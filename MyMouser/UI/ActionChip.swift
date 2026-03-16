import SwiftUI

struct ActionChip: View {
    let actionId: String
    let actionLabel: String
    let isCurrent: Bool
    let onPicked: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Text(actionLabel)
            .font(.system(size: 12, family: Theme.fontFamily))
            .foregroundColor(isCurrent ? Theme.bgSidebar : Theme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCurrent ? Theme.accent : (isHovered ? Theme.bgCardHover : Theme.bgCard))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isCurrent ? Theme.accent : Theme.border, lineWidth: 1)
            )
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                onPicked()
            }
            .animation(.easeInOut(duration: 0.12))
    }
}
