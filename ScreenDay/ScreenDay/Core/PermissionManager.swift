//
//  PermissionManager.swift
//  ScreenDay
//
//  Created on 2026-01-18.
//

import Foundation
import ScreenCaptureKit
import os.log

@MainActor
class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    private let logger = Logger(subsystem: "io.vurt.ScreenDay", category: "PermissionManager")

    @Published var hasScreenRecordingPermission: Bool = false

    private init() {
        Task {
            await checkPermission()
        }
    }

    /// Check if we have screen recording permission without triggering the prompt
    func checkPermission() async {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            hasScreenRecordingPermission = !content.displays.isEmpty
            logger.info("🔐 Screen recording permission: \(self.hasScreenRecordingPermission ? "✅ granted" : "❌ denied")")
        } catch {
            hasScreenRecordingPermission = false
            logger.info("🔐 Screen recording permission: ❌ denied or not yet granted")
        }
    }

    /// Open System Settings to the Screen Recording permission page
    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
