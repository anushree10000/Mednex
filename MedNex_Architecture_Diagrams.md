# MedNex — System Architecture & Workflow Diagrams

---

## 1. System Architecture (Layered)

```mermaid
graph TD
    subgraph EntryPoint["🚀 App Entry"]
        MNA["MedNexApp"]
        CV["ContentView"]
    end

    subgraph CoreLayer["🔐 Core Layer"]
        OB["OnboardingView"]
        LV["LoginView"]
        RV["RegisterView"]
        AVM["AuthViewModel"]
        AS["AuthService"]
        APP["AppState"]
        RR["RoleRouter"]
    end

    subgraph FeatureLayer["📱 Feature Layer — Role-Based Modules"]
        subgraph PatientModule["Patient Module"]
            PTab["PatientTabView"]
            PHome["PatientHomeView"]
            AList["AppointmentListView"]
            ABook["AppointmentBookingView"]
            ADet["AppointmentDetailView"]
            HDash["HealthDashboardView"]
            MRec["MedicalRecordsView"]
            PRx["PrescriptionTrackerView"]
            LRes["LabResultsView"]
            PLab["PatientLabRequestView"]
            PBill["BillingView"]
            PProf["PatientProfileView"]
        end

        subgraph DoctorModule["Doctor Module"]
            DTab["DoctorTabView"]
            DDash["DoctorDashboardView"]
            DSch["DoctorScheduleView"]
            DPat["DoctorPatientsView"]
            DLab["DoctorLabOrderView"]
            DRx["PrescriptionWriterView"]
            DMR["MedicalRecordEditorView"]
            DProf["DoctorProfileView"]
        end

        subgraph AdminModule["Admin Module"]
            ATab["AdminTabView"]
            ADash["AdminDashboardView"]
            AStaff["StaffManagementView"]
            ARep["AdminReportsView"]
            ABill["BillingOverviewView"]
            ADept["DepartmentManagementView"]
            ABed["BedManagementView"]
            AInv["AdminInventoryView"]
            ASet["AdminSettingsView"]
        end

        subgraph NurseModule["Nurse Module"]
            NTab["NurseTabView"]
            NDash["NurseDashboardView"]
            NQueue["NursePatientQueueView"]
            NVit["NurseVitalsEntryView"]
            NBed["NurseBedUpdateView"]
            NTask["NurseTasksView"]
        end

        subgraph LabModule["Lab Tech Module"]
            LTab["LabTechTabView"]
        end

        subgraph PharmModule["Pharmacist Module"]
            PhTab["PharmacistTabView"]
        end

        SProf["StaffProfileView"]
    end

    subgraph SharedLayer["🧱 Shared Layer"]
        subgraph UIComponents["UI Components"]
            GC["GlassCard"]
            SC["StatCard"]
            SB["StatusBadge"]
            AV["AvatarView"]
        end

        subgraph DesignSystem["Design System"]
            Theme["MedNexTheme"]
            Glass["GlassStyles"]
            Haptic["HapticManager"]
        end

        subgraph DataModels["Data Models"]
            MUser["MedNexUser + UserRole"]
            MAppt["Appointment"]
            MRx["Prescription"]
            MLab["LabTest"]
            MBill["Bill"]
            MDept["Department"]
            MVit["VitalRecord"]
        end

        MockDS["MockDataService"]
    end

    subgraph IntelligenceLayer["🧠 Apple Intelligence Layer"]
        subgraph QueryIntents["Query Intents"]
            NAI["NextAppointmentIntent"]
            TSI["TodayScheduleIntent"]
            API["ActivePrescriptionsIntent"]
        end
        subgraph ActionIntents["Actionable Intents"]
            BAI["BookAppointmentIntent"]
            CBAI["CheckBedAvailabilityIntent"]
            RLTI["RequestLabTestIntent"]
            VUI["VitalsUpdateIntent"]
        end
        Short["MedNexShortcuts"]
        WT["Writing Tools"]
    end

    %% Entry flow
    MNA -->|"creates"| CV
    CV -->|"manages"| APP
    CV -->|"!onboarded"| OB
    CV -->|"!authenticated"| LV
    CV -->|"first-time"| RV
    LV -->|"uses"| AVM
    RV -->|"uses"| AVM
    AVM -->|"calls"| AS
    AVM -->|"updates"| APP
    CV -->|"authenticated"| RR

    %% Role routing
    RR -->|"patient"| PTab
    RR -->|"doctor"| DTab
    RR -->|"admin"| ATab
    RR -->|"nurse"| NTab
    RR -->|"labTech"| LTab
    RR -->|"pharmacist"| PhTab

    %% Patient tabs
    PTab --> PHome
    PTab --> AList
    PTab --> HDash
    PTab --> PBill
    PHome -->|"Book"| ABook
    PHome -->|"Lab Test"| PLab
    AList -->|"tap"| ADet

    %% Doctor tabs
    DTab --> DDash
    DTab --> DSch
    DTab --> DPat
    DTab --> DLab
    DTab --> DProf
    DPat --> DRx
    DPat --> DMR

    %% Admin tabs
    ATab --> ADash
    ATab --> AStaff
    ATab --> ARep
    ATab --> ABill
    ATab --> ASet
    ADash --> ADept
    ADash --> ABed
    ADash --> AInv

    %% Nurse tabs
    NTab --> NDash
    NTab --> NQueue
    NTab --> NVit
    NTab --> NBed
    NTab --> NTask

    %% Shared dependencies
    FeatureLayer -->|"uses"| UIComponents
    UIComponents -->|"styled by"| DesignSystem
    FeatureLayer -->|"reads"| MockDS
    MockDS -->|"returns"| DataModels

    %% Intelligence
    Short -->|"registers"| QueryIntents
    Short -->|"registers"| ActionIntents
    QueryIntents -->|"queries"| MockDS
    ActionIntents -->|"queries"| MockDS
    DRx -->|"uses"| WT
    DMR -->|"uses"| WT

    style EntryPoint fill:#0A84FF,stroke:#0A84FF,color:#fff
    style CoreLayer fill:#BF5AF2,stroke:#BF5AF2,color:#fff
    style FeatureLayer fill:#30D158,stroke:#30D158,color:#fff
    style SharedLayer fill:#FF9500,stroke:#FF9500,color:#fff
    style IntelligenceLayer fill:#FF375F,stroke:#FF375F,color:#fff
```

