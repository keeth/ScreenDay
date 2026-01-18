//
//  ActiveDisplayTracker.swift
//  ScreenDay
//
//  Tracks the CGDirectDisplayID under the mouse cursor
//

import Foundation
import AppKit
import Combine

@MainActor
final class ActiveDisplayTracker: ObservableObject {
    @Published private(set) var activeDisplayID: CGDirectDisplayID?

    private var timerSource: DispatchSourceTimer?
    private var screensObserver: Any?

    // Debounce state - accessed only from stateQueue
    private let stateQueue = DispatchQueue(label: "io.vurt.ScreenDay.ActiveDisplayTracker.state")
    private nonisolated(unsafe) var candidateID: CGDirectDisplayID?
    private nonisolated(unsafe) var candidateSince: Date?

    // Configuration
    private let pollHz: Double = 6.0
    private let debounceSeconds: TimeInterval = 0.4
    private let hysteresisInset: CGFloat = 10

    init() {
        // Observe screen changes
        screensObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: NSApplication.shared,
            queue: .main
        ) { [weak self] _ in
            self?.handleDisplayChange()
        }

        start()
    }

    deinit {
        timerSource?.cancel()
        if let obs = screensObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    private nonisolated func handleDisplayChange() {
        stateQueue.async { [weak self] in
            self?.candidateID = nil
            self?.candidateSince = nil
            self?.pollDisplayOnBackground()
        }
    }

    private func start() {
        stop()

        let interval = 1.0 / pollHz
        let source = DispatchSource.makeTimerSource(queue: stateQueue)
        source.schedule(deadline: .now() + interval, repeating: interval)
        source.setEventHandler { [weak self] in
            self?.pollDisplayOnBackground()
        }
        source.resume()
        timerSource = source
    }

    private func stop() {
        timerSource?.cancel()
        timerSource = nil
    }

    private nonisolated func pollDisplayOnBackground() {
        // Get mouse location
        let loc = NSEvent.mouseLocation
        let inset = hysteresisInset

        // Get screens
        let screens = NSScreen.screens

        // Find screen under cursor with hysteresis
        guard let screen = screens.first(where: { $0.frame.insetBy(dx: inset, dy: inset).contains(loc) })
                ?? screens.first(where: { $0.frame.contains(loc) })
        else { return }

        guard let newID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
        else { return }

        let now = Date()

        // Debounce logic
        if candidateID != newID {
            candidateID = newID
            candidateSince = now
            return
        }

        // Candidate is stable - update published property
        if let since = candidateSince, now.timeIntervalSince(since) >= debounceSeconds {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.activeDisplayID != newID {
                    self.activeDisplayID = newID
                }
            }
        }
    }
}
