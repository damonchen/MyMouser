import SwiftUI

struct HotspotDot: View {
    let buttonKey: String
    let label: String
    let sublabel: String
    let normX: CGFloat
    let normY: CGFloat
    let labelSide: String
    let labelOffX: CGFloat
    let labelOffY: CGFloat
    let isHScroll: Bool
    
    @Binding var selectedButton: String
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var isSelected: Bool {
        selectedButton == buttonKey || (isHScroll && selectedButton == "hscroll_left")
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Calculate position
                let cx = geometry.size.width * normX
                let cy = geometry.size.height * normY
                
                // Glow ring
                Circle()
                    .stroke(isSelected ? Theme.accent : Color(hex: "#00d4aa").opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    .frame(width: 30, height: 30)
                    .position(x: cx, y: cy)
                    .opacity(isSelected || isHovered ? 1 : 0.6)
                    .scaleEffect(isSelected ? 1.25 : 1.0)
                    .animation(isSelected ? Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default)
                
                // Dot
                Circle()
                    .fill(isSelected ? Theme.accentHover : Theme.accent)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.3), lineWidth: 2)
                    )
                    .position(x: cx, y: cy)
                    .scaleEffect(isHovered ? 1.2 : 1.0)
                    .animation(.easeOut(duration: 0.15))
                
                // Click area (larger than dot)
                Circle()
                    .fill(Color.clear)
                    .frame(width: 36, height: 36)
                    .position(x: cx, y: cy)
                    .contentShape(Circle())
                    .onHover { hovering in
                        isHovered = hovering
                    }
                    .onTapGesture {
                        onSelect()
                    }
                
                // Connecting line
                Path { path in
                    path.move(to: CGPoint(x: cx, y: cy))
                    path.addLine(to: CGPoint(x: cx + labelOffX, y: cy + labelOffY))
                }
                .stroke(isSelected ? Theme.accent : Color(hex: "#00d4aa").opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                
                // Label
                let labelX = cx + labelOffX + (labelSide == "left" ? -labelWidth - 14 : 6)
                let labelY = cy + labelOffY - 8
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 12, weight: .bold, family: Theme.fontFamily))
                        .foregroundColor(isSelected ? Theme.accent : Theme.textPrimary)
                    
                    if !sublabel.isEmpty {
                        Text(sublabel)
                            .font(.system(size: 10, family: Theme.fontFamily))
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: 220, alignment: .leading)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Theme.accent.opacity(0.12) : Color.black.opacity(0.35))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Theme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
                )
                .position(x: labelX + labelWidth / 2, y: labelY + labelHeight / 2)
                .onTapGesture {
                    onSelect()
                }
                
                // Small dot at end of line
                Circle()
                    .fill(isSelected ? Theme.accent : Color(hex: "#00d4aa").opacity(0.5))
                    .frame(width: 6, height: 6)
                    .position(x: cx + labelOffX, y: cy + labelOffY)
            }
        }
    }
    
    var labelWidth: CGFloat {
        // Approximate width calculation
        let textWidth = (label as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: 12, weight: .bold)]).width
        let subWidth = (sublabel as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: 10)]).width
        return min(max(textWidth, subWidth, 60) + 20, 240)
    }
    
    var labelHeight: CGFloat {
        sublabel.isEmpty ? 28 : 42
    }
}
