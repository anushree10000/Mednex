//
//  StaffManagementView.swift
//  MedNex
//
//  Staff — departmental hierarchy IS the design. No summary badges.
//  All data pulled from the unified `staff` table.

import SwiftUI

struct StaffManagementView: View {
    @State private var searchText = ""
    @State private var selectedDepartmentFilter: String = DepartmentFilter.all
    @State private var selectedRoleFilter: StaffRoleFilter = .all
    @State private var showingAddStaff = false
    @Environment(DataStore.self) private var dataStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - Filtered Data (ALL from staff table)
    
    private var filteredDoctors: [Staff] {
        dataStore.staff.filter { $0.role == .doctor }.filter { doctor in
            matchesDepartmentFilter(departmentId: doctor.departmentId, departmentName: doctor.departmentName)
            && matchesSearch(doctor.name)
        }
    }
    
    private var doctorsByDepartment: [(department: String, doctors: [Staff])] {
        let deptLookup = Dictionary(uniqueKeysWithValues: dataStore.departments.map { ($0.id, $0.name) })
        let grouped = Dictionary(grouping: filteredDoctors) { doc -> String in
            if let deptId = doc.departmentId, let name = deptLookup[deptId] { return name }
            if let deptName = doc.departmentName, !deptName.isEmpty { return deptName }
            return "Unassigned"
        }
        return grouped.map { (department: $0.key, doctors: $0.value) }.sorted { $0.department < $1.department }
    }
    
    private var filteredNurses: [Staff] {
        let nurses = dataStore.staff.filter { $0.role == .nurse }
        return nurses.filter { nurse in
            matchesDepartmentFilter(departmentId: nurse.departmentId, departmentName: nurse.departmentName)
            && matchesSearch(nurse.name)
        }
    }
    
    private var filteredLabTechs: [Staff] {
        let techs = dataStore.staff.filter { $0.role == .labTechnician }
        return techs.filter { tech in
            matchesDepartmentFilter(departmentId: tech.departmentId, departmentName: tech.departmentName)
            && matchesSearch(tech.name)
        }
    }

    private var departmentFilters: [String] {
        let names = dataStore.departments.map(\.name)
        return [DepartmentFilter.all] + names.sorted() + [DepartmentFilter.unassigned]
    }

    private func matchesSearch(_ name: String) -> Bool {
        searchText.isEmpty || name.localizedCaseInsensitiveContains(searchText)
    }

    private func departmentName(for departmentId: String?) -> String? {
        guard let departmentId else { return nil }
        return dataStore.departments.first(where: { $0.id == departmentId })?.name
    }

    private func matchesDepartmentFilter(departmentId: String?, departmentName: String?) -> Bool {
        if selectedDepartmentFilter == DepartmentFilter.all {
            return true
        }

        if selectedDepartmentFilter == DepartmentFilter.unassigned {
            return (departmentId == nil || departmentId?.isEmpty == true)
                && (departmentName == nil || departmentName?.isEmpty == true)
        }

        let resolvedName = (departmentName?.isEmpty == false) ? departmentName : self.departmentName(for: departmentId)
        return resolvedName == selectedDepartmentFilter
    }

    private var isPadLayout: Bool { horizontalSizeClass == .regular }
    private var centeredContentWidth: CGFloat { isPadLayout ? 980 : .infinity }
    
