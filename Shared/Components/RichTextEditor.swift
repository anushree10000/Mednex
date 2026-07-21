import SwiftUI
import UIKit

/// A robust `UITextView` wrapper to guarantee iOS 18 Apple Intelligence Writing Tools support.
/// SwiftUI's native `TextEditor` and `TextField(axis: .vertical)` frequently drop Writing Tools 
/// in complex layouts or when custom background modifiers are applied.
struct RichTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var showWritingTools: Bool
    var placeholder: String = ""
    var minHeight: CGFloat = 40
    
    init(text: Binding<String>, showWritingTools: Binding<Bool> = .constant(false), placeholder: String = "", minHeight: CGFloat = 40) {
        self._text = text
        self._showWritingTools = showWritingTools
        self.placeholder = placeholder
        self.minHeight = minHeight
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear // Let SwiftUI handle the background
        textView.isScrollEnabled = true
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        
        // Explicitly enable Apple Intelligence Writing Tools (iOS 18+)
        if #available(iOS 18.0, *) {
            textView.writingToolsBehavior = .complete
        }
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        
        if showWritingTools {
            DispatchQueue.main.async {
                // Programmatically trigger the edit menu by selecting all text
                uiView.becomeFirstResponder()
                uiView.selectAll(nil)
                
                // Reset the binding after triggering
                self.showWritingTools = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}
