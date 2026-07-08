# ALU InternConnect 🚀

A Flutter mobile application connecting ALU students with student-led startups for meaningful internship experiences.

---

## Features

### For Students
- 🔍 **Discover Opportunities** — Browse and search opportunities by category, type, and location
- ⭐ **Personalized Recommendations** — See roles matching your skills on the home screen
- 📌 **Bookmark Opportunities** — Save roles for later
- 📝 **Apply with Cover Letter** — Submit applications with cover letter and portfolio link
- 📊 **Track Applications** — Real-time status updates (Pending → Under Review → Shortlisted → Accepted)
- 👤 **Edit Profile** — Update your skills, bio, and portfolio

### For Startups
- ✅ **ALU Verification System** — Only ALU-recognized startups are approved 
- 📢 **Post Opportunities** — Create detailed role listings with skills, type, and deadline
- 👥 **Manage Applications** — Review applicants, shortlist and accept candidates
- 📈 **Dashboard** — Track active roles and incoming applications

### General
- 🔒 **Firebase Auth** — Email/password authentication
- ⚡ **Real-time Updates** — Firestore streams for live data
- 🗺 **GoRouter Navigation** — Type-safe routing with role-aware redirects
- 🧩 **BLoC/Cubit** — Clean state management across all features

---

## Architecture

```
lib/
├── core/
│   ├── constants/       # App-wide constants (collections, roles, categories)
│   ├── theme/           # AppTheme, AppColors, AppTextStyles
│   └── utils/
├── features/
│   ├── auth/
│   │   ├── bloc/        # AuthCubit + AuthState
│   │   ├── models/      # UserModel
│   │   ├── repositories/# AuthRepository (Firebase Auth + Firestore)
│   │   └── screens/     # Splash, Onboarding, Login, SignupStudent, SignupStartup
│   ├── opportunities/
│   │   ├── bloc/        # OpportunityCubit
│   │   ├── models/      # OpportunityModel
│   │   ├── repositories/# OpportunityRepository
│   │   ├── screens/     # Explore, OpportunityDetail, CreateOpportunity
│   │   └── widgets/     # OpportunityCard, RecommendedCard
│   ├── applications/
│   │   ├── bloc/        # ApplicationCubit
│   │   ├── models/      # ApplicationModel
│   │   ├── repositories/# ApplicationRepository
│   │   └── screens/     # Applications, Apply
│   ├── startup/
│   │   ├── models/      # StartupModel
│   │   ├── repositories/# StartupRepository
│   │   └── screens/     # StartupProfile, StartupDashboard
│   ├── profile/
│   │   └── screens/     # Profile, EditProfile
│   └── home/
│       └── screens/     # HomeShell (bottom nav), HomeScreen
└── config/
    └── router.dart      # GoRouter with auth-aware redirects
```

---

## Firebase Collections

| Collection | Description |
|---|---|
| `users` | All users (students + startup owners) |
| `startups` | Startup profiles with verification status |
| `opportunities` | Internship/role listings |
| `applications` | Student applications with status |
| `bookmarks` | Student saved opportunities |
| `notifications` | In-app notifications |

---

## Setup Guide

### 1. Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/alu_internconnect.git
cd alu_internconnect
```

### 2. Install Flutter dependencies
```bash
flutter pub get
```

### 3. Set up Firebase

**a) Create Firebase project**
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project** → name it `alu-internconnect`
3. Enable **Google Analytics** (optional)

**b) Enable Firebase services**
- **Authentication** → Sign-in method → Email/Password → Enable
- **Firestore Database** → Create database → Start in **test mode** (then update with security rules below)
- **Storage** → Get started

**c) Install FlutterFire CLI and configure**
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```
This auto-generates `lib/firebase_options.dart` with your credentials.

**d) Deploy Firestore security rules**
```bash
firebase deploy --only firestore:rules
```

### 4. Run the app
```bash
# On Android emulator
flutter run

# On iOS simulator
flutter run -d ios

# With specific device
flutter devices
flutter run -d DEVICE_ID
```

---

## State Management

ALU InternConnect uses **BLoC / Cubit** pattern:

- **AuthCubit** — Handles sign in, sign up, sign out, and session persistence
- **OpportunityCubit** — Streams real-time opportunities from Firestore; handles filters, search, and bookmarks
- **ApplicationCubit** — Streams student applications or startup incoming applications in real-time

All Cubits are provided at the app root via `MultiBlocProvider` and repositories are injected via `MultiRepositoryProvider`.

---

## Firestore Security Rules

Security rules are in `firestore.rules`. Key rules:
- Students can only read/write their own applications
- Only **approved** startups can post opportunities
- Startup owners can update application status
- Admin role can approve/reject startups

---

## Demo Credentials (for testing)

After setup, create test accounts manually or seed the database. Suggested test data:

| Role | Email | Password |
|---|---|---|
| Student | student@alustudent.com | test123 |
| Startup | startup@learnify.com | test123 |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart) |
| State Management | flutter_bloc (Cubit) |
| Backend | Firebase (Auth, Firestore, Storage) |
| Navigation | go_router |
| UI | Material 3, Google Fonts (Outfit) |
| Architecture | Feature-first, Repository pattern |

---

## Author

**Elvis** — African Leadership University  
Course: Mobile Application Development  
Assignment: Final Flutter Project
