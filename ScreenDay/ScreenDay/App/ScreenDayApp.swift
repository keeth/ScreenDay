//
//  ScreenDayApp.swift
//  ScreenDay
//
//  Created on 2026-01-17.
//

import SwiftUI

@main
struct ScreenDayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
