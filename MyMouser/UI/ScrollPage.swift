import SwiftUI

struct ScrollPage: View {
    @ObservedObject var backend: Backend
    
    @State private var dpiValue: Double = 1000
    @State private var invertVScroll: Bool = false
    @State private var invertHScroll: Bool = false
    
    let dpiPresets = [400, 800, 1000, 1600, 2400, 4000, 6000, 8000]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                    .background(Theme.border)
                    .padding(.horizontal, 36)
                
                Spacer()
                    .frame(height: 24)
                
                // DPI Card
                dpiCard
                
                Spacer()
                    .frame(height: 16)
                
                // Scroll Direction Card
                scrollDirectionCard
                
                Spacer()
                    .frame(height: 16)
                
                // Info note
                infoCard
                
                Spacer()
                    .frame(height: 24)
            }
        }
        .background(Theme.bg)
        .onAppear {
            dpiValue = Double(backend.configManager.config.settings.dpi)
            invertVScroll = backend.configManager.config.settings.invertVScroll
            invertHScroll = backend.configManager.config.settings.invertHScroll
        }
        .onChange(of: backend.configManager.config.settings.dpi) { newValue in
            dpiValue = Double(newValue)
        }
        .onChange(of: backend.configManager.config.settings.invertVScroll) { newValue in
            invertVScroll = newValue
        }
        .onChange(of: backend.configManager.config.settings.invertHScroll) { newValue in
            invertHScroll = newValue
        }
    }
    
    var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Point & Scroll")
                .font(.system(size: 24, weight: .bold, family: Theme.fontFamily))
                .foregroundColor(Theme.textPrimary)
            
            Text("Adjust pointer speed and scroll behaviour")
                .font(.system(size: 13, family: Theme.fontFamily))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 36)
        .frame(height: 90)
    }
    
    var dpiCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pointer Speed (DPI)")
                .font(.system(size: 16, weight: .bold, family: Theme.fontFamily))
                .foregroundColor(Theme.textPrimary)
            
            Text("Adjust the tracking speed of the sensor. Higher = faster pointer.")
                .font(.system(size: 12, family: Theme.fontFamily))
                .foregroundColor(Theme.textSecondary)
            
            // Slider row
            HStack(spacing: 12) {
                Text("200")
                    .font(.system(size: 11, family: Theme.fontFamily))
                    .foregroundColor(Theme.textDim)
                
                Slider(value: $dpiValue, in: 200...8000, step: 50) { editing in
                    if !editing {
                        backend.setDpi(Int(dpiValue))
                    }
                }
                .accentColor(Theme.accent)
                
                Text("8000")
                    .font(.system(size: 11, family: Theme.fontFamily))
                    .foregroundColor(Theme.textDim)
                
                Text("\(Int(dpiValue)) DPI")
                    .font(.system(size: 14, weight: .bold, family: Theme.fontFamily))
                    .foregroundColor(Theme.accent)
                    .frame(width: 100, height: 36)
                    .background(Theme.accentDim)
                    .cornerRadius(8)
            }
            
            // Presets
            HStack(spacing: 8) {
                Text("Presets:")
                    .font(.system(size: 11, family: Theme.fontFamily))
                    .foregroundColor(Theme.textDim)
                
                ForEach(dpiPresets, id: \.self) { preset in
                    Button(action: {
                        dpiValue = Double(preset)
                        backend.setDpi(preset)
                    }) {
                        Text("\(preset)")
                            .font(.system(size: 12, family: Theme.fontFamily))
                            .foregroundColor(Int(dpiValue) == preset ? Theme.bgSidebar : Theme.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Int(dpiValue) == preset ? Theme.accent : Theme.bgSidebar)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius)
                .stroke(Theme.border, lineWidth: 1)
        )
        .padding(.horizontal, 36)
    }
    
    var scrollDirectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scroll Direction")
                .font(.system(size: 16, weight: .bold, family: Theme.fontFamily))
                .foregroundColor(Theme.textPrimary)
            
            Text("Invert the scroll direction (natural scrolling)")
                .font(.system(size: 12, family: Theme.fontFamily))
                .foregroundColor(Theme.textSecondary)
            
            // Vertical scroll toggle
            HStack {
                Text("Invert vertical scroll")
                    .font(.system(size: 13, family: Theme.fontFamily))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Toggle("", isOn: $invertVScroll)
                    .onChange(of: invertVScroll) { newValue in
                        backend.setInvertVScroll(newValue)
                    }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Theme.bgSidebar)
            .cornerRadius(8)
            
            // Horizontal scroll toggle
            HStack {
                Text("Invert horizontal scroll")
                    .font(.system(size: 13, family: Theme.fontFamily))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Toggle("", isOn: $invertHScroll)
                    .onChange(of: invertHScroll) { newValue in
                        backend.setInvertHScroll(newValue)
                    }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Theme.bgSidebar)
            .cornerRadius(8)
        }
        .padding(20)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius)
                .stroke(Theme.border, lineWidth: 1)
        )
        .padding(.horizontal, 36)
    }
    
    var infoCard: some View {
        Text("Note: DPI changes require HID++ communication with the device and will take effect after a short delay.")
            .font(.system(size: 12, family: Theme.fontFamily))
            .foregroundColor(Theme.textDim)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.bgCard)
            .cornerRadius(Theme.radius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .padding(.horizontal, 36)
    }
}