---

## 2. First-Launch & Authentication Flow

```mermaid
flowchart TD
    START(["App Launch"]) --> LOAD["AppState.loadOnboardingState()"]
    LOAD --> CHK{"isRegistered?"}

    CHK -->|"false"| RESET["Reset onboarding flags"]
    RESET --> OB["OnboardingView (3 pages)"]
    OB -->|"Get Started"| COMPLETE["completeOnboarding()"]
    COMPLETE --> LOGIN1["Show LoginView"]
    LOGIN1 -->|"auto-present"| MODAL["RegisterView (.sheet 85%)"]
    MODAL --> FORM["Fill: Name, Email, Password, Role"]
    FORM --> VAL{"Valid?"}
    VAL -->|"No"| FORM
    VAL -->|"Yes"| REG["register()"]
    REG --> FACEID["FaceID Enrollment"]
    FACEID --> CHOICE{"Enable?"}
    CHOICE -->|"Yes"| ENROLL["LAContext biometrics"]
    CHOICE -->|"Skip"| FIN
    ENROLL --> FIN["completeRegistrationFlow()"]
    FIN --> DASH(["Role Dashboard"])

    CHK -->|"true"| LOGIN2["Show LoginView"]
    LOGIN2 --> METHOD{"Method?"}
    METHOD -->|"Credentials"| SIGNIN["login()"]
    SIGNIN --> DASH
    METHOD -->|"Face ID"| BIO["biometrics()"]
    BIO --> DASH

    style START fill:#0A84FF,color:#fff
    style DASH fill:#30D158,color:#fff
```

---

## 3. Role-Based Navigation Map

