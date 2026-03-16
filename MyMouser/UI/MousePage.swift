import SwiftUI

struct MousePage: View {
    @ObservedObject var backend: Backend
    
    @State private var selectedProfile: String = "default"
    @State private var selectedProfileLabel: String = ""
    @State private var selectedButton: String = ""
    @State private var selectedButtonName: String = ""
    @State private var selectedActionId: String = ""
    @State private var selectedAppLabel: String = ""
    
    var body: some View {
        HStack(spacing: 0) {
            // Left panel - Profile list
            profileListPanel
                .frame(width: 220)
            
            // Right panel - Mouse image and settings
            ScrollView {
                VStack(spacing: 0) {
                    headerPanel
                    
                    Divider()
                        .background(Theme.border)
                        .padding(.horizontal, 28)
                    
                    // Mouse image with hotspots
                    mouseImagePanel
                        .frame(height: 420)
                    
                    if !selectedButton.isEmpty {
                        Divider()
                            .background(Theme.border)
                            .padding(.horizontal, 28)
                        
                        actionPickerPanel
                            .padding(.horizontal, 28)
                            .padding(.vertical, 16)
                    }
                    
                    Spacer()
                        .frame(height: 24)
                }
            }
            .background(Theme.bg)
        }
        .onAppear {
            selectProfile(backend.activeProfile)
        }
        .onChange(of: backend.activeProfile) { newValue in
            selectProfile(newValue)
        }
    }
    
    // MARK: - Profile List Panel
    var profileListPanel: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Profiles")
                    .font(.system(size: 14, weight: .bold, family: Theme.fontFamily))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            
            Divider()
                .background(Theme.border)
            
