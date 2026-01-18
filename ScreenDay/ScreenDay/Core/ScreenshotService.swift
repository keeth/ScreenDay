//
//  ScreenshotService.swift
//  ScreenDay
//
//  Created on 2026-01-17.
//

import Foundation
import ScreenCaptureKit
import AppKit
import Combine
import os.log

@MainActor
class ScreenshotService: ObservableObject {
    static let shared = ScreenshotService()

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let appState = AppState.shared
    private let settings = SettingsManager.shared
    private let logger = Logger(subsystem: "com.screenday.ScreenDay", category: "ScreenshotService")
    private let tracker = ActiveDisplayTracker()
    private var currentDisplayID: CGDirectDisplayID?

    private init() {
        logger.info("📸 ScreenshotService initialized")
        print("📸 ScreenshotService initialized")

        // Observe active display changes
        tracker.$activeDisplayID
            .sink { [weak self] displayID in
                guard let self = self else { return }
                self.currentDisplayID = displayID
                if let id = displayID {
                    self.logger.info("📺 Active display changed to: \(id)")
                    print("📺 Active display changed to: \(id)")
                }
            }
            .store(in: &cancellables)

        // Observe capture state changes
        appState.$isCapturing
            .sink { [weak self] isCapturing in
                self?.logger.info("📸 Capture state changed: \(isCapturing)")
                print("📸 Capture state changed: \(isCapturing)")
                if isCapturing {
                    self?.startCapturing()
                } else {
                    self?.stopCapturing()
                }
            }
            .store(in: &cancellables)

        // Observe system sleep/wake events
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        // Observe screen lock events
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(screenDidLock),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(screenDidUnlock),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )
    }

    private func startCapturing() {
        stopCapturing() // Clear any existing timer

        let interval = settings.screenshotInterval
        let destination = settings.destinationFolder.path
        logger.info("📸 Starting capture: interval=\(interval, privacy: .public)s, destination=\(destination, privacy: .public)")
        print("📸 Starting capture: interval=\(interval)s, destination=\(destination)")

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.captureScreenshot()
            }
        }

        // Take first screenshot immediately
        Task {
            logger.info("📸 Taking initial screenshot...")
            print("📸 Taking initial screenshot...")
            await captureScreenshot()
        }
    }

    private func stopCapturing() {
        if timer != nil {
            logger.info("📸 Stopping capture")
            print("📸 Stopping capture")
            timer?.invalidate()
            timer = nil
        }
    }

    private func captureScreenshot() async {
        do {
            print("📸 Getting shareable content...")

            // Get available content
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )

            // Find the active display, or fall back to first display
            let display: SCDisplay
            if let activeID = currentDisplayID,
               let activeDisplay = content.displays.first(where: { $0.displayID == activeID }) {
                display = activeDisplay
                print("📸 Using active display: \(display.displayID), size: \(display.width)x\(display.height)")
            } else if let firstDisplay = content.displays.first {
                display = firstDisplay
                print("📸 Using first display: \(display.displayID), size: \(display.width)x\(display.height)")
            } else {
                print("❌ No display found!")
                return
            }

            // Create screenshot configuration
            print("📸 Capturing image...")
            let config = SCStreamConfiguration()

            // Calculate dimensions to maintain aspect ratio at ~1080p
            let aspectRatio = Double(display.width) / Double(display.height)
            var targetWidth = Int(Double(1080) * aspectRatio)
            if targetWidth % 2 != 0 { targetWidth += 1 }  // Ensure even
            var targetHeight = 1080
            if targetHeight % 2 != 0 { targetHeight += 1 }

            config.width = targetWidth
            config.height = targetHeight
            config.scalesToFit = true
            config.showsCursor = true

            let image = try await SCScreenshotManager.captureImage(
                contentFilter: SCContentFilter(display: display, excludingWindows: []),
                configuration: config
            )

            print("📸 Image captured: \(image.width)x\(image.height)")

            // Save to disk
            try await saveScreenshot(image)

            // Update permission status on success
            await PermissionManager.shared.checkPermission()

        } catch {
            logger.error("❌ Failed to capture screenshot: \(error.localizedDescription, privacy: .public)")
            print("❌ Failed to capture screenshot: \(error)")
            print("❌ Error details: \(error.localizedDescription)")

            // Check if it's a permission error
            let nsError = error as NSError
            logger.error("❌ Error domain: \(nsError.domain, privacy: .public), code: \(nsError.code, privacy: .public)")
            if nsError.domain == "com.apple.ScreenCaptureKit.SCStreamErrorDomain" && nsError.code == -3801 {
                logger.error("🔐 Permission denied - stopping capture to avoid repeated dialogs")
                print("🔐 Permission denied - stopping capture to avoid repeated dialogs")
                // Update permission status
                await PermissionManager.shared.checkPermission()
                // Stop capturing to avoid repeated permission prompts
                stopCapturing()
                // Update app state
                appState.isCapturing = false
            }
        }
    }

    private func saveScreenshot(_ cgImage: CGImage) async throws {
        let destinationFolder = settings.destinationFolder

        logger.info("📸 Saving to: \(destinationFolder.path, privacy: .public)")

        // Start accessing security-scoped resource
        let accessing = destinationFolder.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                destinationFolder.stopAccessingSecurityScopedResource()
            }
        }

        // Ensure directory exists
        try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true)

        // Generate filename with timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let filename = "\(timestamp).jpg"
        let fileURL = destinationFolder.appendingPathComponent(filename)

        logger.info("📸 Filename: \(filename, privacy: .public)")
        logger.info("📸 Image size: \(cgImage.width, privacy: .public)x\(cgImage.height, privacy: .public)")

        // Convert to JPEG using NSBitmapImageRep
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(
            width: cgImage.width,
            height: cgImage.height
        ))

        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapImage.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [NSBitmapImageRep.PropertyKey.compressionFactor: 0.85]) else {
            logger.error("❌ Failed to convert image to JPEG")
            throw NSError(domain: "ScreenshotService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])
        }

        logger.info("📸 JPEG size: \(jpegData.count / 1024, privacy: .public) KB")

        // Write to file
        logger.info("📸 Writing to file: \(fileURL.path, privacy: .public)")
        do {
            try jpegData.write(to: fileURL)
            logger.info("✅ Screenshot saved successfully: \(fileURL.lastPathComponent, privacy: .public)")
        } catch {
            logger.error("❌ Failed to write file: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    @objc private func systemWillSleep() {
        print("💤 System going to sleep")
        if appState.isCapturing {
            stopCapturing()
        }
    }

    @objc private func systemDidWake() {
        print("👋 System woke up")
        if appState.isCapturing {
            startCapturing()
        }
    }

    @objc private func screenDidLock() {
        print("🔒 Screen locked")
        if appState.isCapturing {
            stopCapturing()
        }
    }

    @objc private func screenDidUnlock() {
        print("🔓 Screen unlocked")
        if appState.isCapturing {
            startCapturing()
        }
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }
}
