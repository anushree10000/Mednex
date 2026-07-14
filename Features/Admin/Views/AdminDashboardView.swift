//
//  AdminDashboardView.swift
//  MedNex
//
//  Dashboard — the command center. Chart is the hero.
//  Metrics are inline and scannable, not boxed into uniform cards.

import SwiftUI
import Charts

struct AdminDashboardView: View {
    let appState: AppState
    @Binding var showProfile: Bool
    @Environment(DataStore.self) private var dataStore
    @State private var selectedRange: DashboardRange = .last30Days
    @State private var selectedDate: Date?
    @State private var activeDetailSheet: AdminDashboardSheet?
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                overviewCards
                    .padding(.horizontal)
                    .padding(.top, MedNexTheme.Spacing.sm)
                
                revenueChart
                    .padding(.horizontal)

                operationalCards
                    .padding(.horizontal)

                insightCards
                    .padding(.horizontal)
                    .padding(.bottom, MedNexTheme.Spacing.xl)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await dataStore.refreshFromBackend()
        }
        .task {
            if dataStore.admissions.isEmpty || dataStore.appointments.isEmpty || dataStore.labTests.isEmpty {
                await dataStore.refreshFromBackend()
            }
        }
        .overlay {
            if dataStore.isLoadingFromBackend {
                ProgressView("Loading…")
                    .padding(MedNexTheme.Spacing.xl)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md))
            }
        }
        .sheet(item: $activeDetailSheet) { detail in
            AdminDashboardSheetView(sheet: detail, dataStore: dataStore)
        }
    }
    
    private var overviewCards: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: MedNexTheme.Spacing.sm)], spacing: MedNexTheme.Spacing.sm) {
            dashboardStatCard(
                title: "Patients",
                value: "\(dataStore.allPatients.count)",
                subtitle: "\(admittedCount) admitted · \(dischargedLast30Days) discharged (30D)",
                icon: "person.2.fill",
                tint: MedNexTheme.Colors.info
            ) {
                activeDetailSheet = .patients
            }

            dashboardStatCard(
                title: "Today's Appointments",
                value: "\(todayAppointmentsCount)",
                subtitle: "\(scheduledTodayCount) scheduled · \(completedTodayCount) completed",
                icon: "calendar",
                tint: MedNexTheme.Colors.primary
            ) {
                activeDetailSheet = .todayAppointments
            }

            dashboardStatCard(
                title: "Collections",
                value: "₹\(compactCurrency(totalRevenue))",
                subtitle: "Unpaid ₹\(compactCurrency(outstandingRevenue))",
                icon: "indianrupeesign.circle.fill",
                tint: MedNexTheme.Colors.success
            ) {
                activeDetailSheet = .collections
            }

            dashboardStatCard(
                title: "Lab Pipeline",
                value: "\(activeLabCount)",
                subtitle: "\(processingLabCount) processing · \(completedTodayLabCount) completed today",
                icon: "cross.vial.fill",
                tint: MedNexTheme.Colors.warning
            ) {
                activeDetailSheet = .labPipeline
            }
        }
    }
    
    private func dashboardStatCard(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
                HStack {
                    Label(title, systemImage: icon)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    Spacer(minLength: 0)
                }

                Text(value)
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                    .lineLimit(2)
            }
            .padding(MedNexTheme.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg))
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 34, height: 34)
                    .overlay {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(tint)
                    }
                    .padding(10)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var revenueChart: some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
            HStack {
                Text("Revenue")
                    .font(.headline)
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                Spacer()
                Picker("Range", selection: $selectedRange) {
                    ForEach(DashboardRange.allCases) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 250)
                .padding(.vertical, 1)
            }

            if let highlightedRevenuePoint {
                HStack {
                    Text(highlightedRevenuePoint.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    Spacer()
                    Text("₹\(Int(highlightedRevenuePoint.amount))")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(MedNexTheme.Colors.primary)
                }
            } else {
                HStack {
                    Text(selectedRange.title)
                        .font(.subheadline)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    Spacer()
                    Text("₹\(Int(rangeTotalRevenue))")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(MedNexTheme.Colors.primary)
                }
            }

            Chart(revenuePoints) { item in
                AreaMark(
                    x: .value("Date", item.date),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(LinearGradient(
                    colors: [MedNexTheme.Colors.primary.opacity(0.25), MedNexTheme.Colors.primary.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .interpolationMethod(.catmullRom)
                
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(MedNexTheme.Colors.primary)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .interpolationMethod(.catmullRom)

                if let highlightedRevenuePoint {
                    RuleMark(x: .value("Selected", highlightedRevenuePoint.date))
                        .foregroundStyle(MedNexTheme.Colors.textTertiary.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))

                    PointMark(
                        x: .value("Date", highlightedRevenuePoint.date),
                        y: .value("Amount", highlightedRevenuePoint.amount)
                    )
                    .foregroundStyle(MedNexTheme.Colors.primary)
                    .symbolSize(70)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    if let amount = value.as(Double.self) {
                        AxisValueLabel {
                            Text(yAxisLabel(for: amount))
                                .font(.caption2)
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(MedNexTheme.Colors.separator)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(xAxisLabel(for: date))
                                .font(.caption2)
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                        }
                    }
                }
            }
            .chartXSelection(value: $selectedDate)
            .frame(height: 220)
        }
        .padding(MedNexTheme.Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg))
    }

    private var operationalCards: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: MedNexTheme.Spacing.sm)], spacing: MedNexTheme.Spacing.sm) {
            compactInfoCard(
                title: "Staffing",
                rows: [
                    ("Doctors", "\(doctorCount)"),
                    ("Nurses", "\(nurseCount)"),
                    ("Lab technicians", "\(labTechCount)")
                ],
                action: {
                    activeDetailSheet = .staffing
                }
            )

            compactInfoCard(
                title: "Appointment Health",
                rows: [
                    ("Upcoming appointments", "\(dataStore.upcomingAppointments.count)"),
                    ("Cancelled today", "\(cancelledTodayCount)"),
                    ("Completed today", "\(completedTodayCount)")
                ],
                action: {
                    activeDetailSheet = .appointmentHealth
                }
            )

            compactInfoCard(
                title: "Doctor Performance",
                rows: [
                    ("Active doctors", "\(doctorCount)"),
                    ("Avg completion", "\(avgDoctorCompletionLabel)"),
                    ("Prescriptions (30D)", "\(recentPrescriptionCount)")
                ],
                action: {
                    activeDetailSheet = .doctorPerformance
                }
            )
        }
    }

    private var avgDoctorCompletionLabel: String {
        let threshold = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
        var rates: [Double] = []
        for doctor in dataStore.doctors {
            let doctorId = doctor.userId.isEmpty ? doctor.id : doctor.userId
            let appts = dataStore.appointments.filter { $0.doctorId == doctorId && $0.dateTime >= threshold }
            guard !appts.isEmpty else { continue }
            let completed = appts.filter { $0.status == .completed }.count
            rates.append(Double(completed) / Double(appts.count) * 100)
        }
        guard !rates.isEmpty else { return "—" }
        return "\(Int(rates.reduce(0, +) / Double(rates.count)))%"
    }

    private var recentPrescriptionCount: Int {
        let threshold = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
        return dataStore.prescriptions.filter { $0.createdAt >= threshold }.count
    }

    private var insightCards: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: MedNexTheme.Spacing.sm)], spacing: MedNexTheme.Spacing.sm) {
            revenueBreakdown
        }
    }
    
    private var revenueBreakdown: some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
            Text("Revenue by Category")
                .font(.headline)
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
            
            VStack(spacing: 0) {
                revenueRow(label: "Lab Tests", amount: labTestRevenue)
                revenueRow(label: "Consultations", amount: consultationRevenue)
                revenueRow(label: "Pharmacy", amount: pharmacyRevenue)
                revenueRow(label: "Room Charges", amount: roomChargeRevenue)
                revenueRow(label: "Procedures", amount: procedureRevenue)
            }
        }
        .padding(MedNexTheme.Spacing.md)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg))
    }
    
    private func revenueRow(label: String, amount: Double) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
            Spacer()
            Text("₹\(Int(amount))")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
        }
        .padding(.vertical, 6)
    }

    private func compactInfoCard(title: String, rows: [(String, String)], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                }

                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack {
                        Text(row.0)
                            .font(.subheadline)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        Spacer()
                        Text(row.1)
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(MedNexTheme.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 144, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg))
        }
        .buttonStyle(.plain)
    }
    
    private var formattedRevenue: String {
        let rev = totalRevenue
        if rev >= 100_000 { return "\(String(format: "%.1f", rev / 100_000))L" }
        else if rev >= 1_000 { return "\(String(format: "%.1f", rev / 1_000))K" }
        return "\(Int(rev))"
    }
    
    private var rangeTotalRevenue: Double {
        billsInSelectedRange.reduce(0) { $0 + $1.totalAmount }
    }

    private var doctorCount: Int { dataStore.doctors.count }
    private var nurseCount: Int { dataStore.staff.filter { $0.role == .nurse }.count }
    private var labTechCount: Int { dataStore.staff.filter { $0.role == .labTechnician }.count }
    private var totalStaffCount: Int { doctorCount + nurseCount + labTechCount }
    private var admittedCount: Int { dataStore.admissions.filter { $0.status == .admitted }.count }
    private var dischargedCount: Int { dataStore.admissions.filter { $0.status == .discharged }.count }
    
    // #18: Enriched subtitle with average stay duration
    private var admissionSubtitle: String {
        let admitted = admittedCount
        let discharged = dischargedCount
        let base = "\(admitted) admitted · \(discharged) discharged"
        
        // Calculate avg stay for current admissions
        let activeAdmissions = dataStore.admissions.filter { $0.status == .admitted }
        guard !activeAdmissions.isEmpty else { return base }
        let totalDays = activeAdmissions.reduce(0.0) { sum, a in
            sum + max(1, Date().timeIntervalSince(a.admissionDate) / 86400)
        }
        let avgDays = Int(totalDays / Double(activeAdmissions.count))
        return "\(admitted) admitted (avg \(avgDays)d) · \(discharged) discharged"
    }
    private var totalRevenue: Double { dataStore.totalRevenue }
    private var outstandingRevenue: Double {
        dataStore.bills
            .filter { $0.status != .paid && $0.status != .waived }
            .reduce(0) { $0 + max(0, $1.balanceDue) }
    }
    private var pendingBillsCount: Int {
        dataStore.bills.filter { $0.status == .unpaid || $0.status == .partial }.count
    }
    private var pendingLabCount: Int { dataStore.labTests.filter { $0.status == .pending }.count }
    private var receivedLabCount: Int { dataStore.labTests.filter { $0.status == .received }.count }
    private var processingLabCount: Int { dataStore.labTests.filter { $0.status == .processing }.count }
    private var activeLabCount: Int { pendingLabCount + receivedLabCount + processingLabCount }
    private var completedTodayLabCount: Int {
        dataStore.labTests.filter { $0.status == .completed && ($0.completedAt.map { Calendar.current.isDateInToday($0) } ?? false) }.count
    }
    private var todayAppointmentsCount: Int {
        dataStore.todayAppointments.filter { $0.status != .cancelled && $0.status != .noShow }.count
    }
    private var scheduledTodayCount: Int { dataStore.todayAppointments.filter { $0.status == .scheduled }.count }
    private var cancelledTodayCount: Int { dataStore.todayAppointments.filter { $0.status == .cancelled }.count }
    private var completedTodayCount: Int { dataStore.todayAppointments.filter { $0.status == .completed }.count }
    private var dischargedLast30Days: Int {
        let threshold = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
        return dataStore.admissions.filter { admission in
            guard let dischargeDate = admission.dischargeDate else { return false }
            return dischargeDate >= threshold
        }.count
    }
    
    private var labTestRevenue: Double {
        let paidItems = billsInSelectedRange.filter { $0.status == .paid }.flatMap { $0.items }
        return paidItems.filter { item in
            if let cat = item.category { return cat == .labTest }
            let desc = item.description.lowercased()
            return desc.contains("lab") || desc.contains("test") || desc.contains("blood")
                || desc.contains("urine") || desc.contains("x-ray") || desc.contains("scan")
                || desc.contains("mri") || desc.contains("ct") || desc.contains("pathology")
        }.reduce(0) { $0 + $1.total }
    }
    
    private var consultationRevenue: Double {
        let paidItems = billsInSelectedRange.filter { $0.status == .paid }.flatMap { $0.items }
        return paidItems.filter { item in
            if let cat = item.category { return cat == .consultation }
            let desc = item.description.lowercased()
            return desc.contains("consult") || desc.contains("doctor") || desc.contains("visit")
                || desc.contains("checkup") || desc.contains("examination") || desc.contains("opd")
        }.reduce(0) { $0 + $1.total }
    }
    
    private var pharmacyRevenue: Double { categoryRevenue(for: .pharmacy) }
    private var roomChargeRevenue: Double { categoryRevenue(for: .roomCharge) }
    private var procedureRevenue: Double { categoryRevenue(for: .procedure) }
    
    private func categoryRevenue(for category: BillItemCategory) -> Double {
        billsInSelectedRange.filter { $0.status == .paid }.flatMap { $0.items }
            .filter { $0.category == category }
            .reduce(0) { $0 + $1.total }
    }
    
    private var rangeStartDate: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        switch selectedRange {
        case .last7Days:
            return calendar.date(byAdding: .day, value: -6, to: today) ?? today
        case .last30Days:
            return calendar.date(byAdding: .day, value: -29, to: today) ?? today
        case .last90Days:
            return calendar.date(byAdding: .day, value: -89, to: today) ?? today
        case .last365Days:
            return calendar.date(byAdding: .day, value: -364, to: today) ?? today
        }
    }

    private var billsInSelectedRange: [Bill] {
        dataStore.bills.filter { $0.createdAt >= rangeStartDate }
    }

    private var revenuePoints: [RevenuePoint] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        var points: [RevenuePoint] = []

        if selectedRange == .last365Days {
            let monthlyBills = billsInSelectedRange

            var cursor = calendar.date(from: calendar.dateComponents([.year, .month], from: rangeStartDate)) ?? rangeStartDate
            while cursor <= endDate {
                let next = calendar.date(byAdding: .month, value: 1, to: cursor) ?? endDate
                let amount = monthlyBills
                    .filter { $0.createdAt >= cursor && $0.createdAt < next }
                    .reduce(0) { $0 + $1.totalAmount }
                points.append(RevenuePoint(date: cursor, amount: amount))
                cursor = next
            }
            return points
        }

        if selectedRange == .last90Days {
            let weekBills = billsInSelectedRange
            var cursor = rangeStartDate
            while cursor <= endDate {
                let next = calendar.date(byAdding: .day, value: 7, to: cursor) ?? endDate
                let amount = weekBills
                    .filter { $0.createdAt >= cursor && $0.createdAt < next }
                    .reduce(0) { $0 + $1.totalAmount }
                points.append(RevenuePoint(date: cursor, amount: amount))
                cursor = next
            }
            return points
        }

        let dayCount = selectedRange.days
        let rangeBills = billsInSelectedRange
        for offset in 0..<dayCount {
            let date = calendar.date(byAdding: .day, value: offset, to: rangeStartDate) ?? endDate
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let dayTotal = rangeBills
                .filter { $0.createdAt >= dayStart && $0.createdAt < dayEnd }
                .reduce(0) { $0 + $1.totalAmount }
            points.append(RevenuePoint(date: dayStart, amount: dayTotal))
        }
        return points
    }

    private var highlightedRevenuePoint: RevenuePoint? {
        guard let selectedDate, !revenuePoints.isEmpty else { return nil }
        return revenuePoints.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
    }

    private func xAxisLabel(for date: Date) -> String {
        if selectedRange == .last365Days {
            return date.formatted(.dateTime.month(.abbreviated))
        }
        if selectedRange == .last7Days {
            return date.formatted(.dateTime.weekday(.abbreviated))
        }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }

    private func yAxisLabel(for amount: Double) -> String {
        if amount >= 100_000 { return "₹\(Int(amount / 100_000))L" }
        if amount >= 1_000 { return "₹\(Int(amount / 1_000))K" }
        return "₹\(Int(amount))"
    }

    private func compactCurrency(_ amount: Double) -> String {
        if amount >= 100_000 { return String(format: "%.1fL", amount / 100_000) }
        if amount >= 1_000 { return String(format: "%.1fK", amount / 1_000) }
        return "\(Int(amount))"
    }
}

