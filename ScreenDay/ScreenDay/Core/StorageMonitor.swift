//
//  StorageMonitor.swift
//  ScreenDay
//
//  Created on 2026-01-17.
//

import Foundation
import Combine
import os.log

@MainActor
class StorageMonitor: ObservableObject {
    static let shared = StorageMonitor()

    private var timer: Timer?
    private let appState = AppState.shared
    private let settings = SettingsManager.shared
    private let checkInterval: TimeInterval = 30.0 // Check every 30 seconds
    private let logger = Logger(subsystem: "io.vurt.ScreenDay", category: "StorageMonitor")

    private init() {
        startMonitoring()
    }

    func startMonitoring() {
        stopMonitoring()

        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkStorage()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkStorage() async {
        let folderURL = settings.destinationFolder
        let maxSize = settings.maxFolderSizeBytes

        // Skip check if unlimited
        guard maxSize > 0 else { return }

        let currentSize = calculateFolderSize(at: folderURL)
        let threshold90 = Int64(Double(maxSize) * 0.90)

        if currentSize > threshold90 {
            await pruneOldFiles(at: folderURL, targetSize: Int64(Double(maxSize) * 0.80))
        }
    }

    private func calculateFolderSize(at url: URL) -> Int64 {
        var totalSize: Int64 = 0

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            totalSize += Int64(fileSize)
        }

        return totalSize
    }

    private func pruneOldFiles(at url: URL, targetSize: Int64) async {
        appState.isPruning = true

        defer {
            appState.isPruning = false
        }

        // Collect files synchronously to avoid async iterator issues
        let files = collectFiles(at: url)

        // Delete oldest files until under target size
        var currentSize: Int64 = files.reduce(0) { $0 + $1.size }

        for file in files {
            guard currentSize > targetSize else { break }

            do {
                try FileManager.default.removeItem(at: file.url)
                currentSize -= file.size
            } catch {
                logger.error("Failed to delete file \(file.url.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Collects files with their modification dates and sizes, sorted oldest first
    private nonisolated func collectFiles(at url: URL) -> [(url: URL, date: Date, size: Int64)] {
        var files: [(url: URL, date: Date, size: Int64)] = []

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
                  let date = resourceValues.contentModificationDate,
                  let size = resourceValues.fileSize else {
                continue
            }
            files.append((url: fileURL, date: date, size: Int64(size)))
        }

        // Sort by date (oldest first)
        files.sort { $0.date < $1.date }

        return files
    }
}
