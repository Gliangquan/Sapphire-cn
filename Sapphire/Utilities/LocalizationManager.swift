//
//  LocalizationManager.swift
//  Sapphire
//
//  Created by Sapphire Localization Team.
//

import AppKit
import Combine
import Foundation
import SwiftUI

// MARK: - AppLanguage

public enum AppLanguage: String, Codable, CaseIterable, Identifiable, Sendable {
    case system = "system"
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system:
            return LocalizationManager.shared.isChineseActive ? "跟随系统 (System)" : "Follow System"
        case .english:
            return "English"
        case .simplifiedChinese:
            return "简体中文 (Simplified Chinese)"
        }
    }

    public var languageCode: String? {
        switch self {
        case .system:
            return nil
        case .english:
            return "en"
        case .simplifiedChinese:
            return "zh-Hans"
        }
    }

    public var locale: Locale {
        switch self {
        case .system:
            return Locale.current
        case .english:
            return Locale(identifier: "en")
        case .simplifiedChinese:
            return Locale(identifier: "zh-Hans")
        }
    }

    public var isChinese: Bool {
        switch self {
        case .simplifiedChinese:
            return true
        case .english:
            return false
        case .system:
            let preferred = Locale.preferredLanguages.first ?? ""
            return preferred.hasPrefix("zh")
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    public static let sapphireLanguageChanged = Notification.Name("sapphireLanguageChanged")
}

// MARK: - LanguageBundle (Dynamic Bundle Swizzler for SwiftUI LocalizedStringKey & AppKit)

private final class LanguageBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        let manager = LocalizationManager.shared
        if manager.currentLanguage == .english {
            return key
        }
        let translated = manager.localized(key, comment: "")
        if translated != key && !translated.isEmpty {
            return translated
        }
        return value ?? key
    }
}

// MARK: - LocalizationManager

public final class LocalizationManager: ObservableObject, @unchecked Sendable {
    public static let shared = LocalizationManager()
    public static let userDefaultsKey = "sapphire.app.language"

    private let lock = NSLock()
    private var storedLanguage: AppLanguage = .system
    private var storedBundle: Bundle = .main
    private var englishBundle: Bundle?
    private var chineseBundle: Bundle?

    @Published public private(set) var currentLanguage: AppLanguage = .system
    @Published public private(set) var locale: Locale = Locale.current
    @Published public private(set) var revision: UInt64 = 0

    public var isChineseActive: Bool {
        lock.lock()
        let lang = storedLanguage
        lock.unlock()
        return lang.isChinese
    }

    private init() {
        resolveBundles()
        object_setClass(Bundle.main, LanguageBundle.self)

        let initialLanguage: AppLanguage
        if let stored = UserDefaults.standard.string(forKey: Self.userDefaultsKey),
           let lang = AppLanguage(rawValue: stored) {
            initialLanguage = lang
        } else {
            initialLanguage = .system
        }
        applyLanguageInternal(initialLanguage, persist: false, notify: false)
    }

    private func resolveBundles() {
        if let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let bundle = Bundle(path: enPath) {
            englishBundle = bundle
        }
        if let zhPath = Bundle.main.path(forResource: "zh-Hans", ofType: "lproj"),
           let bundle = Bundle(path: zhPath) {
            chineseBundle = bundle
        }
    }

    public func setLanguage(_ language: AppLanguage) {
        lock.lock()
        let unchanged = (storedLanguage == language)
        lock.unlock()
        guard !unchanged else { return }
        applyLanguageInternal(language, persist: true, notify: true)
    }

    private func applyLanguageInternal(_ language: AppLanguage, persist: Bool, notify: Bool) {
        let resolvedBundle: Bundle
        switch language {
        case .system:
            resolvedBundle = language.isChinese ? (chineseBundle ?? .main) : (englishBundle ?? .main)
        case .english:
            resolvedBundle = englishBundle ?? .main
        case .simplifiedChinese:
            resolvedBundle = chineseBundle ?? .main
        }

        lock.lock()
        storedLanguage = language
        storedBundle = resolvedBundle
        lock.unlock()

        if persist {
            UserDefaults.standard.set(language.rawValue, forKey: Self.userDefaultsKey)
            if let code = language.languageCode {
                UserDefaults.standard.set([code], forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            }
        }

        let updatePublished = {
            self.currentLanguage = language
            self.locale = language.locale
            self.revision &+= 1
            if notify {
                NotificationCenter.default.post(name: .sapphireLanguageChanged, object: language)
            }
        }

        if Thread.isMainThread {
            updatePublished()
        } else {
            DispatchQueue.main.async(execute: updatePublished)
        }
    }

    public func localized(_ key: String, comment: String = "") -> String {
        lock.lock()
        let lang = storedLanguage
        let bundle = storedBundle
        lock.unlock()

        let isChineseTarget = lang.isChinese

        // 1. Try bundle .lproj lookup first
        if bundle != Bundle.main {
            let val = bundle.localizedString(forKey: key, value: "__SAPPHIRE_NOT_FOUND__", table: nil)
            if val != "__SAPPHIRE_NOT_FOUND__" && !val.isEmpty {
                return val
            }
        }

        // 2. Check built-in Chinese translation table when Chinese is active
        if isChineseTarget {
            if let zhVal = ChineseTranslations.table[key] {
                return zhVal
            }
        }

        // 3. Fallback to English table or return original key
        if let enVal = EnglishTranslations.table[key] {
            return enVal
        }

        return key
    }

    public func localizedFormat(_ formatKey: String, _ arguments: CVarArg...) -> String {
        let format = localized(formatKey)
        return String(format: format, arguments: arguments)
    }
}

// MARK: - Global Convenience

public func loc(_ key: String) -> String {
    LocalizationManager.shared.localized(key)
}

public func locFormat(_ key: String, _ arguments: CVarArg...) -> String {
    let format = LocalizationManager.shared.localized(key)
    return String(format: format, arguments: arguments)
}

extension String {
    public var localized: String {
        LocalizationManager.shared.localized(self)
    }
}

// MARK: - LocalizedText View

public struct LocalizedText: View {
    let key: String
    @ObservedObject private var locManager = LocalizationManager.shared

    public init(_ key: String) {
        self.key = key
    }

    public var body: some View {
        Text(locManager.localized(key))
    }
}
