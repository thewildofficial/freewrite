// Swift 5.0
//
//  ContentView.swift
//  freewrite
//
//  Created by thorfinn on 2/14/25.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PDFKit
import CoreGraphics
import Foundation

struct HumanEntry: Identifiable {
    let id: UUID
    let date: String
    let filename: String
    var previewText: String
    
    static func createNew() -> HumanEntry {
        let id = UUID()
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let dateString = dateFormatter.string(from: now)
        
        // For display
        dateFormatter.dateFormat = "MMM d"
        let displayDate = dateFormatter.string(from: now)
        
        return HumanEntry(
            id: id,
            date: displayDate,
            filename: "[\(id)]-[\(dateString)].md",
            previewText: ""
        )
    }
}

struct HeartEmoji: Identifiable {
    let id = UUID()
    var position: CGPoint
    var offset: CGFloat = 0
}

struct ContentView: View {
    private let headerString = "\n\n"
    @State private var entries: [HumanEntry] = []
    @State private var text: String = ""  // Remove initial welcome text since we'll handle it in createNewEntry
    @AppStorage("customDirectoryPath") private var customDirectoryPath: String?
    
    @State private var isFullscreen = false
    @State private var selectedFont: String = "Lato-Regular"
    @State private var currentRandomFont: String = ""
    @State private var timeRemaining: Int = 900  // Changed to 900 seconds (15 minutes)
    @State private var timerIsRunning = false
    @State private var isHoveringTimer = false
    @State private var isHoveringFullscreen = false
    @State private var hoveredFont: String? = nil
    @State private var isHoveringSize = false
    @State private var fontSize: CGFloat = 18
    @State private var blinkCount = 0
    @State private var isBlinking = false
    @State private var opacity: Double = 1.0
    @State private var shouldShowGray = true // New state to control color
    @State private var lastClickTime: Date? = nil
    @State private var bottomNavOpacity: Double = 1.0
    @State private var isHoveringBottomNav = false
    @State private var selectedEntryIndex: Int = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedEntryId: UUID? = nil
    @State private var hoveredEntryId: UUID? = nil
    @State private var isHoveringChat = false  // Add this state variable
    @State private var showingChatMenu = false
    @State private var chatMenuAnchor: CGPoint = .zero
    @State private var showingSidebar = false  // Add this state variable
    @State private var hoveredTrashId: UUID? = nil
    @State private var hoveredExportId: UUID? = nil
    @State private var placeholderText: String = ""  // Add this line
    @State private var isHoveringNewEntry = false
    @State private var isHoveringClock = false
    @State private var isHoveringHistory = false
    @State private var isHoveringHistoryText = false
    @State private var isHoveringHistoryPath = false
    @State private var isHoveringHistoryArrow = false
    @State private var isZenMode = false
    @State private var currentLine = ""
    @State private var previousLines: [String] = []
    @State private var isHoveringZen = false
    @State private var isHoveringRandomFont = false // Add state for random font button hover
    @State private var fontSearchText: String = "" // State for font search field
    @State private var showingTimerPopover = false // State for timer popover
    @State private var customTimeInput: String = "" // State for custom timer input
    @State private var isHoveringThemeToggle = false // Add state for theme toggle hover
    @EnvironmentObject var themeManager: ThemeManager
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let entryHeight: CGFloat = 40

    // Get all available font families from the system
    let availableFonts = NSFontManager.shared.availableFontFamilies
    // Keep standardFonts for the dropdown
    let standardFonts = ["Lato-Regular", "Arial", ".AppleSystemUIFont", "Times New Roman"]
    let fontSizes: [CGFloat] = [16, 18, 20, 22, 24, 26]
    let placeholderOptions = [
        "\n\nBegin writing",
        "\n\nPick a thought and go",
        "\n\nStart typing",
        "\n\nWhat's on your mind",
        "\n\nJust start",
        "\n\nType your first thought",
        "\n\nStart with one sentence",
        "\n\nJust say it"
    ]
    
    // Add file manager and save timer
    private let fileManager = FileManager.default
    private let saveTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    // AI Prompts
    private let aiChatPrompt = "You are an AI assistant. The user has provided the following text. Please analyze it and provide helpful feedback, suggestions, or insights. Focus on clarity, flow, and potential areas for expansion or refinement."
    private let claudePrompt = "Analyze the following text and provide constructive feedback. Consider the writing style, clarity, potential improvements, and interesting themes or ideas present."
    
