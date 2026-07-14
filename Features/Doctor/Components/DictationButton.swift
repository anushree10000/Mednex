import SwiftUI

struct DictationButton: View {
    @Binding var text: String
    @State private var recognizer = SpeechRecognizer()
    @State private var isDictating = false
    
    var body: some View {
        Button {
            HapticManager.light()
            if isDictating {
                stopDictating()
            } else {
                startDictating()
            }
        } label: {
            Image(systemName: isDictating ? "mic.fill" : "mic")
                .foregroundStyle(isDictating ? MedNexTheme.Colors.error : MedNexTheme.Colors.primary)
                .font(.title3)
                .padding(8)
                .background(
                    Circle()
                        .fill(isDictating ? MedNexTheme.Colors.error.opacity(0.15) : MedNexTheme.Colors.primary.opacity(0.1))
                )
                .scaleEffect(isDictating ? 1.1 : 1.0)
                .animation(MedNexTheme.Animation.bouncy, value: isDictating)
        }
        .onChange(of: recognizer.transcript) { oldTranscript, newTranscript in
            if isDictating {
                // Determine the difference to append
                if newTranscript.starts(with: oldTranscript) {
                    let diff = newTranscript.dropFirst(oldTranscript.count)
                    text += diff
                } else if !newTranscript.isEmpty {
                    // Fallback to just appending what is new (or rewriting)
                    // If the transcription engine resets, we just append a space and the new word
                    text += (text.isEmpty || text.hasSuffix(" ") ? "" : " ") + newTranscript
                    recognizer.transcript = "" // Reset to avoid double appending
                }
            }
        }
    }
    
    private func startDictating() {
        isDictating = true
        recognizer.startTranscribing()
    }
    
    private func stopDictating() {
        isDictating = false
        recognizer.stopTranscribing()
        recognizer.transcript = ""
    }
}
