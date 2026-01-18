//
//  AppState.swift
//  ScreenDay
//
//  Created on 2026-01-17.
//

import Foundation
import Combine

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isCapturing: Bool = false {
        didSet {
            print("🎯 AppState.isCapturing changed to: \(isCapturing)")
            SettingsManager.shared.isCapturing = isCapturing
        }
    }

    @Published var isPruning: Bool = false {
        didSet {
            print("🧹 AppState.isPruning changed to: \(isPruning)")
        }
    }

    private init() {
        // Restore previous capture state
        isCapturing = SettingsManager.shared.isCapturing
        print("🎯 AppState initialized with isCapturing: \(isCapturing)")
    }
}