    // Computed property for formatted time
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var timerColor: Color {
        if timerIsRunning {
            return isHoveringTimer ? themeManager.currentTheme.textColor : themeManager.currentTheme.secondaryTextColor
        } else {
            return isHoveringTimer ? themeManager.currentTheme.textColor : themeManager.currentTheme.secondaryTextColor.opacity(0.8)
        }
    }
    
    var lineHeight: CGFloat {
        let font = NSFont(name: selectedFont, size: fontSize) ?? .systemFont(ofSize: fontSize)
        let defaultLineHeight = getLineHeight(font: font)
        return (fontSize * 1.5) - defaultLineHeight
    }
    
    var fontSizeButtonTitle: String {
        return "\(Int(fontSize))px"
    }
    
    var placeholderOffset: CGFloat {
        // Instead of using calculated line height, use a simple offset
        return fontSize / 2
    }
    
    // Add missing helper for randomButtonTitle
    private var randomButtonTitle: String {
        return currentRandomFont.isEmpty ? "Random" : currentRandomFont
    }

    // Add missing helper for timerButtonTitle
    private var timerButtonTitle: String {
        if timerIsRunning {
            return formattedTime
        } else {
            return "Timer"
        }
    }

    // Add missing getDocumentsDirectory helper
    private func getDocumentsDirectory() -> URL? {
        if let customPath = customDirectoryPath {
            let url = URL(fileURLWithPath: customPath)
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                return url
            } else {
                return nil
            }
        }
        let defaultDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Freewrite")
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: defaultDir.path, isDirectory: &isDir) {
            do {
                try FileManager.default.createDirectory(at: defaultDir, withIntermediateDirectories: true)
            } catch {
                print("Error creating Freewrite directory: \(error)")
                return nil
            }
        }
        return defaultDir
    }

    // Add missing loadExistingEntries helper
    private func loadExistingEntries() {
        guard let directory = getDocumentsDirectory() else {
            print("Invalid directory for loading entries.")
            return
        }
        do {
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            let mdFiles = files.filter { $0.pathExtension == "md" }
            let loadedEntries = mdFiles.compactMap { url -> HumanEntry? in
                let filename = url.lastPathComponent
                let id = UUID()
                let date = "" // You can parse from filename if needed
                let previewText = (try? String(contentsOf: url))?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? ""
                return HumanEntry(id: id, date: date, filename: filename, previewText: previewText)
            }
            entries = loadedEntries
            if let first = entries.first {
                selectedEntryId = first.id
                loadEntry(entry: first)
            }
        } catch {
            print("Error loading entries: \(error)")
        }
    }

    var body: some View {
        let navHeight: CGFloat = 68
        
        HStack(spacing: 0) {
            // Main content
            ZStack {
                // Use a Rectangle for the background to ensure full coverage and smooth animation
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.3), value: themeManager.currentTheme)
                
                TextEditor(text: Binding(
                    get: { text },
                    set: { newValue in
                        // Ensure the text always starts with two newlines
                        if !newValue.hasPrefix("\n\n") {
                            text = "\n\n" + newValue.trimmingCharacters(in: CharacterSet.newlines)
                        } else {
                            text = newValue
                        }
                    }
                ))
                    .font(.custom(selectedFont, size: fontSize))
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.never)
                    .lineSpacing(lineHeight)
                    .frame(maxWidth: 650)
                    .id("\(selectedFont)-\(fontSize)-\(themeManager.currentTheme.rawValue)")
                    .padding(.bottom, bottomNavOpacity > 0 ? navHeight : 0)
                    .ignoresSafeArea()
                    .overlay(
                        ZStack(alignment: .topLeading) {
                            if text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                                Text(placeholderText)
                                    .font(.custom(selectedFont, size: fontSize))
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.5))
                                    .allowsHitTesting(false)
                                    .offset(x: 5, y: placeholderOffset)
                            }
                        }, alignment: .topLeading
                    )
                
                VStack {
                    Spacer()
                    HStack {
                        // Font buttons (moved to left)
                        HStack(spacing: 8) {
                            Button(fontSizeButtonTitle) {
                                if let currentIndex = fontSizes.firstIndex(of: fontSize) {
                                    let nextIndex = (currentIndex + 1) % fontSizes.count
                                    fontSize = fontSizes[nextIndex]
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(isHoveringSize ? themeManager.currentTheme.textColor : themeManager.currentTheme.secondaryTextColor)
                            .onHover { hovering in
                                isHoveringSize = hovering
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            
                            Text("•")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            Button("Lato") {
                                selectedFont = "Lato-Regular"
                                currentRandomFont = ""
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(hoveredFont == "Lato" ? themeManager.currentTheme.textColor : themeManager.currentTheme.secondaryTextColor)
                            .onHover { hovering in
                                hoveredFont = hovering ? "Lato" : nil
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            
                            Text("•")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            Button("Arial") {
                                selectedFont = "Arial"
                                currentRandomFont = ""
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(hoveredFont == "Arial" ? themeManager.currentTheme.textColor : themeManager.currentTheme.secondaryTextColor)
                            .onHover { hovering in
                                hoveredFont = hovering ? "Arial" : nil
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            
                            Text("•")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            Button("System") {
                                selectedFont = ".AppleSystemUIFont"
                                currentRandomFont = ""
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(hoveredFont == "System" ? themeManager.currentTheme.textColor : themeManager.currentTheme.secondaryTextColor)
                            .onHover { hovering in
                                hoveredFont = hovering ? "System" : nil
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            
                            Text("•")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            Button("Serif") {
                                selectedFont = "Times New Roman"
                                currentRandomFont = ""
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(hoveredFont == "Serif" ? themeManager.currentTheme.textColor : themeManager.currentTheme.secondaryTextColor)
                            .onHover { hovering in
                                hoveredFont = hovering ? "Serif" : nil
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            
                            Text("•")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            Button(randomButtonTitle) {
                                if let randomFont = availableFonts.randomElement() {
                                    selectedFont = randomFont
                                    currentRandomFont = randomFont
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(hoveredFont == "Random" ? themeManager.currentTheme.textColor : themeManager.currentTheme.secondaryTextColor)
                            .onHover { hovering in
                                hoveredFont = hovering ? "Random" : nil
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        }
                        .padding(8)
                        .cornerRadius(6)
                        .onHover { hovering in
                            isHoveringBottomNav = hovering
                        }
                        
                        Spacer()
                        
                        // Utility buttons (moved to right)
                        HStack(spacing: 8) {
                            Button(timerButtonTitle) {
                                let now = Date()
                                if let lastClick = lastClickTime,
                                   now.timeIntervalSince(lastClick) < 0.3 {
                                    timeRemaining = 900
                                    timerIsRunning = false
                                    lastClickTime = nil
                                } else {
                                    timerIsRunning.toggle()
                                    if timerIsRunning {
                                        // Start timer
                                        withAnimation(.easeIn(duration: 1.0)) {
                                            bottomNavOpacity = 0.0 // Fade out when timer starts
                                        }
                                    } else {
                                        // Stop timer
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            bottomNavOpacity = 1.0 // Fade in when timer stops
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(timerColor)
                            .onHover { hovering in
                                isHoveringTimer = hovering
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            
                            Text("•")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            Button("Chat") {
                                showingChatMenu = true
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(isHoveringChat ? themeManager.currentTheme.textColor : themeManager.currentTheme.secondaryTextColor)
                            .onHover { hovering in
                                isHoveringChat = hovering
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            .popover(isPresented: $showingChatMenu, attachmentAnchor: .point(UnitPoint(x: 0.5, y: 0)), arrowEdge: .top) {
                                if text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).hasPrefix("hi. my name is farza.") {
                                    Text("Yo. Sorry, you can't chat with the guide lol. Please write your own entry.")
                                        .font(.system(size: 14))
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                        .frame(width: 250)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(themeManager.currentTheme.backgroundColor)
                                        .cornerRadius(8)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                                } else if text.count < 350 {
                                    Text("Please free write for at minimum 5 minutes first. Then click this. Trust.")
                                        .font(.system(size: 14))
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                        .frame(width: 250)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(themeManager.currentTheme.backgroundColor)
                                        .cornerRadius(8)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                                } else {
                                    VStack(spacing: 0) {
                                        Button(action: {
                                            showingChatMenu = false
                                            openChatGPT()
                                        }) {
                                            Text("ChatGPT")
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                        }
                                        .buttonStyle(.plain)
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                        
                                        Divider()
                                        
                                        Button(action: {
                                            showingChatMenu = false
                                            openClaude()
                                        }) {
                                            Text("Claude")
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                        }
                                        .buttonStyle(.plain)
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                    }
                                    .frame(width: 120)
                                    .background(themeManager.currentTheme.backgroundColor)
                                    .cornerRadius(8)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                                }
                            }
                            
                            Text("•")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            Button(isFullscreen ? "Minimize" : "Fullscreen") {
                                if let window = NSApplication.shared.windows.first {
                                    window.toggleFullScreen(nil)
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(isHoveringFullscreen ? themeManager.currentTheme.textColor : themeManager.currentTheme.secondaryTextColor)
                            .onHover { hovering in
                                isHoveringFullscreen = hovering
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            
                            Text("•")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            Button(action: {
                                createNewEntry()
                            }) {
                                Text("New Entry")
                                    .font(.system(size: 13))
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(isHoveringNewEntry ? themeManager.currentTheme.textColor : themeManager.currentTheme.secondaryTextColor)
                            .onHover { hovering in
                                isHoveringNewEntry = hovering
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            
                            Text("•")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            // Theme toggle button
                            Button(action: {
                                themeManager.toggleTheme()
                            }) {
                                Image(systemName: themeManager.currentTheme.iconName)
                                    .foregroundColor(isHoveringThemeToggle ? themeManager.currentTheme.iconColor : themeManager.currentTheme.secondaryTextColor)
                                    // Fix for macOS 14+ API
                                    .modifier(SymbolEffectIfAvailable())
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                isHoveringThemeToggle = hovering
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            
                            Text("•")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            // Version history button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingSidebar.toggle()
                                }
                            }) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(isHoveringClock ? themeManager.currentTheme.textColor : themeManager.currentTheme.secondaryTextColor)
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                isHoveringClock = hovering
                                isHoveringBottomNav = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        }
                        .padding(8)
                        .cornerRadius(6)
                        .onHover { hovering in
                            isHoveringBottomNav = hovering
                        }
                    }
                    .padding()
                    .background(themeManager.currentTheme.backgroundColor)
                    .opacity(bottomNavOpacity)
                    .onHover { hovering in
                        isHoveringBottomNav = hovering
                        if hovering {
                            withAnimation(.easeOut(duration: 0.2)) {
                                bottomNavOpacity = 1.0
                            }
                        } else if timerIsRunning {
                            withAnimation(.easeIn(duration: 1.0)) {
                                bottomNavOpacity = 0.0
                            }
                        }
                    }
                }
            }
            
            // Right sidebar
            if showingSidebar {
                Divider()
                    .background(themeManager.currentTheme.secondaryTextColor.opacity(0.2))
                
                VStack(spacing: 0) {
                    // Header
                    Button(action: {
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: getDocumentsDirectory()?.path ?? "")
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Text("History")
                                        .font(.system(size: 13))
                                        .foregroundColor(isHoveringHistory ? themeManager.currentTheme.textColor : themeManager.currentTheme.secondaryTextColor)
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(isHoveringHistory ? themeManager.currentTheme.textColor : themeManager.currentTheme.secondaryTextColor)
                                }
                                Text(getDocumentsDirectory()?.path ?? "")
                                    .font(.system(size: 10))
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(isHoveringHistory ? themeManager.currentTheme.hoverColor : .clear)
                    .onHover { hovering in
                        isHoveringHistory = hovering
                    }
                    
                    Divider()
                        .background(themeManager.currentTheme.secondaryTextColor.opacity(0.2))
                    
                    // Entries List
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(entries) { entry in
                                Button(action: {
                                    if selectedEntryId != entry.id {
                                        // Save current entry before switching
                                        if let currentId = selectedEntryId,
                                           let currentEntry = entries.first(where: { $0.id == currentId }) {
                                            saveEntry(entry: currentEntry)
                                        }
                                        
                                        selectedEntryId = entry.id
                                        loadEntry(entry: entry)
                                    }
                                }) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(entry.previewText)
                                                    .font(.system(size: 13))
                                                    .lineLimit(1)
                                                    .foregroundColor(themeManager.currentTheme.textColor)
                                                
                                                Spacer()
                                                
                                                // Export/Trash icons that appear on hover
                                                if hoveredEntryId == entry.id {
                                                    HStack(spacing: 8) {
                                                        // Export PDF button
                                                        Button(action: {
                                                            exportEntryAsPDF(entry: entry)
                                                        }) {
                                                            Image(systemName: "arrow.down.circle")
                                                                .font(.system(size: 11))
                                                                .foregroundColor(hoveredExportId == entry.id ? 
                                                                    themeManager.currentTheme.textColor : 
                                                                    themeManager.currentTheme.secondaryTextColor)
                                                        }
                                                        .buttonStyle(.plain)
                                                        .help("Export entry as PDF")
                                                        .onHover { hovering in
                                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                                hoveredExportId = hovering ? entry.id : nil
                                                            }
                                                            if hovering {
                                                                NSCursor.pointingHand.push()
                                                            } else {
                                                                NSCursor.pop()
                                                            }
                                                        }
                                                        
                                                        // Trash icon
                                                        Button(action: {
                                                            deleteEntry(entry: entry)
                                                        }) {
                                                            Image(systemName: "trash")
                                                                .font(.system(size: 11))
                                                                .foregroundColor(hoveredTrashId == entry.id ? .red : themeManager.currentTheme.secondaryTextColor)
                                                        }
                                                        .buttonStyle(.plain)
                                                        .onHover { hovering in
                                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                                hoveredTrashId = hovering ? entry.id : nil
                                                            }
                                                            if hovering {
                                                                NSCursor.pointingHand.push()
                                                            } else {
                                                                NSCursor.pop()
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            Text(entry.date)
                                                .font(.system(size: 12))
                                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(backgroundColor(for: entry))
                                    )
                                    .padding(.horizontal, 4) // Add slight horizontal padding for the background highlight
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contentShape(Rectangle()) // Ensure the whole area is clickable
                                .onHover { hovering in
                                    withAnimation(.easeInOut(duration: 0.1)) { // Faster hover animation
                                        hoveredEntryId = hovering ? entry.id : nil
                                    }
                                }
                                .onAppear {
                                    NSCursor.pop()  // Reset cursor when button appears
                                }
                                .help("Click to select this entry")  // Add tooltip

                                if entry.id != entries.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .scrollIndicators(.never)
                }
                .frame(width: 200)
                .background(themeManager.currentTheme.sidebarColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minWidth: 1100, minHeight: 600)
        .animation(.easeInOut(duration: 0.2), value: showingSidebar)
        .environmentObject(themeManager)
        .onAppear {
            showingSidebar = false  // Hide sidebar by default
            loadExistingEntries()
        }
        .onChange(of: text) { _ in
            // Save current entry when text changes, only if NOT in Zen Mode
            // ZenModeView handles updating 'text' internally via binding
            if !isZenMode, let currentId = selectedEntryId,
               let currentEntry = entries.first(where: { $0.id == currentId }) {
                saveEntry(entry: currentEntry)
            }
        }
        .onChange(of: isZenMode) { newValue in
             // Use the new value directly
            if newValue {
                // Entering Zen Mode
                showingSidebar = false // Ensure sidebar is hidden
                // Parse current text into lines, preserving initial newlines and structure
                let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

                // Find the last non-empty line to be the current line
                if let lastNonEmptyIndex = lines.lastIndex(where: { !$0.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty }) {
                    currentLine = lines[lastNonEmptyIndex]
                    // Previous lines are everything before the last non-empty one, preserving empty lines between them
                    previousLines = Array(lines.prefix(lastNonEmptyIndex))
                } else {
                    // Text is empty or only whitespace/newlines
                    currentLine = ""
                    // Preserve leading newlines if they exist
                    previousLines = lines.filter { $0.isEmpty }
                }
                // Update the main text state immediately to reflect the split (important for consistency if saved)
                 text = (previousLines + [currentLine]).joined(separator: "\n")

            } else {
                // Exiting Zen Mode
                // Reconstruct the text from previousLines and the potentially modified currentLine
                // Add current line back only if it's not just whitespace
                let trimmedCurrentLine = currentLine.trimmingCharacters(in: CharacterSet.whitespaces)
                let finalLines = previousLines + (trimmedCurrentLine.isEmpty ? [] : [currentLine])

                // Reconstruct, ensuring at least the initial \n\n are present if the result isn't empty
                var reconstructedText = finalLines.joined(separator: "\n")
                if !reconstructedText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                    // If there's content, ensure it starts with \n\n
                    if !reconstructedText.hasPrefix("\n\n") {
                         if reconstructedText.hasPrefix("\n") {
                             reconstructedText = "\n" + reconstructedText // Add one more \n
                         } else {
                             reconstructedText = "\n\n" + reconstructedText // Add both \n\n
                         }
                    }
                } else {
                    // If the result is effectively empty, reset to just \n\n
                    reconstructedText = "\n\n"
                }
                 text = reconstructedText // Update the main state

                // Save the reconstructed text immediately
                if let currentId = selectedEntryId,
                   let currentEntry = entries.first(where: { $0.id == currentId }) {
                    saveEntry(entry: currentEntry)
                }
            }
        }
        .onReceive(timer) { _ in
            if timerIsRunning && timeRemaining > 0 {
                timeRemaining -= 1
            } else if timeRemaining == 0 {
                timerIsRunning = false
                // Exit Zen Mode automatically if timer runs out
                if isZenMode {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isZenMode = false
                    }
                }
                // Show bottom bar if not hovering
                if !isHoveringBottomNav {
                    withAnimation(.easeOut(duration: 1.0)) {
                        bottomNavOpacity = 1.0
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willEnterFullScreenNotification)) { _ in
            isFullscreen = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willExitFullScreenNotification)) { _ in
            isFullscreen = false
        }
    } // End body var

    // Function to set the timer
    private func setTimer(minutes: Int) {
        timeRemaining = minutes * 60
        timerIsRunning = false // Stop timer when setting a new time
        customTimeInput = "" // Clear custom input field
        showingTimerPopover = false // Close popover
        // Ensure bottom bar is visible when timer is reset/stopped
        withAnimation(.easeOut(duration: 0.2)) {
            bottomNavOpacity = 1.0
        }
    }

    // Computed property for filtered fonts
    private var filteredFonts: [String] {
        if fontSearchText.isEmpty {
            return availableFonts.sorted() // Show all available fonts sorted if search is empty
        } else {
            // Filter available fonts based on search text (case-insensitive)
            return availableFonts.filter { $0.localizedCaseInsensitiveContains(fontSearchText) }.sorted()
        }
    }

    // MARK: - Helper Functions

    private func backgroundColor(for entry: HumanEntry) -> Color {
        if entry.id == selectedEntryId {
            return themeManager.currentTheme.hoverColor
        } else if entry.id == hoveredEntryId {
            return themeManager.currentTheme.subtleHoverColor
        } else {
            return .clear
        }
    }

    private func updatePreviewText(for entry: HumanEntry) {
        // Use the currently determined valid directory
        guard let documentsDirectory = getDocumentsDirectory() else {
             print("Cannot update preview text: Invalid directory.")
             return
        }
        let fileURL = documentsDirectory.appendingPathComponent(entry.filename)

        do {
            // Check if file exists before trying to read
            guard fileManager.fileExists(atPath: fileURL.path) else {
                print("Preview update skipped: File does not exist at \(fileURL.path)")
                // Optionally remove the entry from the list if the file is gone
                // if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                //     entries.remove(at: index)
                // }
                return
            }
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let preview = content
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let truncated = preview.isEmpty ? "" : (preview.count > 30 ? String(preview.prefix(30)) + "..." : preview)

            // Find and update the entry in the entries array
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index].previewText = truncated
            }
        } catch {
            print("Error updating preview text: \(error)")
        }
    }

    private func saveEntry(entry: HumanEntry) {
        // Use the currently determined valid directory
        guard let documentsDirectory = getDocumentsDirectory() else {
             print("Cannot save entry: Invalid directory.")
             return // Or handle error appropriately
        }
        let fileURL = documentsDirectory.appendingPathComponent(entry.filename)

        // Ensure text always has the leading newlines before saving
        var textToSave = text
        if !textToSave.hasPrefix("\n\n") {
             if textToSave.hasPrefix("\n") {
                 textToSave = "\n" + textToSave
             } else if !textToSave.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                 // Only add prefix if there's actual content
                 textToSave = "\n\n" + textToSave
             } else {
                 // If it's effectively empty, save just the newlines
                 textToSave = "\n\n"
             }
        }

        do {
            try textToSave.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Successfully saved entry: \(entry.filename)")
            updatePreviewText(for: entry)  // Update preview after saving
        } catch {
            print("Error saving entry: \(error)")
        }
    }

    private func loadEntry(entry: HumanEntry) {
        // Use the currently determined valid directory
        guard let documentsDirectory = getDocumentsDirectory() else {
             print("Cannot load entry: Invalid directory.")
             text = "\n\nError: Could not access storage location." // Provide feedback
             return
        }
        let fileURL = documentsDirectory.appendingPathComponent(entry.filename)

        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                var loadedText = try String(contentsOf: fileURL, encoding: .utf8)
                // Ensure loaded text starts correctly
                if !loadedText.hasPrefix("\n\n") {
                     if loadedText.hasPrefix("\n") {
                         loadedText = "\n" + loadedText
                     } else if !loadedText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                         loadedText = "\n\n" + loadedText
                     } else {
                         loadedText = "\n\n"
                     }
                }
                text = loadedText
                print("Successfully loaded entry: \(entry.filename)")
            }
        } catch {
            print("Error loading entry: \(error)")
        }
    }

    private func createNewEntry() {
        // Save the current entry first if one is selected
        if let currentId = selectedEntryId, let currentEntry = entries.first(where: { $0.id == currentId }) {
             saveEntry(entry: currentEntry)
        }

        let newEntry = HumanEntry.createNew()
        entries.insert(newEntry, at: 0) // Add to the beginning
        selectedEntryId = newEntry.id

        // If this is the first entry (entries was empty before adding this one)
        if entries.count == 1 {
            // Read welcome message from default.md
            if let defaultMessageURL = Bundle.main.url(forResource: "default", withExtension: "md"),
               let defaultMessage = try? String(contentsOf: defaultMessageURL, encoding: .utf8) {
                text = "\n\n" + defaultMessage
            } else {
                 text = "\n\n" // Fallback if default.md is missing
            }
            // Save the welcome message immediately
            saveEntry(entry: newEntry)
            // Update the preview text
            updatePreviewText(for: newEntry)
        } else {
            // Regular new entry starts with newlines
            text = "\n\n"
            // Randomize placeholder text for new entry
            placeholderText = placeholderOptions.randomElement() ?? "\n\nBegin writing"
            // Save the empty entry
            saveEntry(entry: newEntry)
        }
    }

    private func openChatGPT() {
        let trimmedText = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let fullText = aiChatPrompt + "\n\n" + trimmedText

        if let encodedText = fullText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
           let url = URL(string: "https://chat.openai.com/?m=" + encodedText) {
            NSWorkspace.shared.open(url)
        }
    }

    private func openClaude() {
        let trimmedText = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let fullText = claudePrompt + "\n\n" + trimmedText

        if let encodedText = fullText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
           let url = URL(string: "https://claude.ai/new?q=" + encodedText) {
            NSWorkspace.shared.open(url)
        }
    }

    private func deleteEntry(entry: HumanEntry) {
        // Use the currently determined valid directory
        guard let documentsDirectory = getDocumentsDirectory() else {
             print("Cannot delete entry: Invalid directory.")
             // Optionally show an alert to the user
             return
        }
        let fileURL = documentsDirectory.appendingPathComponent(entry.filename)

        do {
            // Check if file exists before trying to delete
            guard fileManager.fileExists(atPath: fileURL.path) else {
                 print("Deletion skipped: File does not exist at \(fileURL.path)")
                 // Remove the entry from the list anyway if it's somehow still there
                 if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                     entries.remove(at: index)
                     // Handle selection change if needed
                     if selectedEntryId == entry.id {
                         if let firstEntry = entries.first {
                             selectedEntryId = firstEntry.id
                             loadEntry(entry: firstEntry)
                         } else {
                             createNewEntry()
                         }
                     }
                 }
                 return
            }

            try fileManager.removeItem(at: fileURL)
            print("Successfully deleted file: \(entry.filename)")

            // Remove the entry from the entries array
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries.remove(at: index)

                // If the deleted entry was selected, select the first entry or create a new one
                if selectedEntryId == entry.id {
                    if let firstEntry = entries.first {
                        selectedEntryId = firstEntry.id
                        loadEntry(entry: firstEntry)
                    } else {
                        // If no entries left, create a new one
                        createNewEntry()
                    }
                }
            }
        } catch {
            print("Error deleting file: \(error)")
        }
    }
    
    // Extract a title from entry content for PDF export
    private func extractTitleFromContent(_ content: String, date: String) -> String {
        // Clean up content by removing leading/trailing whitespace and newlines
        let trimmedContent = content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        // If content is empty, just use the date
        if trimmedContent.isEmpty {
            return "Entry \(date)"
        }
        
        // Split content into words, ignoring newlines and removing punctuation
        let words = trimmedContent
            .replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { word in
                word.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;:\"'()[]{}<>"))
                    .lowercased()
            }
            .filter { !$0.isEmpty }
        
        // If we have at least 4 words, use them
        if words.count >= 4 {
            return "\(words[0])-\(words[1])-\(words[2])-\(words[3])"
        }
        
        // If we have fewer than 4 words, use what we have
        if !words.isEmpty {
            return words.joined(separator: "-")
        }
        
        // Fallback to date if no words found
        return "Entry \(date)"
    }
    
    private func exportEntryAsPDF(entry: HumanEntry) {
        // First make sure the current entry is saved
        if selectedEntryId == entry.id {
            saveEntry(entry: entry)
        }
        
        // Get entry content
        let documentsDirectory = getDocumentsDirectory()
        let fileURL = documentsDirectory?.appendingPathComponent(entry.filename)
        
        do {
            // Read the content of the entry
            let entryContent = try String(contentsOf: fileURL!, encoding: .utf8)
            
            // Extract a title from the entry content and add .pdf extension
            let suggestedFilename = extractTitleFromContent(entryContent, date: entry.date) + ".pdf"
            
            // Create save panel
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [UTType.pdf]
            savePanel.nameFieldStringValue = suggestedFilename
            savePanel.isExtensionHidden = false  // Make sure extension is visible
            
            // Show save dialog
            if savePanel.runModal() == .OK, let url = savePanel.url {
                // Create PDF data
                if let pdfData = createPDFFromText(text: entryContent) {
                    try pdfData.write(to: url)
                    print("Successfully exported PDF to: \(url.path)")
                }
            }
        } catch {
            print("Error in PDF export: \(error)")
        }
    }
    
    private func createPDFFromText(text: String) -> Data? {
        // Letter size page dimensions
        let pageWidth: CGFloat = 612.0  // 8.5 x 72
        let pageHeight: CGFloat = 792.0 // 11 x 72
        let margin: CGFloat = 72.0      // 1-inch margins
        
        // Calculate content area
        let contentRect = CGRect(
            x: margin,
            y: margin,
            width: pageWidth - (margin * 2),
            height: pageHeight - (margin * 2)
        )
        
        // Create PDF data container
        let pdfData = NSMutableData()
        
        // Configure text formatting attributes
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineHeight
        
        let font = NSFont(name: selectedFont, size: fontSize) ?? .systemFont(ofSize: fontSize)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1.0),
            .paragraphStyle: paragraphStyle
        ]
        
        // Trim the initial newlines before creating the PDF
        let trimmedText = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        // Create the attributed string with formatting
        let attributedString = NSAttributedString(string: trimmedText, attributes: textAttributes)
        
        // Create a Core Text framesetter for text layout
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        
        // Create a PDF context with the data consumer
        guard let pdfContext = CGContext(consumer: CGDataConsumer(data: pdfData as CFMutableData)!, mediaBox: nil, nil) else {
            print("Failed to create PDF context")
            return nil
        }
        
        // Track position within text
        var currentRange = CFRange(location: 0, length: 0)
        var pageIndex = 0
        
        // Create a path for the text frame
        let framePath = CGMutablePath()
        framePath.addRect(contentRect)
        
        // Continue creating pages until all text is processed
        while currentRange.location < attributedString.length {
            // Begin a new PDF page
            pdfContext.beginPage(mediaBox: nil)
            
            // Fill the page with white background
            pdfContext.setFillColor(NSColor.white.cgColor)
            pdfContext.fill(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
            
            // Create a frame for this page's text
            let frame = CTFramesetterCreateFrame(
                framesetter, 
                currentRange, 
                framePath, 
                nil
            )
            
            // Draw the text frame
            CTFrameDraw(frame, pdfContext)
            
            // Get the range of text that was actually displayed in this frame
            let visibleRange = CTFrameGetVisibleStringRange(frame)
            
            // Move to the next block of text for the next page
            currentRange.location += visibleRange.length
            
            // Finish the page
            pdfContext.endPage()
            pageIndex += 1
            
            // Safety check - don't allow infinite loops
            if pageIndex > 1000 {
                print("Safety limit reached - stopping PDF generation")
                break
            }
        }
        
        // Finalize the PDF document
        pdfContext.closePDF()
        
        return pdfData as Data
    }
}

// Helper function to calculate line height
func getLineHeight(font: NSFont) -> CGFloat {
    return font.ascender - font.descender + font.leading
}

// MARK: - Extensions

// Add helper extension to find NSView subviews
extension NSView {
    func findTextView() -> NSView? {
        if self is NSTextView {
            return self
        }
        for subview in subviews {
            if let textView = subview.findTextView() {
                return textView
            }
        }
        return nil
    }
}

// Add helper extension for finding subviews of a specific type
extension NSView {
    func findSubview<T: NSView>(ofType type: T.Type) -> T? {
        if let typedSelf = self as? T {
            return typedSelf
        }
        for subview in subviews {
            if let found = subview.findSubview(ofType: type) {
                return found
            }
        }
        return nil
    }
}

// Helper view modifier for macOS 14+ symbolEffect
struct SymbolEffectIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 14.0, *) {
            content.contentTransition(.symbolEffect(.replace.downUp.byLayer))
        } else {
            content // fallback: no transition
        }
    }
}

#Preview {
    ContentView()
}