```mermaid
flowchart TD
    RR["RoleRouter"] --> P{"patient"}
    RR --> D{"doctor"}
    RR --> A{"admin"}
    RR --> N{"nurse"}
    RR --> L{"labTech"}
    RR --> PH{"pharmacist"}

    P --> PT["PatientTabView"]
    PT --> PT1["🏠 Home"]
    PT --> PT2["📅 Appointments"]
    PT --> PT3["❤️ Health"]
    PT --> PT4["💳 Billing"]
    PT1 --> PQA1["→ Book Appointment"]
    PT1 --> PQA2["→ Book Lab Test"]
    PT1 --> PQA3["→ Records"]
    PT1 --> PQA4["→ Medicines"]
    PT2 --> ADET["→ Appointment Detail"]

    D --> DT["DoctorTabView"]
    DT --> DT1["📊 Dashboard"]
    DT --> DT2["📅 Schedule"]
    DT --> DT3["👥 Patients"]
    DT --> DT4["🧪 Lab Orders"]
    DT --> DT5["⋯ Profile"]
    DT3 --> DRX["→ Prescription Writer ✍️"]
    DT3 --> DMR["→ Medical Record Editor ✍️"]

    A --> AT["AdminTabView"]
    AT --> AT1["📊 Dashboard"]
    AT --> AT2["👥 Staff"]
    AT --> AT3["📈 Reports"]
    AT --> AT4["💳 Billing"]
    AT --> AT5["⋯ Settings"]
    AT1 --> ADEPT["→ Departments"]
    AT1 --> ABED["→ Bed Management"]
    AT1 --> AINV["→ Inventory"]

    N --> NT["NurseTabView"]
    NT --> NT1["📋 Dashboard"]
    NT --> NT2["👥 Patients"]
    NT --> NT3["💓 Vitals"]
    NT --> NT4["🛏️ Beds"]
    NT --> NT5["✅ Tasks"]

    L --> LT["LabTechTabView"]
    LT --> LT1["🧪 Queue"]
    LT --> LT2["📄 Results"]

    PH --> PHT["PharmacistTabView"]
    PHT --> PHT1["💊 Orders"]
    PHT --> PHT2["📦 Inventory"]

    style RR fill:#BF5AF2,color:#fff
    style PT fill:#0A84FF,color:#fff
    style DT fill:#30D158,color:#fff
    style AT fill:#FF9500,color:#fff
    style NT fill:#FF375F,color:#fff
    style LT fill:#5E5CE6,color:#fff
    style PHT fill:#FF6482,color:#fff
```

---

## 4. Doctor → Patient → Nurse → Doctor → Patient Flow

```mermaid
flowchart TD
    A(["Patient Books Appointment"]) --> CHECKIN["Patient Checks In at Reception"]
    CHECKIN -->|"Notification sent"| NURSE_ALERT["🔔 Nurse Receives Alert<br/>(Patient Queue badge)"]
    NURSE_ALERT --> NURSE_VITALS["Nurse Records Vitals<br/>(NurseVitalsEntryView)"]
    NURSE_VITALS --> ABNORMAL{"Vitals Normal?"}
    
    ABNORMAL -->|"Yes"| NOTIFY_DOC["Status → Vitals Done<br/>Doctor notified"]
    ABNORMAL -->|"No — Abnormal"| URGENT["⚠️ Urgent Alert to Doctor<br/>+ Abnormal flag"]
    URGENT --> NOTIFY_DOC
    
    NOTIFY_DOC --> DOC_SEES["Doctor Sees Patient"]
    DOC_SEES --> DOC_ACTIONS{"Doctor Actions"}
    DOC_ACTIONS -->|"Prescribe"| RX["PrescriptionWriterView ✍️"]
    DOC_ACTIONS -->|"Record"| MR["MedicalRecordEditorView ✍️"]
    DOC_ACTIONS -->|"Order Lab"| LAB["DoctorLabOrderView ✍️"]
    
    RX --> RX_OUT["→ Patient Rx Tracker<br/>→ Pharmacist Queue"]
    MR --> MR_OUT["→ Patient Records"]
    LAB --> LAB_OUT["→ Lab Tech Queue"]
    
    DOC_SEES --> DISCHARGE{"Discharge?"}
    DISCHARGE -->|"Yes"| BED_NOTIFY["Nurse notified:<br/>Bed needs updating"]
    BED_NOTIFY --> NURSE_BED["Nurse marks bed:<br/>Discharged → Cleaning → Available"]
    DISCHARGE -->|"No — Admitted"| STAY["Patient stays<br/>Nurse monitors vitals"]
    STAY -->|"Buffer time"| NURSE_VITALS

    style A fill:#0A84FF,color:#fff
    style NURSE_ALERT fill:#FF375F,color:#fff
    style NURSE_VITALS fill:#FF375F,color:#fff
    style DOC_SEES fill:#30D158,color:#fff
    style NURSE_BED fill:#FF375F,color:#fff
    style URGENT fill:#FF9500,color:#fff
```

