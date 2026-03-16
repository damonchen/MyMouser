import Foundation
import AppKit

class AppDetector: ObservableObject {
    @Published var currentApp: String = ""
    
    private var timer: Timer?
    private var lastExe: String?
    private let interval: TimeInterval = 0.3
    var onChange: ((String) -> Void)?
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.poll()
        }
        // Initial poll
        poll()
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func poll() {
        guard let exe = getForegroundExe() else { return }
        
        if exe != lastExe {
            lastExe = exe
            currentApp = exe
            onChange?(exe)
        }
    }
    
    func getForegroundExe() -> String? {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        
        // Try to get executable URL
        if let url = app.executableURL {
            return url.lastPathComponent
        }
        
        // Fallback to bundle identifier or localized name
        if let bundleId = app.bundleIdentifier {
            return bundleId
        }
        
        return app.localizedName
    }
}
