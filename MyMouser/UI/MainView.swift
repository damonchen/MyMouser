import SwiftUI

struct MainView: View {
    @StateObject private var backend = Backend()
    @State private var currentPage = 0
    @State private var showToast = false
    @State private var toastMessage = ""
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            sidebar
                .frame(width: 64)
            
            // Content
            contentView
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(Theme.bg)
        .overlay(toastView, alignment: .bottom)
        .onAppear {
            backend.engine.start()
        }
        .onChange(of: backend.statusMessage) { newValue in
            if !newValue.isEmpty {
                showToast(message: newValue)
            }
        }
    }
    
    var sidebar: some View {
        VStack(spacing: 4) {
            // Brand logo
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.accent)
                    .frame(width: 42, height: 42)
                
                Text("M")
                    .font(.system(size: 20, weight: .bold, family: Theme.fontFamily))
                    .foregroundColor(Theme.bgSidebar)
            }
            .padding(.top, 20)
            
            Spacer()
                .frame(height: 20)
            
            // Nav items
            navItem(icon: "🖱", tooltip: "Mouse & Profiles", page: 0)
            navItem(icon: "⚙", tooltip: "Point & Scroll", page: 1)
            
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .background(Theme.bgSidebar)
    }
    
    func navItem(icon: String, tooltip: String, page: Int) -> some View {
        Button(action: {
            currentPage = page
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(currentPage == page ? Theme.accent.opacity(0.12) : Color.clear)
                    .frame(width: 44, height: 44)
                
                Text(icon)
                    .font(.system(size: 20))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 64, height: 52)
        .overlay(
            // Active indicator bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.accent)
                .frame(width: 3, height: 24)
                .position(x: 2, y: 26)
                .opacity(currentPage == page ? 1 : 0)
            , alignment: .leading
        )
        // Tooltip removed for macOS 12 compatibility
    }
    
    var contentView: some View {
        Group {
            if currentPage == 0 {
                MousePage(backend: backend)
            } else {
                ScrollPage(backend: backend)
            }
        }
    }
    
    var toastView: some View {
        Group {
            if showToast {
                Text(toastMessage)
                    .font(.system(size: 12, weight: .bold, family: Theme.fontFamily))
                    .foregroundColor(Theme.bgSidebar)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.accent)
                    .cornerRadius(18)
                    .padding(.bottom, 24)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2))
            }
        }
    }
    
    func showToast(message: String) {
        toastMessage = message
        showToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}
