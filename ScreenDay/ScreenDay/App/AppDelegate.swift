//
//  AppDelegate.swift
//  ScreenDay
//
//  Created on 2026-01-17.
//

import Cocoa
import SwiftUI
import ScreenCaptureKit
import os.log

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private let logger = Logger(subsystem: "io.vurt.ScreenDay", category: "AppDelegate")

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("🚀 ScreenDay launched")

        // Initialize services
        _ = ScreenshotService.shared
        _ = StorageMonitor.shared

        // Create status bar controller
        statusBarController = StatusBarController()

        // Show settings if destination folder not configured
        checkDestinationFolder()

        // Permission will be requested automatically when user starts capturing
    }

    private func checkDestinationFolder() {
        let settings = SettingsManager.shared

        // Open settings window if user hasn't set a destination folder
        if !settings.hasUserSetDestination {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Post notification to open settings
                NotificationCenter.default.post(name: NSNotification.Name("OpenSettings"), object: nil)
            }
        }
    }
}