---

## 5. Patient Complete Workflow

```mermaid
flowchart TD
    A(["Patient Logs In"]) --> HOME["Home Dashboard"]

    HOME -->|"Quick Action"| BOOK["Book Appointment"]
    BOOK --> B1["Select Specialty → Doctor → Date → Confirm"]
    B1 --> APPT["Appointment Created"]

    HOME -->|"Quick Action"| LABREQ["Book Lab Test"]
    LABREQ --> LR1["Select Category (Blood/Urine/Imaging...)"]
    LR1 --> LR2["Pick Tests + Date"]
    LR2 --> LR3["Optional Doctor Referral"]
    LR3 --> LR4["Submit → Lab Tech Queue"]

    HOME -->|"Appointments Tab"| ALIST["Appointment List"]
    ALIST -->|"Tap"| ADET["Appointment Detail"]

    HOME -->|"Health Tab"| HEALTH["Health Dashboard<br/>HR, BP, SpO₂, Steps"]

    HOME -->|"Records"| RECORDS["Medical Records"]
    HOME -->|"Medicines"| RX["Prescription Tracker"]
    HOME -->|"Lab Results"| LAB["Lab Results View"]

    HOME -->|"Billing Tab"| BILL["Billing<br/>Outstanding / History"]

    HOME -->|"Profile"| PROF["PatientProfileView"]

    style A fill:#0A84FF,color:#fff
    style HOME fill:#30D158,color:#fff
    style LABREQ fill:#FF9500,color:#fff
```

---

## 6. Admin Operations — Bed Management Focus

```mermaid
flowchart TD
    A(["Admin Logs In"]) --> DASH["AdminDashboardView"]

    DASH --> STAFF["Staff Management"]
    DASH --> DEPT["Department Management"]
    DASH --> REPORTS["Reports (Financial/Clinical)"]
    DASH --> BILLING["Billing Overview"]
    DASH --> SETTINGS["Admin Settings"]

    DASH --> BED["Bed Management"]

    BED --> STATS["Stats: Total / Available / Occupied /<br/>Reserved / Cleaning / Maintenance"]
    BED --> FILTER["Filter by Ward + Floor"]
    
    BED --> CAPACITY{"Occupancy > 85%?"}
    CAPACITY -->|"Yes"| ALERT["⚠️ High Occupancy Alert<br/>Suggest overflow protocol"]
    
    BED --> ACTIONS{"Bed Actions"}
    ACTIONS -->|"Available bed"| ADMIT["Admit: Reserve or Assign Patient"]
    ADMIT --> OCC["Status → Occupied"]
    
    ACTIONS -->|"Occupied bed"| DISC_OR_TRANSFER{"Action?"}
    DISC_OR_TRANSFER -->|"Discharge"| DISCHARGE["Status → Cleaning<br/>🔔 Nurse notified"]
    DISCHARGE --> NURSE_CLEAN["Nurse cleans → marks Available"]
    DISC_OR_TRANSFER -->|"Transfer"| TRANSFER["Move to another bed/ward"]
    
    ACTIONS -->|"Any bed"| MAINT["Toggle Maintenance<br/>(Admin only)"]

    BED --> HISTORY["Bed History Log<br/>(Last 5 events)"]

    style A fill:#0A84FF,color:#fff
    style DASH fill:#FF9500,color:#fff
    style ALERT fill:#FF375F,color:#fff
    style NURSE_CLEAN fill:#BF5AF2,color:#fff
```

---

## 7. Cross-Role Data Flow

