//
//  LocalizationTests.swift
//  SapphireTests
//
//  Created by Sapphire Localization Team.
//

import Foundation
import XCTest
@testable import Sapphire

final class LocalizationTests: XCTestCase {
    @MainActor
    func testLanguageSwitchingReturnsCorrectStrings() {
        let manager = LocalizationManager.shared
        let originalLanguage = manager.currentLanguage
        defer {
            manager.setLanguage(originalLanguage)
        }

        // Test English
        manager.setLanguage(.english)
        XCTAssertEqual(manager.currentLanguage, .english)
        XCTAssertEqual(loc("General"), "General")
        XCTAssertEqual(loc("Appearance"), "Appearance")
        XCTAssertEqual(loc("Quit"), "Quit")
        XCTAssertEqual(SettingsSection.general.label, "General")

        // Test Chinese
        manager.setLanguage(.simplifiedChinese)
        XCTAssertEqual(manager.currentLanguage, .simplifiedChinese)
        XCTAssertEqual(loc("General"), "通用")
        XCTAssertEqual(loc("Appearance"), "外观与动效")
        XCTAssertEqual(loc("Quit"), "退出 Sapphire")
        XCTAssertEqual(loc("Launch at Login"), "开机自动启动")
        XCTAssertEqual(SettingsSection.general.label, "通用")
        XCTAssertEqual(SettingsSection.appearance.label, "外观与动效")
    }

    @MainActor
    func testStringLocalizedExtension() {
        let manager = LocalizationManager.shared
        let originalLanguage = manager.currentLanguage
        defer {
            manager.setLanguage(originalLanguage)
        }

        manager.setLanguage(.simplifiedChinese)
        XCTAssertEqual("General".localized, "通用")
        XCTAssertEqual("Lock Screen".localized, "锁定屏幕")

        manager.setLanguage(.english)
        XCTAssertEqual("General".localized, "General")
        XCTAssertEqual("Lock Screen".localized, "Lock Screen")
    }

    func testSidebarCatalogRemainsCompleteUnderAllLanguages() {
        let manager = LocalizationManager.shared

        for lang in AppLanguage.allCases {
            manager.setLanguage(lang)
            let sidebarSections = SettingsSection.sidebarGroups.flatMap(\.sections)
            XCTAssertEqual(sidebarSections.count, SettingsSection.allCases.count)
            XCTAssertEqual(Set(sidebarSections.map(\.id)), Set(SettingsSection.allCases.map(\.id)))
        }
    }

    @MainActor
    func testSettingsModelIntegratesLanguageSetting() {
        let model = SettingsModel.shared
        let original = model.settings.appLanguage
        defer {
            model.settings.appLanguage = original
            LocalizationManager.shared.setLanguage(original)
        }

        model.settings.appLanguage = .simplifiedChinese
        XCTAssertEqual(LocalizationManager.shared.currentLanguage, .simplifiedChinese)

        model.settings.appLanguage = .english
        XCTAssertEqual(LocalizationManager.shared.currentLanguage, .english)
    }

    @MainActor
    func testNSLocalizedStringSwizzlingRoutesCorrectly() {
        let manager = LocalizationManager.shared
        let originalLanguage = manager.currentLanguage
        defer {
            manager.setLanguage(originalLanguage)
        }

        manager.setLanguage(.simplifiedChinese)
        XCTAssertEqual(NSLocalizedString("Appearance", comment: ""), "外观与动效")
        XCTAssertEqual(NSLocalizedString("Widgets", comment: ""), "小组件管理")
        XCTAssertEqual(NSLocalizedString("Music", comment: ""), "音乐与歌词")

        manager.setLanguage(.english)
        XCTAssertEqual(NSLocalizedString("Appearance", comment: ""), "Appearance")
    }
}
