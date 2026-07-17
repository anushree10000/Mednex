//
//  MedicalRecordsView.swift
//  MedNex
//
//  Three-tab medical records: Visits, Lab Results, Documents
//  Supports document upload from Photos/Files, shows prescriptions & lab results,
//  and enables sharing/downloading as professional hospital PDFs.

import SwiftUI
import PhotosUI
import SafariServices
import PDFKit

struct MedicalRecordsView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var selectedTab = 0
    @State private var pdfURL: URL?
    @State private var showShareSheet = false
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isUploading = false
    @State private var animateCards = false
    
    @State private var previewURL: URL?
    @State private var showPreview = false
    @State private var showPDFPreview = false
    @State private var previewPDFData: Data?
    @State private var previewPDFTitle: String = ""
    
    private var completedAppointments: [Appointment] {
        dataStore.appointments
            .filter { $0.status == .completed || $0.status == .inProgress }
            .sorted { $0.dateTime > $1.dateTime }
    }
    
    private var completedLabTests: [LabTest] {
        dataStore.labTests.filter { $0.status == .completed }.sorted { ($0.completedAt ?? $0.orderedAt) > ($1.completedAt ?? $1.orderedAt) }
    }
    
    private func prescriptions(for appointmentId: String) -> [Prescription] {
        dataStore.prescriptions.filter { $0.appointmentId == appointmentId }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Segmented Control
            Picker("Records", selection: $selectedTab) {
                Text("Visits").tag(0)
                Text("Lab Results").tag(1)
                Text("Documents").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.vertical, MedNexTheme.Spacing.sm)
            
            ScrollView {
                switch selectedTab {
                case 0:
                    visitsTab
                case 1:
                    labResultsTab
                case 2:
                    documentsTab
                default:
                    EmptyView()
                }
            }
        }
        .navigationTitle("Medical Records")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) { animateCards = true }
            dataStore.loadPatientDocuments(patientId: dataStore.patient.id)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ActivityView(activityItems: [url])
                    .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $showPreview) {
            if let url = previewURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showPDFPreview) {
            if let data = previewPDFData {
                PDFPreviewView(pdfData: data, title: previewPDFTitle)
            }
        }
        .sheet(isPresented: $showFilePicker) {
            DocumentPickerView { urls in
                isUploading = true
                Task {
                    for url in urls {
                        if let data = try? Data(contentsOf: url) {
                            let contentType = url.pathExtension == "pdf" ? "application/pdf" : "application/octet-stream"
                            dataStore.uploadPatientDocument(
                                patientId: dataStore.patient.id,
                                fileName: url.lastPathComponent,
                                data: data,
                                contentType: contentType
                            )
                        }
                    }
                    await MainActor.run { isUploading = false }
                }
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItems, maxSelectionCount: 10, matching: .images)
        .onChange(of: selectedPhotoItems) { _, newItems in
            isUploading = true
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        let fileName = "Photo_\(Date().timeIntervalSince1970).jpg"
                        dataStore.uploadPatientDocument(
                            patientId: dataStore.patient.id,
                            fileName: fileName,
                            data: data,
                            contentType: "image/jpeg"
                        )
                    }
                }
                await MainActor.run {
                    isUploading = false
                    selectedPhotoItems = []
                }
            }
        }
    }
    
    // MARK: - Visits Tab
    private var visitsTab: some View {
        Group {
            if completedAppointments.isEmpty {
                EmptyStateView(icon: "doc.text.fill", title: "No Visit Records", message: "Your visit records will appear here after your appointments.")
            } else {
                LazyVStack(spacing: MedNexTheme.Spacing.md) {
                    ForEach(completedAppointments) { appointment in
                        visitRecordCard(appointment)
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.bottom, MedNexTheme.Spacing.xxl)
            }
        }
    }
    
    private func visitRecordCard(_ appointment: Appointment) -> some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
            // Header
            HStack {
                HStack(spacing: MedNexTheme.Spacing.sm) {
                    Image(systemName: "stethoscope")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(MedNexTheme.Colors.primary)
                        .frame(width: 32, height: 32)
                        .background(MedNexTheme.Colors.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(appointment.doctorName)
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                        Text(appointment.specialty.rawValue)
                            .font(MedNexTheme.Typography.caption)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(appointment.dateTime.shortDate)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    StatusBadge(text: appointment.status == .completed ? "Completed" : "In Progress",
                               color: appointment.status == .completed ? MedNexTheme.Colors.success : MedNexTheme.Colors.info,
                               icon: appointment.status == .completed ? "checkmark.circle.fill" : "clock.fill")
                }
            }
            
            // Notes
            if !appointment.notes.isEmpty {
                Divider()
                Text(appointment.notes)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    .lineSpacing(2)
            }
            
            // Prescriptions
            let rxList = prescriptions(for: appointment.id)
            if let rx = rxList.first {
                Divider()
                HStack(spacing: MedNexTheme.Spacing.sm) {
                    Image(systemName: "pills.fill")
                        .foregroundStyle(MedNexTheme.Colors.success)
                    Text("\(rx.medicines.count) medications prescribed")
                        .font(MedNexTheme.Typography.subheadline)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    Spacer()
                }
                
                // Show medicine names
                ForEach(rx.medicines.prefix(3)) { med in
                    Text("• \(med.name) — \(med.dosage), \(med.frequency.rawValue)")
                        .font(MedNexTheme.Typography.caption)
                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                }
                if rx.medicines.count > 3 {
                    Text("  + \(rx.medicines.count - 3) more")
                        .font(MedNexTheme.Typography.caption)
                        .foregroundStyle(MedNexTheme.Colors.primary)
                }
            }
            
            // Action Buttons
            Divider()
            HStack(spacing: MedNexTheme.Spacing.sm) {
                Button {
                    HapticManager.success()
                    previewVisitPDF(for: appointment)
                } label: {
                    Label("Preview", systemImage: "eye.fill")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                }
                .buttonStyle(.bordered)
                .tint(MedNexTheme.Colors.primary)
                
                Button {
                    HapticManager.success()
                    downloadVisitPDF(for: appointment)
                } label: {
                    Label("Download", systemImage: "arrow.down.doc.fill")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                }
                .buttonStyle(.bordered)
                .tint(MedNexTheme.Colors.success)
                
                Button {
                    HapticManager.success()
                    generateVisitPDF(for: appointment)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                }
                .buttonStyle(.bordered)
                .tint(MedNexTheme.Colors.info)
            }
        }
        .padding(MedNexTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg)
                .fill(MedNexTheme.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
        .onTapGesture {
            HapticManager.selection()
            previewVisitPDF(for: appointment)
        }
    }
    
    // MARK: - Lab Results Tab
    private var labResultsTab: some View {
        Group {
            if completedLabTests.isEmpty {
                EmptyStateView(icon: "flask.fill", title: "No Lab Results", message: "Your lab test results will appear here when completed.")
            } else {
                LazyVStack(spacing: MedNexTheme.Spacing.md) {
                    ForEach(completedLabTests) { test in
                        labResultCard(test)
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.bottom, MedNexTheme.Spacing.xxl)
            }
        }
    }
    
    private func labResultCard(_ test: LabTest) -> some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
            // Header
            HStack {
                HStack(spacing: MedNexTheme.Spacing.sm) {
                    Image(systemName: "flask.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(MedNexTheme.Colors.warning)
                        .frame(width: 32, height: 32)
                        .background(MedNexTheme.Colors.warning.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(test.testName)
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                        Text(test.testCategory.rawValue)
                            .font(MedNexTheme.Typography.caption)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text((test.completedAt ?? test.orderedAt).shortDate)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    StatusBadge(text: "Completed", color: MedNexTheme.Colors.success, icon: "checkmark.circle.fill")
                }
            }
            
            // Results Table
            if !test.results.isEmpty {
                Divider()
                VStack(spacing: 0) {
                    // Header row
                    HStack {
                        Text("Parameter")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Value")
                            .frame(width: 60, alignment: .trailing)
                        Text("Unit")
                            .frame(width: 50, alignment: .trailing)
                        Text("Normal")
                            .frame(width: 70, alignment: .trailing)
                    }
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                    .padding(.vertical, 6)
                    .padding(.horizontal, MedNexTheme.Spacing.xs)
                    .background(MedNexTheme.Colors.primary.opacity(0.05))
                    
                    ForEach(test.results) { result in
                        HStack {
                            Text(result.parameterName)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(result.value)
                                .foregroundStyle(result.isAbnormal ? .red : MedNexTheme.Colors.textPrimary)
                                .fontWeight(result.isAbnormal ? .bold : .regular)
                                .frame(width: 60, alignment: .trailing)
                            Text(result.unit)
                                .frame(width: 50, alignment: .trailing)
                            Text(result.normalRange)
                                .frame(width: 70, alignment: .trailing)
                        }
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, MedNexTheme.Spacing.xs)
                    }
                }
                .background(MedNexTheme.Colors.background.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
            }
            
            // Ordered by
            if !test.doctorName.isEmpty && test.doctorName != "Self-Requested" {
                HStack(spacing: 4) {
                    Image(systemName: "stethoscope")
                    Text("Ordered by \(test.doctorName)")
                }
                .font(MedNexTheme.Typography.caption)
                .foregroundStyle(MedNexTheme.Colors.textTertiary)
            }
            
            // Actions
            Divider()
            HStack(spacing: MedNexTheme.Spacing.sm) {
                Button {
                    HapticManager.success()
                    previewLabPDF(for: test)
                } label: {
                    Label("Preview", systemImage: "eye.fill")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                }
                .buttonStyle(.bordered)
                .tint(MedNexTheme.Colors.primary)
                
                Button {
                    HapticManager.success()
                    downloadLabPDF(for: test)
                } label: {
                    Label("Download", systemImage: "arrow.down.doc.fill")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                }
                .buttonStyle(.bordered)
                .tint(MedNexTheme.Colors.success)
                
                Button {
                    HapticManager.success()
                    generateLabPDF(for: test)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                }
                .buttonStyle(.bordered)
                .tint(MedNexTheme.Colors.info)
            }
        }
        .padding(MedNexTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg)
                .fill(MedNexTheme.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
        .onTapGesture {
            HapticManager.selection()
            previewLabPDF(for: test)
        }
    }
    
    // MARK: - Documents Tab
    private var documentsTab: some View {
        VStack(spacing: MedNexTheme.Spacing.md) {
            // Upload Buttons
            HStack(spacing: MedNexTheme.Spacing.sm) {
                Button {
                    HapticManager.selection()
                    showPhotoPicker = true
                } label: {
                    VStack(spacing: MedNexTheme.Spacing.xs) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title2)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        Text("From Photos")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MedNexTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg)
                            .fill(MedNexTheme.Colors.cardBackground)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    )
                }
                
                Button {
                    HapticManager.selection()
                    showFilePicker = true
                } label: {
                    VStack(spacing: MedNexTheme.Spacing.xs) {
                        Image(systemName: "doc.badge.plus")
                            .font(.title2)
                            .foregroundStyle(MedNexTheme.Colors.info)
                        Text("From Files")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MedNexTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg)
                            .fill(MedNexTheme.Colors.cardBackground)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    )
                }
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            
            if isUploading {
                HStack(spacing: MedNexTheme.Spacing.sm) {
                    ProgressView()
                    Text("Uploading…")
                        .font(MedNexTheme.Typography.subheadline)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                }
                .padding(.vertical, MedNexTheme.Spacing.md)
            }
            
            if dataStore.patientDocuments.isEmpty {
                EmptyStateView(icon: "folder.fill", title: "No Documents", message: "Upload medical documents from your Photos or Files app. They'll be securely stored in the cloud.")
                    .padding(.top, MedNexTheme.Spacing.xl)
            } else {
                LazyVStack(spacing: MedNexTheme.Spacing.sm) {
                    ForEach(dataStore.patientDocuments) { doc in
                        supabaseDocumentRow(doc)
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.bottom, MedNexTheme.Spacing.xxl)
            }
        }
    }
    
    private func supabaseDocumentRow(_ doc: PatientDocument) -> some View {
        let isPhoto = doc.name.lowercased().hasSuffix(".jpg") || doc.name.lowercased().hasSuffix(".jpeg") || doc.name.lowercased().hasSuffix(".png") || doc.name.lowercased().hasSuffix(".heic")
        let docURL = dataStore.documentPublicURL(for: doc)
        
        return HStack(spacing: MedNexTheme.Spacing.md) {
            Image(systemName: isPhoto ? "photo.fill" : "doc.fill")
                .font(.title3)
                .foregroundStyle(isPhoto ? MedNexTheme.Colors.primary : MedNexTheme.Colors.info)
                .frame(width: 48, height: 48)
                .background(
                    (isPhoto ? MedNexTheme.Colors.primary : MedNexTheme.Colors.info).opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 8)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(doc.name)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    .lineLimit(1)
                Text(doc.uploadedAt.shortDate)
                    .font(MedNexTheme.Typography.caption)
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
            }
            
            Spacer()
            
            if let url = docURL {
                ShareLink(item: url) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body)
                        .foregroundStyle(MedNexTheme.Colors.primary)
                        .padding(8) // generous hit target
                }
            }
        }
        .padding(MedNexTheme.Spacing.sm)
        .contentShape(Rectangle())
        .onTapGesture {
            if let url = docURL {
                previewURL = url
                showPreview = true
            }
        }
        .background(
            RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md)
                .fill(MedNexTheme.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - PDF Generation
    private func generateVisitPDF(for appointment: Appointment) {
        let rxList = prescriptions(for: appointment.id)
        let pdfData = MedicalRecordPDFGenerator.generatePDF(
            for: appointment,
            patient: dataStore.patient,
            prescriptions: rxList
        )
        sharePDFData(pdfData, fileName: "MedNex_Visit_\(appointment.id.prefix(6)).pdf")
    }
    
    private func generateLabPDF(for test: LabTest) {
        let pdfData = MedicalRecordPDFGenerator.generateLabReportPDF(
            for: test,
            patient: dataStore.patient
        )
        sharePDFData(pdfData, fileName: "MedNex_LabReport_\(test.id.prefix(6)).pdf")
    }
    
    private func sharePDFData(_ data: Data, fileName: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: tempURL)
            pdfURL = tempURL
            showShareSheet = true
        } catch {
            print("Failed to write PDF: \(error)")
        }
    }
    
    // MARK: - Preview Functions
    private func previewVisitPDF(for appointment: Appointment) {
        let rxList = prescriptions(for: appointment.id)
        let pdfData = MedicalRecordPDFGenerator.generatePDF(
            for: appointment,
            patient: dataStore.patient,
            prescriptions: rxList
        )
        previewPDFData = pdfData
        previewPDFTitle = "Visit — \(appointment.doctorName)"
        showPDFPreview = true
    }
    
    private func previewLabPDF(for test: LabTest) {
        let pdfData = MedicalRecordPDFGenerator.generateLabReportPDF(
            for: test,
            patient: dataStore.patient
        )
        previewPDFData = pdfData
        previewPDFTitle = "Lab Report — \(test.testName)"
        showPDFPreview = true
    }
    
    // MARK: - Download Functions (save to Files via share sheet with save option)
    private func downloadVisitPDF(for appointment: Appointment) {
        let rxList = prescriptions(for: appointment.id)
        let pdfData = MedicalRecordPDFGenerator.generatePDF(
            for: appointment,
            patient: dataStore.patient,
            prescriptions: rxList
        )
        sharePDFData(pdfData, fileName: "MedNex_Visit_\(appointment.doctorName.replacingOccurrences(of: " ", with: "_"))_\(appointment.dateTime.shortDate).pdf")
    }
    
    private func downloadLabPDF(for test: LabTest) {
        let pdfData = MedicalRecordPDFGenerator.generateLabReportPDF(
            for: test,
            patient: dataStore.patient
        )
        sharePDFData(pdfData, fileName: "MedNex_LabReport_\(test.testName.replacingOccurrences(of: " ", with: "_"))_\((test.completedAt ?? test.orderedAt).shortDate).pdf")
    }
}

