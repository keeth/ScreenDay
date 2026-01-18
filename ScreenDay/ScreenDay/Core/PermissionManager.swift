//
//  PermissionManager.swift
//  ScreenDay
//
//  Created on 2026-01-18.
//

import Foundation
import ScreenCaptureKit

@MainActor
class PermissionManager: ObservableObject {
    static let shared = PermissionManager()

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
            print("🔐 Screen recording permission: \(hasScreenRecordingPermission ? "✅ granted" : "❌ denied")")
        } catch {
            hasScreenRecordingPermission = false
            print("🔐 Screen recording permission: ❌ denied or not yet granted")
        }
    }

    /// Open System Settings to the Screen Recording permission page
    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