            // Profile items
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(backend.profiles) { profile in
                        profileRow(profile)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            
            Divider()
                .background(Theme.border)
            
            // Add profile controls
            HStack(spacing: 8) {
                let apps = backend.getKnownApps()
                Picker("", selection: $selectedAppLabel) {
                    ForEach(0..<apps.count, id: \.self) { index in
                        Text(apps[index].label).tag(apps[index].label)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    if !selectedAppLabel.isEmpty {
                        backend.addProfile(appLabel: selectedAppLabel)
                    }
                }) {
                    Text("+")
                        .font(.system(size: 16, weight: .bold, family: Theme.fontFamily))
                        .foregroundColor(Theme.bgSidebar)
                        .frame(width: 42, height: 28)
                        .background(Theme.accent)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(8)
            .frame(height: 52)
        }
        .background(Theme.bgCard)
        .overlay(
            Rectangle()
                .stroke(Theme.border, lineWidth: 1)
        )
    }
    
    func profileRow(_ profile: Backend.ProfileInfo) -> some View {
        let isSelected = selectedProfile == profile.name
        
        return HStack(spacing: 8) {
            // Active indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(profile.isActive ? Theme.accent : Color.clear)
                .frame(width: 3, height: 28)
            
            // App icons (placeholder)
            HStack(spacing: -4) {
                ForEach(profile.appIcons, id: \.self) { icon in
                    if !icon.isEmpty {
                        Image(systemName: "app.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.label)
                    .font(.system(size: 12, weight: .bold, family: Theme.fontFamily))
                    .foregroundColor(isSelected ? Theme.accent : Theme.textPrimary)
                    .lineLimit(1)
                
                Text(profile.apps.isEmpty ? "All applications" : profile.apps.joined(separator: ", "))
                    .font(.system(size: 9, family: Theme.fontFamily))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .frame(height: 58)
        .background(isSelected ? Theme.accent.opacity(0.08) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            selectProfile(profile.name)
        }
        .animation(.easeInOut(duration: 0.12))
    }
    
    // MARK: - Header Panel
    var headerPanel: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("MX Master 3S")
                        .font(.system(size: 20, weight: .bold, family: Theme.fontFamily))
                        .foregroundColor(Theme.textPrimary)
                    
                    if !selectedProfileLabel.isEmpty {
                        Text(selectedProfileLabel)
                            .font(.system(size: 11, family: Theme.fontFamily))
                            .foregroundColor(Theme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.accent.opacity(0.12))
                            .cornerRadius(11)
                    }
                }
                
                Text("Click a dot to configure its action")
                    .font(.system(size: 12, family: Theme.fontFamily))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                // Delete profile button
                if selectedProfile != "default" && !selectedProfile.isEmpty {
                    Button(action: {
                        backend.deleteProfile(name: selectedProfile)
                        selectProfile(backend.activeProfile)
                    }) {
                        Text("Delete Profile")
                            .font(.system(size: 10, weight: .bold, family: Theme.fontFamily))
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(hex: "#662222"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Battery badge
                if backend.batteryLevel >= 0 {
                    HStack(spacing: 4) {
                        Text("🔋")
                            .font(.system(size: 11))
                        Text("\(backend.batteryLevel)%")
                            .font(.system(size: 11, weight: .bold, family: Theme.fontFamily))
                            .foregroundColor(batteryColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(batteryBgColor)
                    .cornerRadius(12)
                }
                
                // Connection status
                HStack(spacing: 5) {
                    Circle()
                        .fill(backend.mouseConnected ? Theme.accent : Color(hex: "#e05555"))
                        .frame(width: 7, height: 7)
                    
                    Text(backend.mouseConnected ? "Connected" : "Not Connected")
                        .font(.system(size: 11, family: Theme.fontFamily))
                        .foregroundColor(backend.mouseConnected ? Theme.accent : Color(hex: "#e05555"))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(backend.mouseConnected ? Theme.accent.opacity(0.12) : Color(hex: "#e05555").opacity(0.15))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 28)
        .frame(height: 70)
    }
    
    var batteryColor: Color {
        let lvl = backend.batteryLevel
        if lvl < 20 { return Color(hex: "#e05555") }
        if lvl <= 69 { return Color(hex: "#e0b840") }
        return Theme.accent
    }
    
    var batteryBgColor: Color {
        let lvl = backend.batteryLevel
        if lvl < 20 { return Color(hex: "#e05555").opacity(0.18) }
        if lvl <= 69 { return Color(hex: "#e0b840").opacity(0.18) }
        return Theme.accent.opacity(0.12)
    }
    
    // MARK: - Mouse Image Panel
    var mouseImagePanel: some View {
        ZStack {
            Theme.bg
            
            // Mouse image
            Image("mouse")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 460, height: 360)
            
            // Hotspots
            HotspotDot(
                buttonKey: "middle",
                label: "Middle button",
                sublabel: actionFor("middle"),
                normX: 0.35, normY: 0.4,
                labelSide: "right",
                labelOffX: 100, labelOffY: -160,
                isHScroll: false,
                selectedButton: $selectedButton,
                onSelect: { selectButton("middle") }
            )
            
            HotspotDot(
                buttonKey: "gesture",
                label: "Gesture button",
                sublabel: actionFor("gesture"),
                normX: 0.7, normY: 0.63,
                labelSide: "left",
                labelOffX: -200, labelOffY: 60,
                isHScroll: false,
                selectedButton: $selectedButton,
                onSelect: { selectButton("gesture") }
            )
            
            HotspotDot(
                buttonKey: "xbutton2",
                label: "Forward button",
                sublabel: actionFor("xbutton2"),
                normX: 0.6, normY: 0.48,
                labelSide: "left",
                labelOffX: -300, labelOffY: 0,
                isHScroll: false,
                selectedButton: $selectedButton,
                onSelect: { selectButton("xbutton2") }
            )
            
            HotspotDot(
                buttonKey: "xbutton1",
                label: "Back button",
                sublabel: actionFor("xbutton1"),
                normX: 0.65, normY: 0.4,
                labelSide: "right",
                labelOffX: 200, labelOffY: 50,
                isHScroll: false,
                selectedButton: $selectedButton,
                onSelect: { selectButton("xbutton1") }
            )
            
            HotspotDot(
                buttonKey: "hscroll_left",
                label: "Horizontal scroll",
                sublabel: "L: \(actionFor("hscroll_left")) | R: \(actionFor("hscroll_right"))",
                normX: 0.6, normY: 0.375,
                labelSide: "right",
                labelOffX: 200, labelOffY: -50,
                isHScroll: true,
                selectedButton: $selectedButton,
                onSelect: { selectHScroll() }
            )
        }
    }
    
    // MARK: - Action Picker Panel
    var actionPickerPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Theme.accent)
                    .frame(width: 6, height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedButtonName + " — Choose Action")
                        .font(.system(size: 15, weight: .bold, family: Theme.fontFamily))
                        .foregroundColor(Theme.textPrimary)
                    
                    if selectedButton == "hscroll_left" {
                        Text("Configure separate actions for scroll left and right")
                            .font(.system(size: 12, family: Theme.fontFamily))
                            .foregroundColor(Theme.textSecondary)
                    } else {
                        Text("Select what happens when you use this button")
                            .font(.system(size: 12, family: Theme.fontFamily))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            
            if selectedButton == "hscroll_left" {
                // Horizontal scroll configuration
                VStack(alignment: .leading, spacing: 14) {
                    Text("SCROLL LEFT")
                        .font(.system(size: 11, family: Theme.fontFamily))
                        .foregroundColor(Theme.textDim)
                    
                    // Use adaptive grid for macOS 12 compatibility
                    let allActions = backend.getAllActions()
                    let actionItems = allActions.map { ActionItem(id: $0.id, label: $0.label, category: $0.category) }
                    ChipGrid(items: actionItems, spacing: 8) { action in
                        ActionChip(
                            actionId: action.id,
                            actionLabel: action.label,
                            isCurrent: action.id == actionIdFor("hscroll_left"),
                            onPicked: {
                                backend.setProfileMapping(profileName: selectedProfile, button: "hscroll_left", actionId: action.id)
                                refreshSelectedAction()
                            }
                        )
                    }
                    
                    Text("SCROLL RIGHT")
                        .font(.system(size: 11, family: Theme.fontFamily))
                        .foregroundColor(Theme.textDim)
                        .padding(.top, 4)
                    
                    ChipGrid(items: actionItems, spacing: 8) { action in
                        ActionChip(
                            actionId: action.id,
                            actionLabel: action.label,
                            isCurrent: action.id == actionIdFor("hscroll_right"),
                            onPicked: {
                                backend.setProfileMapping(profileName: selectedProfile, button: "hscroll_right", actionId: action.id)
                                refreshSelectedAction()
                            }
                        )
                    }
                }
            } else {
                // Regular button configuration
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(backend.getActionCategories(), id: \.category) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category.category.uppercased())
                                .font(.system(size: 11, family: Theme.fontFamily))
                                .foregroundColor(Theme.textDim)
                            
                            let actionItems = category.actions.map { ActionItem(id: $0.id, label: $0.label, category: category.category) }
                            ChipGrid(items: actionItems, spacing: 8) { action in
                                ActionChip(
                                    actionId: action.id,
                                    actionLabel: action.label,
                                    isCurrent: action.id == selectedActionId,
                                    onPicked: {
                                        backend.setProfileMapping(profileName: selectedProfile, button: selectedButton, actionId: action.id)
                                        selectedActionId = action.id
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    func selectProfile(_ name: String) {
        selectedProfile = name
        if let profile = backend.profiles.first(where: { $0.name == name }) {
            selectedProfileLabel = profile.label
        }
        selectedButton = ""
        selectedButtonName = ""
        selectedActionId = ""
    }
    
    func selectButton(_ key: String) {
        if selectedButton == key {
            selectedButton = ""
            selectedButtonName = ""
            selectedActionId = ""
            return
        }
        
        let mappings = backend.getProfileMappings(profileName: selectedProfile)
        if let btn = mappings.first(where: { $0.key == key }) {
            selectedButton = key
            selectedButtonName = btn.name
            selectedActionId = btn.actionId
        }
    }
    
    func selectHScroll() {
        if selectedButton == "hscroll_left" {
            selectedButton = ""
            selectedButtonName = ""
            selectedActionId = ""
            return
        }
        
        selectedButton = "hscroll_left"
        selectedButtonName = "Horizontal Scroll"
        let mappings = backend.getProfileMappings(profileName: selectedProfile)
        if let btn = mappings.first(where: { $0.key == "hscroll_left" }) {
            selectedActionId = btn.actionId
        }
    }
    
    func actionFor(_ key: String) -> String {
        let mappings = backend.getProfileMappings(profileName: selectedProfile)
        return mappings.first(where: { $0.key == key })?.actionLabel ?? "Do Nothing"
    }
    
    func actionIdFor(_ key: String) -> String {
        let mappings = backend.getProfileMappings(profileName: selectedProfile)
        return mappings.first(where: { $0.key == key })?.actionId ?? "none"
    }
    
    func refreshSelectedAction() {
        let mappings = backend.getProfileMappings(profileName: selectedProfile)
        if let btn = mappings.first(where: { $0.key == selectedButton }) {
            selectedActionId = btn.actionId
        }
    }
}

// MARK: - ActionItem (Identifiable wrapper)
struct ActionItem: Identifiable {
    let id: String
    let label: String
    let category: String
}

// MARK: - Chip Grid (macOS 12 compatible)
struct ChipGrid<Content: View>: View {
    var items: [ActionItem]
    var spacing: CGFloat = 8
    @ViewBuilder var content: (ActionItem) -> Content
    
    // Fixed column approach for macOS 12 compatibility
    private let columns = 5 // Approximate number of chips per row
    
    var body: some View {
        let rows = chunkArray(items, into: columns)
        
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: spacing) {
                    ForEach(rows[rowIndex]) { item in
                        content(item)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
    
    private func chunkArray<T: Identifiable>(_ array: [T], into size: Int) -> [[T]] {
        var result: [[T]] = []
        var current: [T] = []
        
        for item in array {
            current.append(item)
            if current.count >= size {
                result.append(current)
                current = []
            }
        }
        
        if !current.isEmpty {
            result.append(current)
        }
        
        return result
    }
}
