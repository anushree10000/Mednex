//
//  MedicalRecordPDFGenerator.swift
//  MedNex
//
//  Generates a hospital-grade PDF for medical records using Core Graphics.
//  Designed for seamless backend swap — replace static content with API data.

import UIKit
import PDFKit

struct MedicalRecordPDFGenerator {
    
    // MARK: - Hospital Branding
    
    private static let hospitalName = "MedNex Hospital"
    private static let hospitalTagline = "Your Health, Connected."
    private static let hospitalAddress = "123 Healthcare Avenue, Medical District, San Francisco, CA 94102"
    private static let hospitalPhone = "+1 (800) MED-NEXX"
    private static let hospitalEmail = "records@mednex.com"
    private static let hospitalWebsite = "www.mednex.com"
    
    // MARK: - Colour Palette
    
    private static let brandBlue = UIColor(red: 0.20, green: 0.50, blue: 0.85, alpha: 1.0)
    private static let lightBlue = UIColor(red: 0.90, green: 0.95, blue: 1.0, alpha: 1.0)
    private static let darkText = UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)
    private static let secondaryText = UIColor(red: 0.45, green: 0.45, blue: 0.50, alpha: 1.0)
    private static let dividerColor = UIColor(red: 0.85, green: 0.88, blue: 0.92, alpha: 1.0)
    private static let tableHeaderBg = UIColor(red: 0.20, green: 0.50, blue: 0.85, alpha: 0.08)
    
    // MARK: - Generate PDF
    
    static func generatePDF(
        for appointment: Appointment,
        patient: Patient,
        prescriptions: [Prescription]
    ) -> Data {
        let pageWidth: CGFloat = 612   // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - (margin * 2)
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        
        let data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = margin
            
            // ── Header Band ──
            let headerRect = CGRect(x: 0, y: 0, width: pageWidth, height: 100)
            brandBlue.setFill()
            context.cgContext.fill(headerRect)
            
            // Hospital Logo (cross symbol)
            let logoRect = CGRect(x: margin, y: 20, width: 60, height: 60)
            drawHospitalLogo(in: logoRect, context: context.cgContext)
            
            // Hospital Name
            let hospitalNameAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let nameStr = NSAttributedString(string: hospitalName, attributes: hospitalNameAttr)
            nameStr.draw(at: CGPoint(x: margin + 70, y: 24))
            
            // Tagline
            let taglineAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.85)
            ]
            NSAttributedString(string: hospitalTagline, attributes: taglineAttr)
                .draw(at: CGPoint(x: margin + 70, y: 52))
            
            // Contact info on the right
            let contactAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 7.5, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
            let contactLines = [hospitalAddress, "\(hospitalPhone)  |  \(hospitalEmail)", hospitalWebsite]
            for (i, line) in contactLines.enumerated() {
                let lineStr = NSAttributedString(string: line, attributes: contactAttr)
                let lineSize = lineStr.size()
                lineStr.draw(at: CGPoint(x: pageWidth - margin - lineSize.width, y: 25 + CGFloat(i) * 14))
            }
            
            y = 115
            
            // ── Document Title ──
            let titleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                .foregroundColor: brandBlue
            ]
            NSAttributedString(string: "MEDICAL RECORD", attributes: titleAttr)
                .draw(at: CGPoint(x: margin, y: y))
            
            // Record ID on the right
            let recordIdAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 9, weight: .medium),
                .foregroundColor: secondaryText
            ]
            let recordId = "MRN-\(appointment.id.prefix(8).uppercased())"
            let recordIdStr = NSAttributedString(string: recordId, attributes: recordIdAttr)
            let idSize = recordIdStr.size()
            recordIdStr.draw(at: CGPoint(x: pageWidth - margin - idSize.width, y: y + 5))
            
            y += 30
            
            // ── Thin divider ──
            drawDivider(at: y, margin: margin, width: contentWidth)
            y += 12
            
            // ── Patient Information Box ──
            y = drawSectionHeader("PATIENT INFORMATION", at: y, margin: margin, width: contentWidth)
            y += 8
            
            let patientInfo: [(String, String)] = [
                ("Full Name", patient.personalInfo.fullName),
                ("Date of Birth", patient.personalInfo.dateOfBirth.shortDate),
                ("Age / Gender", "\(patient.personalInfo.age) years  •  \(patient.personalInfo.gender.displayName)"),
                ("Blood Group", patient.medicalInfo.bloodType.rawValue),
                ("Phone", patient.personalInfo.phone),
                ("Address", "\(patient.personalInfo.address), \(patient.personalInfo.city)")
            ]
            y = drawInfoGrid(patientInfo, at: y, margin: margin, width: contentWidth, columns: 2)
            y += 16
            
            // ── Visit Details Box ──
            y = drawSectionHeader("VISIT DETAILS", at: y, margin: margin, width: contentWidth)
            y += 8
            
            let visitInfo: [(String, String)] = [
                ("Date", appointment.dateTime.medicalFormat),
                ("Doctor", appointment.doctorName),
                ("Specialty", appointment.specialty.rawValue),
                ("Visit Type", appointment.type.displayName),
                ("Status", appointment.status.displayName),
                ("Billing", appointment.billingStatus.displayName)
            ]
            y = drawInfoGrid(visitInfo, at: y, margin: margin, width: contentWidth, columns: 2)
            y += 16
            
            // ── Diagnosis / Notes ──
            if !appointment.notes.isEmpty {
                y = drawSectionHeader("DIAGNOSIS / CLINICAL NOTES", at: y, margin: margin, width: contentWidth)
                y += 8
                
                let _ = CGRect(x: margin, y: y, width: contentWidth, height: 0)
                let notesAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                    .foregroundColor: darkText,
                    .paragraphStyle: {
                        let ps = NSMutableParagraphStyle()
                        ps.lineSpacing = 4
                        return ps
                    }()
                ]
                let notesStr = NSAttributedString(string: appointment.notes, attributes: notesAttr)
                let notesSize = notesStr.boundingRect(with: CGSize(width: contentWidth - 16, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], context: nil)
                
                // Light background box
                let boxRect = CGRect(x: margin, y: y, width: contentWidth, height: notesSize.height + 16)
                lightBlue.setFill()
                UIBezierPath(roundedRect: boxRect, cornerRadius: 4).fill()
                
                notesStr.draw(in: CGRect(x: margin + 8, y: y + 8, width: contentWidth - 16, height: notesSize.height + 4))
                y += boxRect.height + 16
            }
            
            // ── Prescriptions Table ──
            if let rx = prescriptions.first(where: { $0.appointmentId == appointment.id }) {
                y = drawSectionHeader("PRESCRIBED MEDICATIONS", at: y, margin: margin, width: contentWidth)
                y += 8
                
                // Table header
                let headers = ["Medicine", "Dosage", "Frequency", "Duration", "Instructions"]
                let colWidths: [CGFloat] = [0.22, 0.12, 0.18, 0.15, 0.33].map { $0 * contentWidth }
                
                let headerAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 8, weight: .bold),
                    .foregroundColor: brandBlue
                ]
                
                // Header bg
                let headerBgRect = CGRect(x: margin, y: y, width: contentWidth, height: 22)
                tableHeaderBg.setFill()
                UIBezierPath(roundedRect: headerBgRect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 4, height: 4)).fill()
                
                var colX = margin + 6
                for (i, header) in headers.enumerated() {
                    NSAttributedString(string: header.uppercased(), attributes: headerAttr)
                        .draw(at: CGPoint(x: colX, y: y + 6))
                    colX += colWidths[i]
                }
                y += 24
                
                // Table rows
                let cellAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                    .foregroundColor: darkText
                ]
                
                for (index, med) in rx.medicines.enumerated() {
                    // Alternate row bg
                    if index % 2 == 0 {
                        let rowBg = CGRect(x: margin, y: y, width: contentWidth, height: 20)
                        UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1).setFill()
                        context.cgContext.fill(rowBg)
                    }
                    
                    colX = margin + 6
                    let values = [med.name, med.dosage, med.frequency.rawValue, med.duration, med.instructions.isEmpty ? "—" : med.instructions]
                    for (i, val) in values.enumerated() {
                        let cellRect = CGRect(x: colX, y: y + 4, width: colWidths[i] - 8, height: 14)
                        NSAttributedString(string: val, attributes: cellAttr)
                            .draw(in: cellRect)
                        colX += colWidths[i]
                    }
                    y += 22
                }
                
                // Table bottom border
                drawDivider(at: y, margin: margin, width: contentWidth)
                y += 16
            }
            
            // ── Allergies & Conditions ──
            if !patient.medicalInfo.allergies.isEmpty || !patient.medicalInfo.chronicConditions.isEmpty {
                y = drawSectionHeader("KNOWN ALLERGIES & CONDITIONS", at: y, margin: margin, width: contentWidth)
                y += 8
                
                let warningAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9, weight: .medium),
                    .foregroundColor: UIColor(red: 0.85, green: 0.20, blue: 0.15, alpha: 1)
                ]
                
                if !patient.medicalInfo.allergies.isEmpty {
                    let allergyText = "⚠ Allergies: \(patient.medicalInfo.allergies.joined(separator: ", "))"
                    NSAttributedString(string: allergyText, attributes: warningAttr).draw(at: CGPoint(x: margin + 4, y: y))
                    y += 16
                }
                
                let condAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                    .foregroundColor: secondaryText
                ]
                if !patient.medicalInfo.chronicConditions.isEmpty {
                    let condText = "Chronic Conditions: \(patient.medicalInfo.chronicConditions.joined(separator: ", "))"
                    NSAttributedString(string: condText, attributes: condAttr).draw(at: CGPoint(x: margin + 4, y: y))
                    y += 16
                }
                y += 8
            }
            
            // ── Footer ──
            let footerY = pageHeight - 60
            
            drawDivider(at: footerY, margin: margin, width: contentWidth)
            
            let footerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 7, weight: .regular),
                .foregroundColor: secondaryText
            ]
            let disclaimerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 7),
                .foregroundColor: secondaryText
            ]
            
            let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short)
            NSAttributedString(string: "Generated on \(dateStr)  •  \(hospitalName)", attributes: footerAttr)
                .draw(at: CGPoint(x: margin, y: footerY + 8))
            
            let disclaimer = "This is a computer-generated document. For official records, please contact the hospital administration."
            NSAttributedString(string: disclaimer, attributes: disclaimerAttr)
                .draw(at: CGPoint(x: margin, y: footerY + 22))
            
            // Confidential watermark (subtle)
            let watermarkAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 7, weight: .medium),
                .foregroundColor: brandBlue.withAlphaComponent(0.4)
            ]
            let confStr = NSAttributedString(string: "CONFIDENTIAL", attributes: watermarkAttr)
            let confSize = confStr.size()
            confStr.draw(at: CGPoint(x: pageWidth - margin - confSize.width, y: footerY + 8))
        }
        
        return data
    }
    
    // MARK: - Drawing Helpers
    
    private static func drawHospitalLogo(in rect: CGRect, context: CGContext) {
        context.saveGState()
        
        // White circle
        UIColor.white.setFill()
        context.fillEllipse(in: rect)
        
        // Blue cross
        let crossColor = brandBlue
        crossColor.setFill()
        
        let cx = rect.midX, cy = rect.midY
        let armW: CGFloat = 8, armH: CGFloat = 24
        context.fill(CGRect(x: cx - armW / 2, y: cy - armH / 2, width: armW, height: armH))
        context.fill(CGRect(x: cx - armH / 2, y: cy - armW / 2, width: armH, height: armW))
        
        context.restoreGState()
    }
    
    private static func drawDivider(at y: CGFloat, margin: CGFloat, width: CGFloat) {
        dividerColor.setStroke()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: margin + width, y: y))
        path.lineWidth = 0.5
        path.stroke()
    }
    
    @discardableResult
    private static func drawSectionHeader(_ title: String, at y: CGFloat, margin: CGFloat, width: CGFloat) -> CGFloat {
        let attr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .bold),
            .foregroundColor: brandBlue,
            .kern: 1.2
        ]
        NSAttributedString(string: title, attributes: attr)
            .draw(at: CGPoint(x: margin, y: y))
        
        // Accent underline
        brandBlue.setStroke()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y + 16))
        path.addLine(to: CGPoint(x: margin + 60, y: y + 16))
        path.lineWidth = 1.5
        path.stroke()
        
        return y + 20
    }
    
    private static func drawInfoGrid(_ items: [(String, String)], at startY: CGFloat, margin: CGFloat, width: CGFloat, columns: Int) -> CGFloat {
        let labelAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .medium),
            .foregroundColor: secondaryText
        ]
        let valueAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: darkText
        ]
        
        let colWidth = width / CGFloat(columns)
        var y = startY
        
        for i in stride(from: 0, to: items.count, by: columns) {
            for col in 0..<columns {
                let idx = i + col
                guard idx < items.count else { break }
                let x = margin + CGFloat(col) * colWidth
                NSAttributedString(string: items[idx].0.uppercased(), attributes: labelAttr).draw(at: CGPoint(x: x, y: y))
                NSAttributedString(string: items[idx].1, attributes: valueAttr).draw(at: CGPoint(x: x, y: y + 12))
            }
            y += 32
        }
        
        return y
    }
    
    // MARK: - Lab Report PDF
    
    static func generateLabReportPDF(
        for test: LabTest,
        patient: Patient
    ) -> Data {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - (margin * 2)
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        
        let data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = margin
            
            // ── Header Band ──
            let headerRect = CGRect(x: 0, y: 0, width: pageWidth, height: 100)
            brandBlue.setFill()
            context.cgContext.fill(headerRect)
            
            let logoRect = CGRect(x: margin, y: 20, width: 60, height: 60)
            drawHospitalLogo(in: logoRect, context: context.cgContext)
            
            let hospitalNameAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            NSAttributedString(string: hospitalName, attributes: hospitalNameAttr)
                .draw(at: CGPoint(x: margin + 70, y: 24))
            
            let taglineAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.85)
            ]
            NSAttributedString(string: hospitalTagline, attributes: taglineAttr)
                .draw(at: CGPoint(x: margin + 70, y: 52))
            
            let contactAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 7.5, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
            let contactLines = [hospitalAddress, "\(hospitalPhone)  |  \(hospitalEmail)", hospitalWebsite]
            for (i, line) in contactLines.enumerated() {
                let lineStr = NSAttributedString(string: line, attributes: contactAttr)
                let lineSize = lineStr.size()
                lineStr.draw(at: CGPoint(x: pageWidth - margin - lineSize.width, y: 25 + CGFloat(i) * 14))
            }
            
            y = 115
            
            // ── Document Title ──
            let titleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                .foregroundColor: brandBlue
            ]
            NSAttributedString(string: "LABORATORY TEST REPORT", attributes: titleAttr)
                .draw(at: CGPoint(x: margin, y: y))
            
            let recordIdAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 9, weight: .medium),
                .foregroundColor: secondaryText
            ]
            let recordId = "LAB-\(test.id.prefix(8).uppercased())"
            let recordIdStr = NSAttributedString(string: recordId, attributes: recordIdAttr)
            let idSize = recordIdStr.size()
            recordIdStr.draw(at: CGPoint(x: pageWidth - margin - idSize.width, y: y + 5))
            
            y += 30
            drawDivider(at: y, margin: margin, width: contentWidth)
            y += 12
            
            // ── Patient Information ──
            y = drawSectionHeader("PATIENT INFORMATION", at: y, margin: margin, width: contentWidth)
            y += 8
            
            let patientInfo: [(String, String)] = [
                ("Full Name", patient.personalInfo.fullName),
                ("Date of Birth", patient.personalInfo.dateOfBirth.shortDate),
                ("Age / Gender", "\(patient.personalInfo.age) years  •  \(patient.personalInfo.gender.displayName)"),
                ("Blood Group", patient.medicalInfo.bloodType.rawValue),
                ("Phone", patient.personalInfo.phone),
                ("Address", "\(patient.personalInfo.address), \(patient.personalInfo.city)")
            ]
            y = drawInfoGrid(patientInfo, at: y, margin: margin, width: contentWidth, columns: 2)
            y += 16
            
            // ── Test Details ──
            y = drawSectionHeader("TEST DETAILS", at: y, margin: margin, width: contentWidth)
            y += 8
            
            let testInfo: [(String, String)] = [
                ("Test Name", test.testName),
                ("Category", test.testCategory.rawValue),
                ("Ordered Date", test.orderedAt.medicalFormat),
                ("Completed Date", (test.completedAt ?? Date()).medicalFormat),
                ("Ordered By", test.doctorName),
                ("Priority", test.priority.displayName),
                ("Status", test.status.displayName)
            ]
            y = drawInfoGrid(testInfo, at: y, margin: margin, width: contentWidth, columns: 2)
            y += 16
            
            // ── Results Table ──
            if !test.results.isEmpty {
                y = drawSectionHeader("TEST RESULTS", at: y, margin: margin, width: contentWidth)
                y += 8
                
                let headers = ["Parameter", "Value", "Unit", "Normal Range", "Status"]
                let colWidths: [CGFloat] = [0.30, 0.15, 0.15, 0.22, 0.18].map { $0 * contentWidth }
                
                let headerAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 8, weight: .bold),
                    .foregroundColor: brandBlue
                ]
                
                let headerBgRect = CGRect(x: margin, y: y, width: contentWidth, height: 22)
                tableHeaderBg.setFill()
                UIBezierPath(roundedRect: headerBgRect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 4, height: 4)).fill()
                
                var colX = margin + 6
                for (i, header) in headers.enumerated() {
                    NSAttributedString(string: header.uppercased(), attributes: headerAttr)
                        .draw(at: CGPoint(x: colX, y: y + 6))
                    colX += colWidths[i]
                }
                y += 24
                
                let cellAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                    .foregroundColor: darkText
                ]
                let abnormalAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9, weight: .bold),
                    .foregroundColor: UIColor(red: 0.85, green: 0.20, blue: 0.15, alpha: 1)
                ]
                
                for (index, result) in test.results.enumerated() {
                    if index % 2 == 0 {
                        let rowBg = CGRect(x: margin, y: y, width: contentWidth, height: 20)
                        UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1).setFill()
                        context.cgContext.fill(rowBg)
                    }
                    
                    colX = margin + 6
                    let statusText = result.isAbnormal ? "⚠ Abnormal" : "Normal"
                    let values = [result.parameterName, result.value, result.unit, result.normalRange, statusText]
                    for (i, val) in values.enumerated() {
                        let attr = (i == 4 && result.isAbnormal) ? abnormalAttr : cellAttr
                        let cellRect = CGRect(x: colX, y: y + 4, width: colWidths[i] - 8, height: 14)
                        NSAttributedString(string: val, attributes: attr).draw(in: cellRect)
                        colX += colWidths[i]
                    }
                    y += 22
                }
                
                drawDivider(at: y, margin: margin, width: contentWidth)
                y += 16
            }
            
            // ── Notes ──
            if !test.notes.isEmpty {
                y = drawSectionHeader("NOTES", at: y, margin: margin, width: contentWidth)
                y += 8
                let notesAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                    .foregroundColor: darkText
                ]
                NSAttributedString(string: test.notes, attributes: notesAttr)
                    .draw(in: CGRect(x: margin + 4, y: y, width: contentWidth - 8, height: 60))
                y += 40
            }
            
            // ── Footer ──
            let footerY = pageHeight - 60
            drawDivider(at: footerY, margin: margin, width: contentWidth)
            
            let footerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 7, weight: .regular),
                .foregroundColor: secondaryText
            ]
            let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short)
            NSAttributedString(string: "Generated on \(dateStr)  •  \(hospitalName)", attributes: footerAttr)
                .draw(at: CGPoint(x: margin, y: footerY + 8))
            
            let disclaimerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 7),
                .foregroundColor: secondaryText
            ]
            NSAttributedString(string: "This is a computer-generated laboratory report. For official results, please contact the hospital laboratory.", attributes: disclaimerAttr)
                .draw(at: CGPoint(x: margin, y: footerY + 22))
            
            let watermarkAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 7, weight: .medium),
                .foregroundColor: brandBlue.withAlphaComponent(0.4)
            ]
            let confStr = NSAttributedString(string: "CONFIDENTIAL", attributes: watermarkAttr)
            let confSize = confStr.size()
            confStr.draw(at: CGPoint(x: pageWidth - margin - confSize.width, y: footerY + 8))
        }
        
        return data
    }
}
