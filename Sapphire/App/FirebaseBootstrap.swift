//
//  FirebaseBootstrap.swift
//  Sapphire
//
//  Created by Shariq Charolia on 2026-09-14

import Foundation

@MainActor
enum FirebaseBootstrap {
    private(set) static var isConfigured = false

    static func configureIfNeeded() {
        // No-op: local build does not require Firebase cloud telemetry or auth
    }
}
