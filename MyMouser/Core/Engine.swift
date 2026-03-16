import Foundation
import Combine

class Engine: ObservableObject {
    @Published var enabled: Bool = true
    @Published var currentProfile: String = "default"
    @Published var batteryLevel: Int = -1
    @Published var deviceConnected: Bool = false
    
    private var configManager: ConfigManager
    private var mouseHook: MouseHook
    private var appDetector: AppDetector
    private var cancellables = Set<AnyCancellable>()
    
    private var hscrollAccum: Int = 0
    private var batteryPollTimer: Timer?
    
    var onProfileChange: ((String) -> Void)?
    var onBatteryRead: ((Int) -> Void)?
    var onConnectionChange: ((Bool) -> Void)?
    
    init(configManager: ConfigManager = .shared) {
        self.configManager = configManager
        self.mouseHook = MouseHook()
        self.appDetector = AppDetector()
        
        self.currentProfile = configManager.config.activeProfile
        
        setupHooks()
        setupAppDetection()
        setupCallbacks()
        
        // Apply persisted DPI setting
        let dpi = configManager.config.settings.dpi
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.mouseHook.hidGesture?.setDpi(dpi)
        }
    }
    
    // MARK: - Setup
    private func setupCallbacks() {
        mouseHook.connectionChangeCallback = { [weak self] connected in
            DispatchQueue.main.async {
                self?.deviceConnected = connected
                self?.onConnectionChange?(connected)
                
                if connected {
                    self?.startBatteryPolling()
                } else {
                    self?.stopBatteryPolling()
                }
            }
        }
    }
    
    private func setupHooks() {
        let mappings = configManager.getActiveMappings()
        let settings = configManager.config.settings
        
        mouseHook.invertVScroll = settings.invertVScroll
        mouseHook.invertHScroll = settings.invertHScroll
        
        for (btnKey, actionId) in mappings {
            guard let events = buttonToEvents[btnKey] else { continue }
            
            for eventTypeStr in events {
                guard let eventType = MouseEventType(rawValue: eventTypeStr) else { continue }
                
                if eventTypeStr.hasSuffix("_up") {
                    if actionId != "none" {
                        mouseHook.block(eventType: eventType)
                    }
                    continue
                }
                
                if actionId != "none" {
                    mouseHook.block(eventType: eventType)
                    
                    if eventTypeStr.contains("hscroll") {
                        mouseHook.register(eventType: eventType) { [weak self] _ in
                            self?.handleHScrollAction(actionId)
                        }
                    } else {
                        mouseHook.register(eventType: eventType) { [weak self] _ in
                            self?.handleAction(actionId)
                        }
                    }
                }
            }
        }
    }
    
    private func setupAppDetection() {
        appDetector.onChange = { [weak self] exeName in
            self?.onAppChange(exeName: exeName)
        }
    }
    
    // MARK: - Event Handlers
    private func handleAction(_ actionId: String) {
        guard enabled else { return }
        KeySimulator.executeAction(actionId)
    }
    
    private func handleHScrollAction(_ actionId: String) {
        guard enabled else { return }
        KeySimulator.executeAction(actionId)
    }
    
    private func onAppChange(exeName: String) {
        let target = configManager.getProfileForApp(exeName)
        guard target != currentProfile else { return }
        
        print("[Engine] App changed to \(exeName) -> profile '\(target)'")
        switchProfile(to: target)
    }
    
    // MARK: - Profile Management
    private func switchProfile(to profileName: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.configManager.config.activeProfile = profileName
            self.currentProfile = profileName
            self.configManager.saveConfig()
            
            // Re-wire callbacks
            self.mouseHook.resetBindings()
            self.setupHooks()
            
            // Notify UI
            self.onProfileChange?(profileName)
        }
    }
    
    func reloadMappings() {
        mouseHook.resetBindings()
        setupHooks()
    }
    
    // MARK: - DPI Control
    func setDpi(_ value: Int) {
        configManager.setDpi(value)
        
        if let result = mouseHook.hidGesture?.setDpi(value) {
            print("[Engine] DPI set to \(value): \(result)")
        }
    }
    
    func readDpiFromDevice() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) { [weak self] in
            if let dpi = self?.mouseHook.hidGesture?.readDpi() {
                DispatchQueue.main.async {
                    self?.configManager.setDpi(dpi)
                }
            }
        }
    }
    
    // MARK: - Battery Polling
    private func startBatteryPolling() {
        // Read battery immediately
        readBattery()
        
        // Then every 5 minutes
        batteryPollTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.readBattery()
        }
    }
    
    private func stopBatteryPolling() {
        batteryPollTimer?.invalidate()
        batteryPollTimer = nil
    }
    
    private func readBattery() {
        // For now, simulate battery reading
        // In real implementation, this would query HID++ for battery level
        // This is a placeholder as proper HID++ battery reading requires more complex implementation
    }
    
    // MARK: - Start/Stop
    func start() {
        mouseHook.start()
        appDetector.start()
        readDpiFromDevice()
    }
    
    func stop() {
        mouseHook.stop()
        appDetector.stop()
        stopBatteryPolling()
    }
    
    func setEnabled(_ value: Bool) {
        enabled = value
    }
}
