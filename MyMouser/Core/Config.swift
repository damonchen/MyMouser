import Foundation

// MARK: - Button Names
let buttonNames: [String: String] = [
    "middle": "Middle button",
    "gesture": "Gesture button",
    "xbutton1": "Back button",
    "xbutton2": "Forward button",
    "hscroll_left": "Horizontal scroll left",
    "hscroll_right": "Horizontal scroll right",
]

let buttonToEvents: [String: [String]] = [
    "middle": ["middle_down", "middle_up"],
    "gesture": ["gesture_down", "gesture_up"],
    "xbutton1": ["xbutton1_down", "xbutton1_up"],
    "xbutton2": ["xbutton2_down", "xbutton2_up"],
    "hscroll_left": ["hscroll_left"],
    "hscroll_right": ["hscroll_right"],
]

// MARK: - Known Apps
struct KnownAppInfo: Codable {
    let label: String
    let icon: String
}

let knownApps: [String: KnownAppInfo] = [
    "Safari": KnownAppInfo(label: "Safari", icon: ""),
    "Google Chrome": KnownAppInfo(label: "Google Chrome", icon: "chrom"),
    "VLC": KnownAppInfo(label: "VLC Media Player", icon: "VLC"),
    "Code": KnownAppInfo(label: "Visual Studio Code", icon: "VSCODE"),
    "Finder": KnownAppInfo(label: "Finder", icon: ""),
    "Microsoft Edge": KnownAppInfo(label: "Microsoft Edge", icon: ""),
    "Firefox": KnownAppInfo(label: "Firefox", icon: ""),
    "Music": KnownAppInfo(label: "Music", icon: ""),
    "Spotify": KnownAppInfo(label: "Spotify", icon: ""),
]

func getIconForExe(_ exeName: String) -> String {
    guard let info = knownApps[exeName] else { return "" }
    let icon = info.icon
    if icon.isEmpty { return "" }
    if icon.contains(".") { return icon }
    return icon + ".png"
}

// MARK: - Profile
struct Profile: Codable, Equatable {
    var label: String
    var apps: [String]
    var mappings: [String: String]
}

// MARK: - Settings
struct Settings: Codable, Equatable {
    var startMinimized: Bool = true
    var startWithWindows: Bool = false
    var hscrollThreshold: Int = 1
    var invertHScroll: Bool = false
    var invertVScroll: Bool = false
    var dpi: Int = 1000
    
    enum CodingKeys: String, CodingKey {
        case startMinimized = "start_minimized"
        case startWithWindows = "start_with_windows"
        case hscrollThreshold = "hscroll_threshold"
        case invertHScroll = "invert_hscroll"
        case invertVScroll = "invert_vscroll"
        case dpi
    }
}

// MARK: - Config
struct Config: Codable {
    var version: Int = 2
    var activeProfile: String = "default"
    var profiles: [String: Profile] = [:]
    var settings: Settings = Settings()
    
    enum CodingKeys: String, CodingKey {
        case version
        case activeProfile = "active_profile"
        case profiles
        case settings
    }
}

// MARK: - Default Config
func createDefaultConfig() -> Config {
    var config = Config()
    config.profiles["default"] = Profile(
        label: "Default (All Apps)",
        apps: [],
        mappings: [
            "middle": "none",
            "gesture": "none",
            "xbutton1": "alt_tab",
            "xbutton2": "alt_tab",
            "hscroll_left": "browser_back",
            "hscroll_right": "browser_forward",
        ]
    )
    return config
}

// MARK: - Config Manager
class ConfigManager: ObservableObject {
    static let shared = ConfigManager()
    
    @Published var config: Config
    
    private let configDir: URL
    private let configFile: URL
    
    init() {
        // Setup config directory
        let home = FileManager.default.homeDirectoryForCurrentUser
        configDir = home.appendingPathComponent("Library/Application Support/MyMouser")
        configFile = configDir.appendingPathComponent("config.json")
        
        // Load or create default config
        if let loaded = ConfigManager.loadConfig() {
            config = loaded
        } else {
            config = createDefaultConfig()
            saveConfig()
        }
    }
    
    static func loadConfig() -> Config? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let configDir = home.appendingPathComponent("Library/Application Support/MyMouser")
        let configFile = configDir.appendingPathComponent("config.json")
        
        guard FileManager.default.fileExists(atPath: configFile.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: configFile)
            let decoder = JSONDecoder()
            var cfg = try decoder.decode(Config.self, from: data)
            cfg = migrateConfig(cfg)
            return cfg
        } catch {
            print("[Config] Error loading config: \(error)")
            return nil
        }
    }
    
    func saveConfig() {
        do {
            try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(config)
            try data.write(to: configFile)
        } catch {
            print("[Config] Error saving config: \(error)")
        }
    }
    
    static func migrateConfig(_ cfg: Config) -> Config {
        var cfg = cfg
        let version = cfg.version
        
        if version < 2 {
            // v1 -> v2 migration
            for (name, var profile) in cfg.profiles {
                if profile.apps.isEmpty && name != "default" {
                    profile.apps = []
                }
                cfg.profiles[name] = profile
            }
            cfg.version = 2
        }
        
        return cfg
    }
    
    // MARK: - Profile Management
    
    func getActiveMappings() -> [String: String] {
        let profileName = config.activeProfile
        return config.profiles[profileName]?.mappings ?? config.profiles["default"]?.mappings ?? [:]
    }
    
    func setMapping(button: String, actionId: String, profile: String? = nil) {
        let targetProfile = profile ?? config.activeProfile
        
        if config.profiles[targetProfile] == nil {
            // Create profile if it doesn't exist
            config.profiles[targetProfile] = Profile(
                label: targetProfile,
                apps: [],
                mappings: createDefaultConfig().profiles["default"]!.mappings
            )
        }
        
        config.profiles[targetProfile]?.mappings[button] = actionId
        saveConfig()
    }
    
    func createProfile(name: String, label: String? = nil, copyFrom: String = "default", apps: [String]? = nil) {
        let profileLabel = label ?? name
        let sourceProfile = config.profiles[copyFrom] ?? config.profiles["default"]
        
        config.profiles[name] = Profile(
            label: profileLabel,
            apps: apps ?? [],
            mappings: sourceProfile?.mappings ?? [:]
        )
        saveConfig()
    }
    
    func deleteProfile(name: String) {
        guard name != "default" else { return }
        config.profiles.removeValue(forKey: name)
        if config.activeProfile == name {
            config.activeProfile = "default"
        }
        saveConfig()
    }
    
    func getProfileForApp(_ exeName: String) -> String {
        for (pname, pdata) in config.profiles {
            if exeName.lowercased() == pdata.apps.map({ $0.lowercased() }).first {
                return pname
            }
        }
        return "default"
    }
    
    // MARK: - Settings
    
    func setDpi(_ value: Int) {
        config.settings.dpi = value
        saveConfig()
    }
    
    func setInvertVScroll(_ value: Bool) {
        config.settings.invertVScroll = value
        saveConfig()
    }
    
    func setInvertHScroll(_ value: Bool) {
        config.settings.invertHScroll = value
        saveConfig()
    }
}