private struct RevenuePoint: Identifiable {
    var id: Date { date }
    let date: Date
    let amount: Double
}

private enum DashboardRange: String, CaseIterable, Identifiable {
    case last7Days
    case last30Days
    case last90Days
    case last365Days

    var id: String { rawValue }

    var label: String {
        switch self {
        case .last7Days: return "7D"
        case .last30Days: return "30D"
        case .last90Days: return "90D"
        case .last365Days: return "1Y"
        }
    }

    var title: String {
        switch self {
        case .last7Days: return "Last 7 Days"
        case .last30Days: return "Last 30 Days"
        case .last90Days: return "Last 90 Days"
        case .last365Days: return "Last 1 Year"
        }
    }

    var days: Int {
        switch self {
        case .last7Days: return 7
        case .last30Days: return 30
        case .last90Days: return 90
        case .last365Days: return 365
        }
    }
}

private enum AdminDashboardSheet: String, Identifiable {
    case patients
    case todayAppointments
    case collections
    case labPipeline
    case staffing
    case appointmentHealth
    case doctorPerformance

    var id: String { rawValue }
}

private enum TimeFilter: String, CaseIterable, Identifiable {
    case last7Days
    case last30Days
    case last90Days
    case allTime

    var id: String { rawValue }
    var label: String {
        switch self {
        case .last7Days: return "7D"
        case .last30Days: return "30D"
        case .last90Days: return "90D"
        case .allTime: return "All"
        }
    }
}

