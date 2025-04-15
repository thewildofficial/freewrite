//
//  ThemeManager.swift
//  freewrite
//
//  Created by thewildofficial on 4/15/25.
//

import SwiftUI

@available(macOS 13.5, *)
public enum Theme: String {
    case light
    case dark
    
    public var backgroundColor: Color {
        switch self {
        case .light: return .white
        case .dark: return Color(red: 0.12, green: 0.12, blue: 0.13)
        }
    }
    
    public var textColor: Color {
        switch self {
        case .light: return Color(red: 0.20, green: 0.20, blue: 0.20)
        case .dark: return Color(red: 0.92, green: 0.92, blue: 0.93)
        }
    }
    
    public var secondaryTextColor: Color {
        switch self {
        case .light: return Color(red: 0.45, green: 0.45, blue: 0.45)
        case .dark: return Color(red: 0.7, green: 0.7, blue: 0.72)
        }
    }
    
    public var hoverColor: Color {
        switch self {
        case .light: return Color.gray.opacity(0.12)
        case .dark: return Color.white.opacity(0.12)
        }
    }
    
    public var subtleHoverColor: Color {
        switch self {
        case .light: return Color.gray.opacity(0.06)
        case .dark: return Color.white.opacity(0.06)
        }
    }
    
    public var sidebarColor: Color {
        switch self {
        case .light: return Color(red: 0.98, green: 0.98, blue: 0.98)
        case .dark: return Color(red: 0.14, green: 0.14, blue: 0.15)
        }
    }
    
    public var iconName: String {
        switch self {
        case .light: return "moon.fill"
        case .dark: return "sun.max.fill"
        }
    }
    
    public var iconColor: Color {
        switch self {
        case .light: return Color(red: 0.2, green: 0.2, blue: 0.2)
        case .dark: return Color(red: 0.95, green: 0.95, blue: 0.6)
        }
    }
}

@available(macOS 13.5, *)
public class ThemeManager: ObservableObject {
    @Published public var currentTheme: Theme = .light {
        didSet {
            UserDefaults.standard.set(currentTheme == .light ? "light" : "dark", forKey: "appTheme")
            NotificationCenter.default.post(name: .init("ThemeDidChange"), object: nil)
        }
    }
    
    public init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "appTheme") {
            currentTheme = savedTheme == "light" ? .light : .dark
        }
    }
    
    public func toggleTheme() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = currentTheme == .light ? .dark : .light
        }
    }
}