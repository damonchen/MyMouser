import SwiftUI
import AppKit

@main
struct MyMouserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusItem: NSStatusItem?
    var window: NSWindow?
    var engine: Engine?
    var backend: Backend?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Create engine and backend
        backend = Backend()
        engine = backend?.engine
        
        // Create window
        createWindow()
        
        // Setup status bar
        setupStatusBar()
        
        // Start engine
        engine?.start()
    }
    
    func createWindow() {
        let contentView = MainView()
            .environmentObject(backend!)
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1060, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window?.title = "Mouser — MX Master 3S"
        window?.contentView = NSHostingView(rootView: contentView)
        window?.minSize = NSSize(width: 900, height: 600)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        
        // Handle window close - hide instead of quit
        window?.delegate = self
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "computermouse", accessibilityDescription: "Mouser")
            button.action = #selector(statusBarClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        let menu = NSMenu()
        
        let openItem = NSMenuItem(title: "Open Settings", action: #selector(showWindow), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let toggleItem = NSMenuItem(title: "Disable Remapping", action: #selector(toggleRemapping), keyEquivalent: "t")
        toggleItem.target = self
        toggleItem.tag = 100
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit Mouser", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc func statusBarClicked() {
        showWindow()
    }
    
    @objc func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func toggleRemapping() {
        guard let engine = engine else { return }
        
        let newEnabled = !engine.enabled
        engine.setEnabled(newEnabled)
        
        if let menu = statusItem?.menu,
           let item = menu.item(withTag: 100) {
            item.title = newEnabled ? "Disable Remapping" : "Enable Remapping"
        }
    }
    
    @objc func quitApp() {
        engine?.stop()
        NSApp.terminate(nil)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Hide window instead of closing
        window?.orderOut(nil)
        return false
    }
}
