//
//  StatusMenuView.swift
//  ScreenDay
//
//  Created on 2026-01-17.
//

import SwiftUI

struct StatusMenuView: View {
    @ObservedObject private var appState = AppState.shared
    @ObservedObject private var permissionManager = PermissionManager.shared
    private let settings = SettingsManager.shared
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 12) {
            // Permission warning
            if !permissionManager.hasScreenRecordingPermission {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Screen Recording permission required")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 4)

                Button("Open System Settings") {
                    permissionManager.openSystemSettings()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal)
                .padding(.bottom, 8)

                Divider()
            }

            // Toggle switch
            Toggle("Capture Screenshots", isOn: Binding(
                get: { appState.isCapturing },
                set: { appState.isCapturing = $0 }
            ))
            .toggleStyle(.switch)
            .tint(.blue)
            .padding(.horizontal)
            .disabled(!permissionManager.hasScreenRecordingPermission)

            Divider()

            // Pruning indicator
            if appState.isPruning {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Pruning old screenshots...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }

            // Open folder button
            Button(action: openScreenshotsFolder) {
                HStack {
                    Image(systemName: "folder")
                    Text("Open Screenshots Folder")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            Divider()

            // Settings link
            SettingsLink {
                HStack {
                    Image(systemName: "gear")
                    Text("Settings...")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            Divider()

            // Quit button
            Button(action: quit) {
                HStack {
                    Image(systemName: "power")
                    Text("Quit ScreenDay")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .frame(width: 250)
    }

    private func openScreenshotsFolder() {
        let folderURL = settings.destinationFolder

        // Create directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            NSWorkspace.shared.open(folderURL)
        } catch {
            print("Failed to create or open folder: \(error)")
        }
    }

    private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

#Preview {
    StatusMenuView()
}
