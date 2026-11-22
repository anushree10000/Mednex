//
//  RoleRouter.swift
//  MedNex
//

import SwiftUI

struct RoleRouter: View {
    let role: UserRole
    let appState: AppState
    
    var body: some View {
        switch role {
        case .patient:
            PatientTabView(appState: appState)
        case .doctor:
            DoctorTabView(appState: appState)
        case .admin:
            AdminTabView(appState: appState)
        case .nurse:
            NurseTabView(appState: appState)
        case .labTechnician:
            LabTechTabView(appState: appState)
        case .pharmacist:
            PharmacistTabView(appState: appState)
        case .receptionist:
            // Receptionist shares the admin-like interface for now
            AdminTabView(appState: appState)
        case .accountant:
            AdminTabView(appState: appState)
        }
    }
}
