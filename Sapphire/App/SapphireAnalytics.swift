//
//  SapphireAnalytics.swift
//  Sapphire
//
//  Created by Shariq Charolia on 2026-08-10

import Foundation

@MainActor
enum SapphireAnalytics {
    static var isEnabled: Bool { false }

    static func bootstrap() {
        // Disabled: local build does not send telemetry
    }

    static func applyCollectionPreference() {
        // No-op
    }

    static func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        // No-op
    }
}