private struct AdminDashboardSheetView: View {
    let sheet: AdminDashboardSheet
    let dataStore: DataStore

    var body: some View {
        switch sheet {
        case .patients:
            PatientAdmissionsDetailView(dataStore: dataStore)
        case .todayAppointments:
            TodayAppointmentsDetailView(dataStore: dataStore)
        case .collections:
            CollectionsDetailView(dataStore: dataStore)
        case .labPipeline:
            LabPipelineDetailView(dataStore: dataStore)
        case .staffing:
            StaffingDetailView(dataStore: dataStore)
        case .appointmentHealth:
            AppointmentHealthDetailView(dataStore: dataStore)
        case .doctorPerformance:
            AdminDoctorPerformanceView(dataStore: dataStore)
        }
    }
}

private struct PatientAdmissionsDetailView: View {
    let dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var filter: TimeFilter = .last30Days

    private var filteredAdmissions: [Admission] {
        let admissions = dataStore.admissions.sorted { $0.admissionDate > $1.admissionDate }
        guard filter != .allTime else { return admissions }
        let threshold: Date
        switch filter {
        case .last7Days: threshold = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        case .last30Days: threshold = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
        case .last90Days: threshold = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? .distantPast
        case .allTime: threshold = .distantPast
        }
        return admissions.filter { admission in
            admission.admissionDate >= threshold || (admission.dischargeDate.map { $0 >= threshold } ?? false)
        }
    }

