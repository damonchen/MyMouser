import Foundation
import Combine

class Backend: ObservableObject {
    @Published var configManager: ConfigManager
    @Published var engine: Engine
    
    @Published var buttons: [ButtonInfo] = []
    @Published var profiles: [ProfileInfo] = []
    @Published var activeProfile: String = "default"
    @Published var mouseConnected: Bool = false
    @Published var batteryLevel: Int = -1
    @Published var statusMessage: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    struct ButtonInfo: Identifiable {
        let id = UUID()
        let key: String
        let name: String
        let actionId: String
        let actionLabel: String
        let index: Int
    }
    
    struct ProfileInfo: Identifiable {
        let id = UUID()
        let name: String
        let label: String
        let apps: [String]
        let appIcons: [String]
        let isActive: Bool
    }
    
    init() {
        self.configManager = ConfigManager.shared
        self.engine = Engine(configManager: ConfigManager.shared)
        
        setupBindings()
        refreshData()
        
        // Setup engine callbacks
        engine.onProfileChange = { [weak self] profileName in
            DispatchQueue.main.async {
                self?.activeProfile = profileName
                self?.statusMessage = "Profile: \(profileName)"
                self?.refreshData()
            }
        }
        
        engine.onConnectionChange = { [weak self] connected in
            DispatchQueue.main.async {
                self?.mouseConnected = connected
            }
        }
        
        engine.onBatteryRead = { [weak self] level in
            DispatchQueue.main.async {
                self?.batteryLevel = level
            }
        }
    }
    
    private func setupBindings() {
        configManager.$config
            .sink { [weak self] _ in
                self?.refreshData()
            }
            .store(in: &cancellables)
        
        engine.$currentProfile
            .sink { [weak self] profile in
                self?.activeProfile = profile
                self?.refreshData()
            }
            .store(in: &cancellables)
        
        engine.$deviceConnected
            .sink { [weak self] connected in
                self?.mouseConnected = connected
            }
            .store(in: &cancellables)
    }
    
    func refreshData() {
        // Refresh buttons
        let mappings = configManager.getActiveMappings()
        buttons = buttonNames.enumerated().map { (index, entry) in
            let (key, name) = entry
            let aid = mappings[key] ?? "none"
            return ButtonInfo(
                key: key,
                name: name,
                actionId: aid,
                actionLabel: actionLabel(for: aid),
                index: index + 1
            )
        }
        
        // Refresh profiles
        let active = configManager.config.activeProfile
        profiles = configManager.config.profiles.map { (name, profile) in
            ProfileInfo(
                name: name,
                label: profile.label,
                apps: profile.apps,
                appIcons: profile.apps.map { getIconForExe($0) },
                isActive: name == active
            )
        }.sorted { $0.name == "default" ? true : ($1.name == "default" ? false : $0.name < $1.name) }
    }
    
    func actionLabel(for actionId: String) -> String {
        return actions[actionId]?.label ?? "Do Nothing"
    }
    
    func setMapping(button: String, actionId: String, profile: String? = nil) {
        configManager.setMapping(button: button, actionId: actionId, profile: profile)
        engine.reloadMappings()
        refreshData()
        statusMessage = "Saved"
    }
    
    func setProfileMapping(profileName: String, button: String, actionId: String) {
        configManager.setMapping(button: button, actionId: actionId, profile: profileName)
        engine.reloadMappings()
        refreshData()
        statusMessage = "Saved"
    }
    
    func setDpi(_ value: Int) {
        configManager.setDpi(value)
        engine.setDpi(value)
        statusMessage = "DPI set to \(value)"
    }
    
    func setInvertVScroll(_ value: Bool) {
        configManager.setInvertVScroll(value)
        engine.reloadMappings()
        statusMessage = "Settings saved"
    }
    
    func setInvertHScroll(_ value: Bool) {
        configManager.setInvertHScroll(value)
        engine.reloadMappings()
        statusMessage = "Settings saved"
    }
    
    func addProfile(appLabel: String) {
        // Find exe for label
        var exe: String?
        for (ex, info) in knownApps {
            if info.label == appLabel {
                exe = ex
                break
            }
        }
        
        guard let targetExe = exe else { return }
        
        // Check if profile already exists
        for (_, profile) in configManager.config.profiles {
            if profile.apps.map({ $0.lowercased() }).contains(targetExe.lowercased()) {
                statusMessage = "Profile already exists"
                return
            }
        }
        
        let safeName = targetExe.lowercased().replacingOccurrences(of: ".exe", with: "")
        configManager.createProfile(name: safeName, label: appLabel, apps: [targetExe])
        refreshData()
        statusMessage = "Profile created"
    }
    
    func deleteProfile(name: String) {
        configManager.deleteProfile(name: name)
        engine.reloadMappings()
        refreshData()
        statusMessage = "Profile deleted"
    }
    
    func getProfileMappings(profileName: String) -> [ButtonInfo] {
        guard let profile = configManager.config.profiles[profileName] else { return [] }
        
        return buttonNames.enumerated().map { (index, entry) in
            let (key, name) = entry
            let aid = profile.mappings[key] ?? "none"
            return ButtonInfo(
                key: key,
                name: name,
                actionId: aid,
                actionLabel: actionLabel(for: aid),
                index: index + 1
            )
        }
    }
    
    func getActionCategories() -> [(category: String, actions: [(id: String, label: String)])] {
        var cats: [String: [(id: String, label: String)]] = [:]
        
        for (aid, action) in actions.sorted(by: {
            ($0.value.category == "Other" ? "0" : "1" + $0.value.category, $0.value.label) <
            ($1.value.category == "Other" ? "0" : "1" + $1.value.category, $1.value.label)
        }) {
            cats[action.category, default: []].append((id: aid, label: action.label))
        }
        
        return cats.map { (category: $0.key, actions: $0.value) }
    }
    
    func getAllActions() -> [(id: String, label: String, category: String)] {
        var result: [(id: String, label: String, category: String)] = []
        
        if let noneAction = actions["none"] {
            result.append((id: "none", label: noneAction.label, category: "Other"))
        }
        
        for (aid, action) in actions.sorted(by: {
            ($0.value.category, $0.value.label) < ($1.value.category, $1.value.label)
        }) {
            if aid == "none" { continue }
            result.append((id: aid, label: action.label, category: action.category))
        }
        
        return result
    }
    
    func getKnownApps() -> [(exe: String, label: String, icon: String)] {
        return knownApps.map { (exe: $0.key, label: $0.value.label, icon: $0.value.icon) }
    }
}