    var body: some View {
        List {
            // Role-based filter
            Section {
                Picker("Role", selection: $selectedRoleFilter) {
                    Text("All").tag(StaffRoleFilter.all)
                    Text("Doctors").tag(StaffRoleFilter.doctors)
                    Text("Nurses").tag(StaffRoleFilter.nurses)
                    Text("Lab Techs").tag(StaffRoleFilter.labTechnicians)
                }
                .pickerStyle(.segmented)
            }
            
            // Doctors grouped by department — from staff table
            if selectedRoleFilter == .all || selectedRoleFilter == .doctors {
                ForEach(doctorsByDepartment, id: \.department) { group in
                    Section(group.department) {
                        ForEach(group.doctors) { doctor in
                            NavigationLink(value: doctor) {
                                doctorRow(doctor)
                            }
                        }
                    }
                }
            }
            
            // Nurses
            if (selectedRoleFilter == .all || selectedRoleFilter == .nurses) && !filteredNurses.isEmpty {
                Section("Nurses · \(filteredNurses.count)") {
                    ForEach(filteredNurses) { nurse in
                        NavigationLink(value: nurse) {
                            staffRow(nurse)
                        }
                    }
                }
            }
            
            // Lab Technicians
            if (selectedRoleFilter == .all || selectedRoleFilter == .labTechnicians) && !filteredLabTechs.isEmpty {
                Section("Lab Technicians · \(filteredLabTechs.count)") {
                    ForEach(filteredLabTechs) { tech in
                        NavigationLink(value: tech) {
                            staffRow(tech)
                        }
                    }
                }
            }
            
            if doctorsByDepartment.isEmpty && filteredNurses.isEmpty && filteredLabTechs.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .frame(maxWidth: centeredContentWidth)
        .frame(maxWidth: .infinity, alignment: .center)
        .navigationTitle("Staff")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by name")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddStaff = true }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Staff")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Department", selection: $selectedDepartmentFilter) {
                        ForEach(departmentFilters, id: \.self) { filter in
                            Text(filter).tag(filter)
                        }
                    }
                } label: {
                    Image(systemName: selectedDepartmentFilter == DepartmentFilter.all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                }
                .accessibilityLabel("Filter by department")
            }
        }
        .navigationDestination(for: Staff.self) { StaffDetailView(member: $0) }
        .sheet(isPresented: $showingAddStaff) { AdminAddStaffView() }
        .refreshable { await dataStore.refreshFromBackend() }
    }
    
    // Doctor row — uses Staff model, shows specialization + shift
    private func doctorRow(_ doctor: Staff) -> some View {
        HStack(spacing: MedNexTheme.Spacing.sm) {
            AvatarView(name: doctor.name, imageURL: doctor.profileImageURL, size: 40, backgroundColor: MedNexTheme.Colors.doctorTint)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(doctor.name)
                    .font(.body.weight(.medium))
                HStack(spacing: 4) {
                    Text(doctor.specialization ?? "General Medicine")
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    // Only show department if it differs from specialization
                    if let dept = doctor.departmentName ?? departmentName(for: doctor.departmentId),
                       dept != (doctor.specialization ?? "General Medicine") {
                        Text("·")
                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                        Text(dept)
                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                    }
                }
                .font(.caption)
            }
            
            Spacer()
            
            Text(doctor.shift.rawValue)
                .font(.caption2.weight(.medium))
                .foregroundStyle(shiftColor(doctor.shift))
        }
        .padding(.vertical, 2)
    }
    
    // Staff row — for nurses and lab techs
    private func staffRow(_ member: Staff) -> some View {
        HStack(spacing: MedNexTheme.Spacing.sm) {
            AvatarView(
                name: member.name,
                imageURL: member.profileImageURL,
                size: 40,
                backgroundColor: member.role == .nurse ? MedNexTheme.Colors.nurseTint : MedNexTheme.Colors.labTechTint
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.body.weight(.medium))
                Text(member.departmentName ?? "Unassigned")
                    .font(.caption)
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
            }
            
            Spacer()
            
            Text(member.shift.rawValue)
                .font(.caption2.weight(.medium))
                .foregroundStyle(shiftColor(member.shift))
        }
        .padding(.vertical, 2)
    }
    
    private func shiftColor(_ shift: ShiftType) -> Color {
        switch shift {
        case .morning: return MedNexTheme.Colors.warning
        case .evening: return MedNexTheme.Colors.info
        case .night: return MedNexTheme.Colors.nightShiftTint
        }
    }
}

private enum DepartmentFilter {
    static let all = "All Departments"
    static let unassigned = "Unassigned"
}

enum StaffRoleFilter: String, CaseIterable {
    case all, doctors, nurses, labTechnicians
}