    private var dischargeCountInFilter: Int {
        filteredAdmissions.filter { $0.status == .discharged }.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Range", selection: $filter) {
                        ForEach(TimeFilter.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 1)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }

                Section {
                    statRow("Admissions", "\(filteredAdmissions.count)")
                    statRow("Discharged", "\(dischargeCountInFilter)")
                    statRow("Active admissions", "\(dataStore.admissions.filter { $0.status == .admitted }.count)")
                }

                Section("Patient Admissions") {
                    ForEach(filteredPatientIds, id: \.self) { patientId in
                        NavigationLink {
                            PatientClinicalDetailView(patientId: patientId, dataStore: dataStore)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(patientName(for: patientId))
                                    .font(.body.weight(.medium))
                                Text(patientDetailSubtitle(for: patientId))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Patients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label); Spacer(); Text(value).monospacedDigit() }
    }

    private var filteredPatientIds: [String] {
        let ids = filteredAdmissions.map(\.patientId)
        return Array(Set(ids)).sorted { patientName(for: $0) < patientName(for: $1) }
    }

    private func patientName(for patientId: String) -> String {
        if let patient = dataStore.allPatients.first(where: { $0.id == patientId }) {
            let fullName = patient.personalInfo.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !fullName.isEmpty { return fullName }
        }
        if let admissionName = dataStore.admissions.first(where: { $0.patientId == patientId })?.patientName, !admissionName.isEmpty {
            return admissionName
        }
        return "Patient \(patientId.prefix(6))"
    }

