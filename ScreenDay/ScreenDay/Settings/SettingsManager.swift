//
//  SettingsManager.swift
//  ScreenDay
//
//  Created on 2026-01-17.
//

import Foundation

class SettingsManager {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard
    private var accessingSecurityScopedResource = false

    private enum Keys {
        static let destinationFolderBookmark = "destinationFolderBookmark"
        static let screenshotInterval = "screenshotInterval"
        static let maxFolderSizeBytes = "maxFolderSizeBytes"
        static let isCapturing = "isCapturing"
    }

    // MARK: - Destination Folder

    var destinationFolder: URL {
        get {
            // Try to restore from security-scoped bookmark
            if let bookmarkData = defaults.data(forKey: Keys.destinationFolderBookmark) {
                do {
                    var isStale = false
                    let url = try URL(resolvingBookmarkData: bookmarkData,
                                     options: .withSecurityScope,
                                     relativeTo: nil,
                                     bookmarkDataIsStale: &isStale)

                    if !isStale {
                        // Start accessing the security-scoped resource
                        if url.startAccessingSecurityScopedResource() {
                            accessingSecurityScopedResource = true
                        }
                        return url
                    }
                } catch {
                    print("⚠️ Failed to resolve bookmark: \(error)")
                }
            }

            // Default to ~/Pictures/ScreenDay/
            // Use the home directory directly to avoid container path
            let homeURL = FileManager.default.homeDirectoryForCurrentUser
            let picturesURL = homeURL.appendingPathComponent("Pictures")
            let defaultURL = picturesURL.appendingPathComponent("ScreenDay")

            // Create directory if it doesn't exist
            try? FileManager.default.createDirectory(at: defaultURL, withIntermediateDirectories: true)

            return defaultURL
        }
        set {
            // Stop accessing previous resource
            if accessingSecurityScopedResource {
                destinationFolder.stopAccessingSecurityScopedResource()
                accessingSecurityScopedResource = false
            }

            // Save as security-scoped bookmark
            do {
                let bookmarkData = try newValue.bookmarkData(options: .withSecurityScope,
                                                             includingResourceValuesForKeys: nil,
                                                             relativeTo: nil)
                defaults.set(bookmarkData, forKey: Keys.destinationFolderBookmark)
            } catch {
                print("⚠️ Failed to create bookmark: \(error)")
            }
        }
    }

    // MARK: - Screenshot Interval

    var screenshotInterval: TimeInterval {
        get {
            let interval = defaults.double(forKey: Keys.screenshotInterval)
            return interval > 0 ? interval : 10.0
        }
        set {
            defaults.set(newValue, forKey: Keys.screenshotInterval)
        }
    }

    // MARK: - Max Folder Size

    var maxFolderSizeBytes: Int64 {
        get {
            let size = defaults.object(forKey: Keys.maxFolderSizeBytes) as? Int64
            return size ?? (10 * 1024 * 1024 * 1024) // 10GB default
        }
        set {
            defaults.set(newValue, forKey: Keys.maxFolderSizeBytes)
        }
    }

    // MARK: - Capture State

    var isCapturing: Bool {
        get {
            defaults.bool(forKey: Keys.isCapturing)
        }
        set {
            defaults.set(newValue, forKey: Keys.isCapturing)
        }
    }

    // MARK: - Helper Methods

    var hasUserSetDestination: Bool {
        return defaults.data(forKey: Keys.destinationFolderBookmark) != nil
    }

    private init() {}

    deinit {
        if accessingSecurityScopedResource {
            destinationFolder.stopAccessingSecurityScopedResource()
        }
    }
}
