//
//  freewriteApp.swift
//  freewrite
//
//  Created by thorfinn on 2/14/25.
//

import SwiftUI
import CoreText

struct freewriteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var themeManager = ThemeManager()
    
    init() {
        if let fontURL = Bundle.main.url(forResource: "Lato-Regular", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }
     
    var body: some Scene {
        WindowGroup {
            ContentView()
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        EmptyView()
                    }
                }
                .preferredColorScheme(themeManager.currentTheme == .light ? .light : .dark)
                .environmentObject(themeManager)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1100, height: 600)
        .windowToolbarStyle(.unifiedCompact)
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var themeObserver: NSObjectProtocol?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            // Ensure window starts in windowed mode
            if window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
            // Center the window on the screen
            window.center()
            // Set window background to match the theme
            window.backgroundColor = .clear
            window.isOpaque = false
            // Set initial appearance
            updateWindowAppearance(window)
            // Observe theme changes
            themeObserver = NotificationCenter.default.addObserver(forName: .init("ThemeDidChange"), object: nil, queue: .main) { [weak window] _ in
                if let window = window {
                    self.updateWindowAppearance(window)
                }
            }
        }
    }
    
    func updateWindowAppearance(_ window: NSWindow) {
        let theme = UserDefaults.standard.string(forKey: "appTheme") ?? "light"
        if theme == "dark" {
            window.appearance = NSAppearance(named: .darkAqua)
        } else {
            window.appearance = NSAppearance(named: .aqua)
        }
    }
    
    deinit {
        if let observer = themeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// Entry point to avoid @main attribute error
@main
struct freewriteAppMain {
    static func main() {
        freewriteApp.main()
    }
}
