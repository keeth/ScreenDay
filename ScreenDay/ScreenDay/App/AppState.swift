//
//  AppState.swift
//  ScreenDay
//
//  Created on 2026-01-17.
//

import Foundation
import Combine
import os.log

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    private let logger = Logger(subsystem: "io.vurt.ScreenDay", category: "AppState")

    @Published var isCapturing: Bool = false {
        didSet {
            logger.info("🎯 AppState.isCapturing changed to: \(isCapturing)")
            SettingsManager.shared.isCapturing = isCapturing
        }
    }

    @Published var isPruning: Bool = false {
        didSet {
            logger.info("🧹 AppState.isPruning changed to: \(isPruning)")
        }
    }

    private init() {
        // Restore previous capture state
        isCapturing = SettingsManager.shared.isCapturing
        logger.info("🎯 AppState initialized with isCapturing: \(isCapturing)")
    }
}
