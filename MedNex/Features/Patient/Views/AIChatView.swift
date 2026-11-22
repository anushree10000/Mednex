//
//  AIChatView.swift
//  MedNex
//

import SwiftUI

struct AIChatView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, content: "Hello! I'm your MedNex AI Health Assistant. I can help you understand your symptoms, suggest which department to visit, and even help you book an appointment. How can I help you today?")
    ]
    @State private var inputText = ""
    @State private var isTyping = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Disclaimer
            HStack(spacing: MedNexTheme.Spacing.xs) {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(MedNexTheme.Colors.warning)
                Text("AI suggestions are not medical advice. Always consult a doctor.")
                    .font(MedNexTheme.Typography.caption)
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.vertical, MedNexTheme.Spacing.xs)
            .background(MedNexTheme.Colors.elevatedBackground)
            
            // Messages
            ScrollView {
                LazyVStack(spacing: MedNexTheme.Spacing.sm) {
                    ForEach(messages) { message in
                        chatBubble(message)
                    }
                    
                    if isTyping {
                        HStack {
                            typingIndicator
                            Spacer()
                        }
                        .padding(.horizontal, MedNexTheme.Spacing.md)
                    }
                }
                .padding(.vertical, MedNexTheme.Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            
            // Input Bar
            HStack(spacing: MedNexTheme.Spacing.sm) {
                TextField("Describe your symptoms...", text: $inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    .padding(.horizontal, MedNexTheme.Spacing.lg)
                    .padding(.vertical, MedNexTheme.Spacing.sm)
                    .frame(minHeight: 44)
                    .background(MedNexTheme.Colors.elevatedBackground, in: Capsule())
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(inputText.isEmpty ? MedNexTheme.Colors.textTertiary : MedNexTheme.Colors.primary)
                }
                .disabled(inputText.isEmpty)
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.vertical, MedNexTheme.Spacing.sm)
            .background(MedNexTheme.Colors.secondaryBackground.opacity(0.95))
        }
        .navigationTitle("AI Health Assistant")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
    }
    
    @ViewBuilder
    private func chatBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer() }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: MedNexTheme.Spacing.xxs) {
                Text(message.content)
                    .font(MedNexTheme.Typography.body)
                    .foregroundStyle(message.role == .user ? .white : MedNexTheme.Colors.textPrimary)
                
                // Suggested actions
                if let specialty = message.suggestedSpecialty {
                    Button {
                        HapticManager.light()
                    } label: {
                        Label("Book \(specialty.rawValue)", systemImage: "calendar.badge.plus")
                            .font(MedNexTheme.Typography.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(message.role == .user ? .white : MedNexTheme.Colors.primary)
                }
                
                if let urgency = message.urgencyLevel {
                    StatusBadge(
                        text: "\(urgency.displayName) Urgency",
                        color: Color(hex: urgency.color),
                        icon: "exclamationmark.triangle.fill"
                    )
                }
                
                Text(message.timestamp.timeOnly)
                    .font(MedNexTheme.Typography.caption2)
                    .foregroundStyle(message.role == .user ? Color.white.opacity(0.7) : MedNexTheme.Colors.textTertiary)
            }
            .padding(MedNexTheme.Spacing.sm)
            .background(
                message.role == .user
                    ? AnyShapeStyle(MedNexTheme.Colors.primary)
                    : AnyShapeStyle(MedNexTheme.Colors.cardBackground),
                in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg)
            )
            .frame(maxWidth: 300, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .assistant { Spacer() }
        }
        .padding(.horizontal, MedNexTheme.Spacing.md)
    }
    
    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(MedNexTheme.Colors.textTertiary)
                    .frame(width: 8, height: 8)
                    .opacity(0.5)
            }
        }
        .padding(MedNexTheme.Spacing.sm)
        .background(MedNexTheme.Colors.cardBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md))
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        HapticManager.light()
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        
        isTyping = true
        
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            
            await MainActor.run {
                isTyping = false
                let response = generateAIResponse(for: text)
                messages.append(response)
                HapticManager.light()
            }
        }
    }
    
    private func generateAIResponse(for input: String) -> ChatMessage {
        let lowered = input.lowercased()
        
        if lowered.contains("headache") || lowered.contains("head") || lowered.contains("migraine") {
            return ChatMessage(role: .assistant, content: "Based on your symptoms, I'd recommend consulting with our **Neurology** department. Persistent headaches should be evaluated by a specialist. Would you like to book an appointment?", suggestedSpecialty: .neurology, urgencyLevel: .moderate)
        } else if lowered.contains("chest") || lowered.contains("heart") || lowered.contains("palpitation") {
            return ChatMessage(role: .assistant, content: "Chest-related symptoms should be evaluated promptly. I recommend visiting our **Cardiology** department. If you're experiencing severe chest pain, please seek emergency care immediately.", suggestedSpecialty: .cardiology, urgencyLevel: .high)
        } else if lowered.contains("skin") || lowered.contains("rash") || lowered.contains("acne") {
            return ChatMessage(role: .assistant, content: "For skin-related concerns, our **Dermatology** department would be the best fit. Would you like me to show available appointments?", suggestedSpecialty: .dermatology, urgencyLevel: .low)
        } else if lowered.contains("fever") || lowered.contains("cold") || lowered.contains("cough") {
            return ChatMessage(role: .assistant, content: "Common fever and cold symptoms are best managed by **General Medicine**. If your fever is above 103°F or persistent for more than 3 days, please visit sooner.", suggestedSpecialty: .generalMedicine, urgencyLevel: .moderate)
        } else if lowered.contains("child") || lowered.contains("kid") || lowered.contains("baby") {
            return ChatMessage(role: .assistant, content: "For children's health concerns, our **Pediatrics** department specializes in care for kids and adolescents.", suggestedSpecialty: .pediatrics, urgencyLevel: .moderate)
        } else {
            return ChatMessage(role: .assistant, content: "Thank you for sharing that. I'd recommend starting with a **General Medicine** consultation for a comprehensive evaluation. The doctor can then refer you to a specialist if needed. Would you like to book an appointment?", suggestedSpecialty: .generalMedicine, urgencyLevel: .low)
        }
    }
}