    private func patientDetailSubtitle(for patientId: String) -> String {
        let admissions = dataStore.admissions.filter { $0.patientId == patientId }
        let latestAdmission = admissions.max(by: { $0.admissionDate < $1.admissionDate })
        let appointments = dataStore.normalizedAppointmentsForDisplay.filter { $0.patientId == patientId }
        let labs = dataStore.labTests.filter { $0.patientId == patientId }
        if let latestAdmission {
            return "Admissions \(admissions.count) · Appointments \(appointments.count) · Labs \(labs.count) · Last \(latestAdmission.admissionDate.formatted(date: .abbreviated, time: .omitted))"
        }
        return "Appointments \(appointments.count) · Labs \(labs.count)"
    }
}

private struct PatientClinicalDetailView: View {
    let patientId: String
    let dataStore: DataStore

    private var patientName: String {
        if let patient = dataStore.allPatients.first(where: { $0.id == patientId }) {
            let fullName = patient.personalInfo.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !fullName.isEmpty { return fullName }
        }
        return dataStore.admissions.first(where: { $0.patientId == patientId })?.patientName ?? "Patient \(patientId.prefix(6))"
    }

    private var admissions: [Admission] { dataStore.admissions.filter { $0.patientId == patientId }.sorted { $0.admissionDate > $1.admissionDate } }
    private var appointments: [Appointment] { dataStore.normalizedAppointmentsForDisplay.filter { $0.patientId == patientId }.sorted { $0.dateTime > $1.dateTime } }
    private var labTests: [LabTest] { dataStore.labTests.filter { $0.patientId == patientId }.sorted { $0.orderedAt > $1.orderedAt } }

