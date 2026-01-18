//
//  SettingsView.swift
//  ScreenDay
//
//  Created on 2026-01-17.
//

import SwiftUI

struct SettingsView: View {
    private let settings = SettingsManager.shared
    @ObservedObject private var permissionManager = PermissionManager.shared
    @State private var selectedFolder: URL
    @State private var selectedInterval: TimeInterval
    @State private var selectedMaxSize: Int64

    init() {
        let mgr = SettingsManager.shared
        _selectedFolder = State(initialValue: mgr.destinationFolder)
        _selectedInterval = State(initialValue: mgr.screenshotInterval)
        _selectedMaxSize = State(initialValue: mgr.maxFolderSizeBytes)
    }

    var body: some View {
        Form {
            // Permission section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Permissions")
                        .font(.headline)

                    HStack {
                        Image(systemName: permissionManager.hasScreenRecordingPermission ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(permissionManager.hasScreenRecordingPermission ? .green : .red)

                        Text("Screen Recording")
                            .font(.body)

                        Spacer()

                        if !permissionManager.hasScreenRecordingPermission {
                            Button("Open System Settings") {
                                permissionManager.openSystemSettings()
                            }
                        }
                    }

                    if !permissionManager.hasScreenRecordingPermission {
                        Text("ScreenDay needs Screen Recording permission to capture screenshots. Click the button above to grant permission in System Settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Destination Folder")
                        .font(.headline)

                    HStack {
                        Text(selectedFolder.path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Spacer()

                        Button("Choose...") {
                            selectFolder()
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Screenshot Interval")
                        .font(.headline)

                    Picker("", selection: $selectedInterval) {
                        Text("5 seconds").tag(5.0)
                        Text("10 seconds").tag(10.0)
                        Text("15 seconds").tag(15.0)
                        Text("30 seconds").tag(30.0)
                        Text("1 minute").tag(60.0)
                        Text("2 minutes").tag(120.0)
                        Text("5 minutes").tag(300.0)
                    }
                    .pickerStyle(.radioGroup)
                    .onChange(of: selectedInterval) { _, newValue in
                        settings.screenshotInterval = newValue
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Maximum Folder Size")
                        .font(.headline)

                    Picker("", selection: $selectedMaxSize) {
                        Text("1 GB").tag(Int64(1 * 1024 * 1024 * 1024))
                        Text("5 GB").tag(Int64(5 * 1024 * 1024 * 1024))
                        Text("10 GB").tag(Int64(10 * 1024 * 1024 * 1024))
                        Text("20 GB").tag(Int64(20 * 1024 * 1024 * 1024))
                        Text("50 GB").tag(Int64(50 * 1024 * 1024 * 1024))
                        Text("Unlimited").tag(Int64(0))
                    }
                    .pickerStyle(.radioGroup)
                    .onChange(of: selectedMaxSize) { _, newValue in
                        settings.maxFolderSizeBytes = newValue
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 500)
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = selectedFolder

        if panel.runModal() == .OK, let url = panel.url {
            selectedFolder = url
            settings.destinationFolder = url
        }
    }
}

#Preview {
    SettingsView()
}
