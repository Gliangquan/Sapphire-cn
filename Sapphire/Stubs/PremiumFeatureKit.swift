//
//  PremiumFeatureKit.swift
//  Sapphire
//
//  Created by Shariq Charolia on 2026-09-15

#if !SAPPHIRE_FULL_BUILD
import Combine
import SwiftUI

enum PremiumGate {
    static func hasAccess(_ feature: AppFeature) -> Bool {
        true
    }

    static func isActive(_ feature: AppFeature?, enabled: Bool) -> Bool {
        enabled
    }

    static var accessChanges: AnyPublisher<Void, Never> {
        NotificationCenter.default.publisher(for: .subscriptionEntitlementsDidChange)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    @discardableResult
    static func require(_ feature: AppFeature, message: String? = nil) -> Bool {
        true
    }
}

struct PremiumFeatureView<Content: View>: View {
    let feature: AppFeature
    let content: Content

    init(feature: AppFeature, message: String? = nil, @ViewBuilder content: () -> Content) {
        self.feature = feature
        self.content = content()
    }

    var body: some View {
        content
    }
}

extension View {
    func premiumFeature(_ feature: AppFeature, message: String? = nil) -> some View {
        PremiumFeatureView(feature: feature, message: message) { self }
    }
}

func premiumDefaultMessage(for feature: AppFeature) -> String {
    "Unlocked"
}

extension SettingsModel {
    func premiumChanges(_ feature: AppFeature, _ enabled: @escaping (Settings) -> Bool) -> AnyPublisher<Bool, Never> {
        $settings
            .map(enabled)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func isPremiumActive(_ feature: AppFeature, _ enabled: (Settings) -> Bool) -> Bool {
        enabled(settings)
    }
}

extension WidgetType {
    var requiredPremiumFeature: AppFeature? {
        nil
    }

    var isPremiumLocked: Bool {
        false
    }
}

extension LiveActivityType {
    var requiredPremiumFeature: AppFeature? {
        nil
    }

    var isPremiumLocked: Bool {
        false
    }
}
#endif
