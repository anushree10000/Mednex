import SwiftUI

struct WritingToolsButton: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        Button {
            HapticManager.light()
            isPresented = true
        } label: {
            Image(systemName: "wand.and.stars")
                .foregroundStyle(MedNexTheme.Colors.primary)
                .font(.title3)
                .padding(8)
                .background(
                    Circle()
                        .fill(MedNexTheme.Colors.primary.opacity(0.1))
                )
        }
    }
}
