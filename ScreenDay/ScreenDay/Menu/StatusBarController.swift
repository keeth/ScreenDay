//
//  StatusBarController.swift
//  ScreenDay
//
//  Created on 2026-01-17.
//

import Cocoa
import SwiftUI
import Combine

@MainActor
class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var cancellables = Set<AnyCancellable>()
    private let appState = AppState.shared

    override init() {
        super.init()

        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
            updateIcon()
        }

        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 250, height: 200)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: StatusMenuView())

        // Observe state changes
        appState.$isCapturing
            .sink { [weak self] _ in
                self?.updateIcon()
            }
            .store(in: &cancellables)

        appState.$isPruning
            .sink { [weak self] _ in
                self?.updateIcon()
            }
            .store(in: &cancellables)

        // Listen for open settings notification
        NotificationCenter.default.publisher(for: NSNotification.Name("OpenSettings"))
            .sink { [weak self] _ in
                self?.openSettings()
            }
            .store(in: &cancellables)
    }

    private func openSettings() {
        // Close popover if open
        if popover.isShown {
            popover.performClose(nil)
        }

        // Use the proper macOS API to open settings
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }

        // Use SF Symbols for reliable menu bar icons
        let symbolName: String
        if appState.isPruning {
            symbolName = "camera.fill.badge.ellipsis"
        } else if appState.isCapturing {
            symbolName = "camera.fill"
        } else {
            symbolName = "camera"
        }

        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(config)
        button.image?.isTemplate = true
    }
}