// MARK: - PDF Preview View
struct PDFPreviewView: View {
    let pdfData: Data
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationStack {
            PDFKitView(data: pdfData)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.body)
                        }
                    }
                }
                .sheet(isPresented: $showShareSheet) {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(title.replacingOccurrences(of: " ", with: "_")).pdf")
                    if let _ = try? pdfData.write(to: tempURL) {
                        ActivityView(activityItems: [tempURL])
                            .presentationDetents([.medium, .large])
                    }
                }
        }
    }
}

// MARK: - PDFKit SwiftUI Wrapper
struct PDFKitView: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(data: data)
        pdfView.backgroundColor = UIColor.systemBackground
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document == nil {
            uiView.document = PDFDocument(data: data)
        }
    }
}

// MARK: - Supporting Types

struct UploadedDocument: Identifiable {
    let id = UUID().uuidString
    let name: String
    let type: DocumentType
    let dateAdded: Date
    var fileURL: URL?
    var thumbnailData: Data?
    
    enum DocumentType {
        case photo, file
    }
}

// MARK: - Document Picker (UIKit Bridge)
struct DocumentPickerView: UIViewControllerRepresentable {
    let onPick: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image, .data])
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([URL]) -> Void
        init(onPick: @escaping ([URL]) -> Void) { self.onPick = onPick }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls)
        }
    }
}

// MARK: - Activity View (reliable share sheet)
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Present the activity view controller after a brief delay to avoid blank screen
        guard uiViewController.presentedViewController == nil else { return }
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        activityVC.completionWithItemsHandler = { _, _, _, _ in }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            uiViewController.present(activityVC, animated: true)
        }
    }
}

// MARK: - Safari View (Web Preview)
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