    var body: some View {
        List {
            Section("Patient") {
                detailRow("Name", patientName)
                detailRow("Patient ID", patientId.prefix(8).description)
                detailRow("Total admissions", "\(admissions.count)")
                detailRow("Total appointments", "\(appointments.count)")
                detailRow("Total lab tests", "\(labTests.count)")
            }

            Section("Admissions Timeline") {
                if admissions.isEmpty {
                    Text("No admissions found.").foregroundStyle(.secondary)
                } else {
                    ForEach(admissions) { admission in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Admitted \(admission.admissionDate.formatted(date: .abbreviated, time: .shortened))")
                                .font(.subheadline.weight(.medium))
                            Text("Discharged \(admission.dischargeDate?.formatted(date: .abbreviated, time: .shortened) ?? "—")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Status: \(admission.status.displayName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Appointments") {
                if appointments.isEmpty {
                    Text("No appointments found.").foregroundStyle(.secondary)
                } else {
                    ForEach(appointments) { appointment in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(appointment.dateTime.formatted(date: .abbreviated, time: .shortened)) · Dr. \(appointment.doctorName)")
                                .font(.subheadline.weight(.medium))
                            Text("Type: \(appointment.type.displayName) · Status: \(appointment.status.displayName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Lab Tests") {
                if labTests.isEmpty {
                    Text("No lab tests found.").foregroundStyle(.secondary)
                } else {
                    ForEach(labTests) { test in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(test.testName)
                                .font(.subheadline.weight(.medium))
                            Text("Ordered \(test.orderedAt.formatted(date: .abbreviated, time: .shortened)) · Status: \(test.status.displayName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(patientName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) { Text(label).foregroundStyle(.secondary); Spacer(); Text(value).multilineTextAlignment(.trailing) }
    }
}

private struct AdmissionRecordDetailView: View {
    let admission: Admission
    let dataStore: DataStore

    private var doctorNames: String {
        let names = admission.doctorIds.compactMap { id in dataStore.doctors.first(where: { $0.id == id })?.name }
        return names.isEmpty ? "Not assigned" : names.joined(separator: ", ")
    }
    private var nurseName: String {
        guard let nurseId = admission.nurseId else { return "Not assigned" }
        return dataStore.staff.first(where: { $0.id == nurseId })?.name ?? "Not assigned"
    }

    var body: some View {
        List {
            Section("Admission Details") {
                detailRow("Patient", admission.patientName ?? "Patient \(admission.patientId.prefix(6))")
                detailRow("Status", admission.status.displayName)
                detailRow("Admitted on", admission.admissionDate.formatted(date: .abbreviated, time: .shortened))
                detailRow("Discharged on", admission.dischargeDate?.formatted(date: .abbreviated, time: .shortened) ?? "—")
                detailRow("Ward/Bed", [admission.wardNumber, admission.bedNumber].compactMap { $0 }.joined(separator: " · ").isEmpty ? "—" : [admission.wardNumber, admission.bedNumber].compactMap { $0 }.joined(separator: " · "))
            }
            Section("Assigned Team") {
                detailRow("Doctors", doctorNames)
                detailRow("Nurse", nurseName)
            }
            if let diagnosis = admission.diagnosis, !diagnosis.isEmpty {
                Section("Diagnosis") { Text(diagnosis) }
            }
        }
        .navigationTitle("Admission")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) { Text(label).foregroundStyle(.secondary); Spacer(); Text(value).multilineTextAlignment(.trailing) }
    }
}

private struct TodayAppointmentsDetailView: View {
    let dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    private var todayAppointments: [Appointment] {
        dataStore.todayAppointments.sorted { $0.dateTime < $1.dateTime }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    statRow("Total today", "\(todayAppointments.count)")
                    statRow("Scheduled", "\(todayAppointments.filter { $0.status == .scheduled }.count)")
                    statRow("Completed", "\(todayAppointments.filter { $0.status == .completed }.count)")
                    statRow("Cancelled", "\(todayAppointments.filter { $0.status == .cancelled }.count)")
                }

                Section("Today's Appointments") {
                    ForEach(todayAppointments) { appointment in
                        NavigationLink {
                            AppointmentRecordDetailView(appointment: appointment)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(appointment.patientName.isEmpty ? "Patient \(appointment.patientId.prefix(6))" : appointment.patientName)
                                    .font(.body.weight(.medium))
                                Text("\(appointment.dateTime.formatted(date: .omitted, time: .shortened)) · Dr. \(appointment.doctorName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Today's Appointments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label); Spacer(); Text(value).monospacedDigit() }
    }
}

private struct AppointmentHealthDetailView: View {
    let dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var filter: TimeFilter = .last30Days

    private var filteredAppointments: [Appointment] {
        let sorted = dataStore.normalizedAppointmentsForDisplay.sorted { $0.dateTime > $1.dateTime }
        guard filter != .allTime else { return sorted }
        let threshold: Date
        switch filter {
        case .last7Days: threshold = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        case .last30Days: threshold = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
        case .last90Days: threshold = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? .distantPast
        case .allTime: threshold = .distantPast
        }
        return sorted.filter { $0.dateTime >= threshold || $0.createdAt >= threshold }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Range", selection: $filter) {
                        ForEach(TimeFilter.allCases) { option in Text(option.label).tag(option) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 1)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                Section("Appointments") {
                    ForEach(filteredAppointments) { appointment in
                        NavigationLink {
                            AppointmentRecordDetailView(appointment: appointment)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(appointment.patientName.isEmpty ? "Patient \(appointment.patientId.prefix(6))" : appointment.patientName)
                                    .font(.body.weight(.medium))
                                Text("\(appointment.dateTime.formatted(date: .abbreviated, time: .shortened)) · Dr. \(appointment.doctorName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Appointment Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}

private struct AppointmentRecordDetailView: View {
    let appointment: Appointment

    var body: some View {
        List {
            Section("Details") {
                row("Patient", appointment.patientName.isEmpty ? "Patient \(appointment.patientId.prefix(6))" : appointment.patientName)
                row("Doctor", appointment.doctorName)
                row("Date", appointment.dateTime.formatted(date: .abbreviated, time: .shortened))
                row("End", appointment.endTime.formatted(date: .omitted, time: .shortened))
                row("Type", appointment.type.displayName)
                row("Status", appointment.status.displayName)
                row("Billing", appointment.billingStatus.displayName)
            }
            if !appointment.notes.isEmpty {
                Section("Notes") { Text(appointment.notes) }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Appointment")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ l: String, _ v: String) -> some View {
        HStack { Text(l).foregroundStyle(.secondary); Spacer(); Text(v).multilineTextAlignment(.trailing) }
    }
}

private struct CollectionsDetailView: View {
    let dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    private var unpaidBills: [Bill] {
        dataStore.bills.filter { $0.status != .paid && $0.status != .waived }
            .sorted { max(0, $0.balanceDue) > max(0, $1.balanceDue) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack { Text("Collected"); Spacer(); Text("₹\(Int(dataStore.totalRevenue))").monospacedDigit() }
                    HStack { Text("Unpaid amount"); Spacer(); Text("₹\(Int(unpaidBills.reduce(0) { $0 + max(0, $1.balanceDue) }))").monospacedDigit() }
                    HStack { Text("Pending bills"); Spacer(); Text("\(unpaidBills.count)").monospacedDigit() }
                }
                Section("Unpaid Bills") {
                    ForEach(unpaidBills) { bill in
                        NavigationLink {
                            BillRecordDetailView(bill: bill)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(bill.patientName).font(.body.weight(.medium))
                                Text("Raised \(bill.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Collections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}

private struct BillRecordDetailView: View {
    let bill: Bill

    var body: some View {
        List {
            Section("Bill Info") {
                row("Patient", bill.patientName)
                row("Raised on", bill.createdAt.formatted(date: .abbreviated, time: .shortened))
                row("Paid on", bill.paidAt?.formatted(date: .abbreviated, time: .shortened) ?? "Not paid")
                row("Status", bill.status.displayName)
                row("Total", "₹\(Int(bill.totalAmount))")
                row("Paid", "₹\(Int(bill.paidAmount))")
                row("Due", "₹\(Int(max(0, bill.balanceDue)))")
            }
            Section("Bill Items") {
                ForEach(bill.items) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.description).font(.subheadline.weight(.medium))
                        Text("\(item.quantity) × ₹\(Int(item.unitPrice))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Bill Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack { Text(label).foregroundStyle(.secondary); Spacer(); Text(value).multilineTextAlignment(.trailing).monospacedDigit() }
    }
}

private struct LabPipelineDetailView: View {
    let dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var scope: LabScope = .active

    private enum LabScope: String, CaseIterable, Identifiable {
        case active = "Active"
        case all = "All"
        var id: String { rawValue }
    }

    private var tests: [LabTest] {
        let sorted = dataStore.labTests.sorted { $0.orderedAt > $1.orderedAt }
        switch scope {
        case .active: return sorted.filter { $0.status == .pending || $0.status == .received || $0.status == .processing }
        case .all: return sorted
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Scope", selection: $scope) {
                        ForEach(LabScope.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 1)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                Section {
                    HStack { Text("Pending"); Spacer(); Text("\(dataStore.labTests.filter { $0.status == .pending }.count)").monospacedDigit() }
                    HStack { Text("Received"); Spacer(); Text("\(dataStore.labTests.filter { $0.status == .received }.count)").monospacedDigit() }
                    HStack { Text("Processing"); Spacer(); Text("\(dataStore.labTests.filter { $0.status == .processing }.count)").monospacedDigit() }
                    HStack { Text("Completed"); Spacer(); Text("\(dataStore.labTests.filter { $0.status == .completed }.count)").monospacedDigit() }
                }
                Section("Lab Tests") {
                    ForEach(tests) { test in
                        NavigationLink {
                            LabTestRecordDetailView(test: test)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(test.testName).font(.body.weight(.medium))
                                Text("\(test.patientName) · Ordered by Dr. \(test.doctorName)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Lab Pipeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}

private struct LabTestRecordDetailView: View {
    let test: LabTest
    var body: some View {
        List {
            Section("Test Info") {
                row("Patient", test.patientName)
                row("Ordered by", "Dr. \(test.doctorName)")
                row("Status", test.status.displayName)
                row("Priority", test.priority.displayName)
                row("Ordered at", test.orderedAt.formatted(date: .abbreviated, time: .shortened))
                row("Completed at", test.completedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Pending")
            }
            if !test.notes.isEmpty { Section("Notes") { Text(test.notes) } }
            Section("Results") {
                if test.results.isEmpty {
                    Text("No results available yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(test.results) { result in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.parameterName).font(.subheadline.weight(.medium))
                            Text("\(result.value) \(result.unit)").font(.caption)
                            if !result.normalRange.isEmpty { Text("Normal: \(result.normalRange)").font(.caption2).foregroundStyle(.secondary) }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Lab Test")
        .navigationBarTitleDisplayMode(.inline)
    }
    private func row(_ l: String, _ v: String) -> some View { HStack { Text(l).foregroundStyle(.secondary); Spacer(); Text(v).multilineTextAlignment(.trailing) } }
}

private struct StaffingDetailView: View {
    let dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("Doctors") { ForEach(dataStore.doctors) { Text($0.name) } }
                Section("Nurses") { ForEach(dataStore.staff.filter { $0.role == .nurse }) { Text($0.name) } }
                Section("Lab Technicians") { ForEach(dataStore.staff.filter { $0.role == .labTechnician }) { Text($0.name) } }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Staffing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}