```mermaid
    flowchart LR
        subgraph DoctorActions["🩺 Doctor"]
            DRx["Writes Rx"]
            DLab["Orders Lab"]
            DMR["Creates Record"]
        end

        subgraph PatientActions["🧑 Patient"]
            PLabReq["Requests Lab Test"]
            PBook["Books Appointment"]
        end

        subgraph DataStore["💾 MockDataService"]
            Prescriptions["Prescriptions"]
            LabOrders["Lab Orders"]
            Records["Medical Records"]
            Appointments["Appointments"]
            Beds["Bed Status"]
        end

        subgraph PatientViews["🧑 Patient Views"]
            PRx["Rx Tracker"]
            PLab["Lab Results"]
            PMR["Medical Records"]
            PApt["Appointments"]
        end

        subgraph NurseRole["👩‍⚕️ Nurse"]
            NVit["Records Vitals"]
            NBed["Updates Bed Status"]
            NQueue["Patient Queue"]
        end

        subgraph LabTech["🧪 Lab Tech"]
            LQueue["Test Queue"]
            LResults["Results Entry"]
        end

        subgraph Pharmacist["💊 Pharmacist"]
            PhQueue["Rx Queue"]
        end

        subgraph Admin["🏥 Admin"]
            AView["Views Beds/Staff/Reports"]
        end

        subgraph Siri["🗣️ Siri (7 Intents)"]
            SQ["Query: Next Appt / Schedule / Rx"]
            SA["Action: Book / Lab / Beds / Vitals"]
        end

        DRx -->|"creates"| Prescriptions
        DLab -->|"creates"| LabOrders
        DMR -->|"creates"| Records
        PLabReq -->|"creates"| LabOrders
        PBook -->|"creates"| Appointments

        Prescriptions -->|"shown in"| PRx
        Prescriptions -->|"queued in"| PhQueue
        LabOrders -->|"queued in"| LQueue
        LResults -->|"updates"| LabOrders
        LabOrders -->|"shown in"| PLab
        Records -->|"shown in"| PMR
        Appointments -->|"shown in"| PApt

        NVit -->|"updates"| Records
        NBed -->|"updates"| Beds
        Appointments -->|"notify"| NQueue

        AView -->|"reads"| DataStore

        SQ -->|"queries"| DataStore
        SA -->|"actions"| DataStore

        style DoctorActions fill:#30D158,color:#fff
        style PatientActions fill:#0A84FF,color:#fff
        style DataStore fill:#FF9500,color:#fff
        style NurseRole fill:#FF375F,color:#fff
        style Siri fill:#BF5AF2,color:#fff
```

---

## 8. Data Model — Entity Relationships

```mermaid
erDiagram
    MedNexUser {
        string id PK
        string email
        string displayName
        UserRole role
    }

    Appointment {
        string id PK
        string patientId FK
        string doctorId FK
        date dateTime
        string specialty
        AppointmentStatus status
        string reason
    }

    Prescription {
        string id PK
        string patientId FK
        string doctorId FK
        string drugName
        string dosage
        string frequency
        int durationDays
        PrescriptionStatus status
    }

    MedicalRecord {
        string id PK
        string patientId FK
        string doctorId FK
        string diagnosis
        string clinicalNotes
        string treatmentPlan
        date createdAt
    }

    LabTest {
        string id PK
        string patientId FK
        string orderedBy FK
        string testName
        string category
        LabTestStatus status
        string priority
        string requestSource
    }

    Doctor {
        string id PK
        string name
        string specialty
        string assignedNurseId FK
    }

    Patient {
        string id PK
        string name
        int age
        string bloodGroup
    }

    Bill {
        string id PK
        string patientId FK
        double amount
        BillStatus status
    }

    Staff {
        string id PK
        string name
        UserRole role
        string department
    }

    Department {
        string id PK
        string name
        string headId FK
    }

    BedInfo {
        string id PK
        string number
        string ward
        string floor
        BedStatus status
        string patientId FK
    }

    VitalRecord {
        string id PK
        string patientId FK
        string nurseId FK
        double heartRate
        string bloodPressure
        double temperature
        double oxygenSaturation
    }

    NurseQueuePatient {
        string id PK
        string patientName
        string doctorName
        string room
        PatientQueueStatus status
    }

    MedNexUser ||--o{ Appointment : "books"
    Doctor ||--o{ Appointment : "provides"
    Doctor ||--o{ Prescription : "prescribes"
    Doctor ||--o{ MedicalRecord : "authors"
    Doctor ||--o{ LabTest : "orders"
    Doctor ||--|| Staff : "is a"
    Patient ||--o{ Appointment : "has"
    Patient ||--o{ Prescription : "receives"
    Patient ||--o{ LabTest : "requests"
    Patient ||--o{ Bill : "owes"
    Patient ||--o{ VitalRecord : "has"
    Staff ||--o{ VitalRecord : "records"
    Staff ||--o{ NurseQueuePatient : "manages"
    Department ||--o{ Staff : "contains"
    Department ||--o{ BedInfo : "has"
    BedInfo ||--o| Patient : "occupied by"
```
