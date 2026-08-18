# 📋 Contribution Log — Sahaj Srivastava
**Role:** Project Admin · Frontend Developer  
**Project:** SchoolSync — SW2627-Dart-Flutter-Firebase-SchoolSync  

---

### 🎯 Objective
Set up the Flutter development environment, validate the project scaffold, resolve build blockers, and get the app running on a web target for the first time.

---

### ✅ Tasks Completed

#### 1. 🔧 Flutter Environment Audit
- Conducted a full `flutter doctor -v` diagnostic on the local machine
- Verified Flutter SDK (v3.44.9, stable channel) installed correctly at `D:\development\flutter`
- Confirmed `D:\development\flutter\bin` is correctly added to system `PATH`
- Identified and documented all environment issues hindering Android development

#### 2. 🐛 Fixed Critical Bug in `lib/main.dart`
- Identified two compile-breaking syntax errors caused by missing class name prefixes in Dart
- **Fix 1 (Line 31):** Corrected `.fromSeed(...)` → `ColorScheme.fromSeed(...)`
- **Fix 2 (Line 105):** Corrected `.center` → `MainAxisAlignment.center`
- App was completely non-compilable before this fix

#### 3. 🔓 Resolved OneDrive File-Locking Issue
- Diagnosed that project stored under `OneDrive\Desktop\` caused OneDrive to place **reparse-point locks** on Flutter's ephemeral build directories
- Locked paths identified:
  - `ios/Flutter/ephemeral/Packages/`
  - `macos/Flutter/ephemeral/Packages/`
- Force-removed all locked directories using `rd /s /q` to restore Flutter's read/write access

#### 4. 🌐 Successfully Ran App on Chrome (Web Target)
- Executed `flutter run -d chrome` successfully
- Dart VM connected at `ws://127.0.0.1:53711/`
- Flutter DevTools profiler & debugger confirmed live
- App launched in Chrome debug mode — Flutter counter scaffold confirmed working

#### 5. 📁 Initialized Flutter Project Scaffold (`mobile_app/`)
- Verified the generated Flutter project structure:
  - `lib/main.dart` — app entry point ✅
  - `pubspec.yaml` — dependency manifest ✅
  - `android/`, `ios/`, `web/`, `windows/` platform folders ✅
  - `pubspec.lock` present for dependency consistency across team ✅
- Confirmed `.gitignore` covers all Flutter build artifacts and IDE files

---

### ⚠️ Blockers Identified & Documented

| Blocker | Status | Owner |
|---|---|---|
| Android Studio not installed — cannot build for Android | 🔴 Open | Sahaj (self) |
| `ANDROID_HOME` / `ANDROID_SDK_ROOT` env vars not set | 🔴 Open | Sahaj (self) |
| `JAVA_HOME` not set; Java 8 installed (need Java 17) | 🟡 Open | Sahaj (self) |
| Project on OneDrive path (causes recurring file locks) | 🟡 Open | Sahaj (self) |
| `mobile_app/` not yet committed/pushed to GitHub | 🟡 Open | Sahaj (self) |

---

### 📝 Notes & Decisions

- **Web-first approach adopted for Day 1:** Since Android toolchain is not yet set up, `flutter run -d chrome` was used as the primary testing target. All UI work can proceed via Chrome until Android Studio is installed.
- **`google-services.json` must be added to `.gitignore`** before Firebase integration begins — flagged for the team.
- **Architecture doc reviewed:** The `docs/architecture.md` feature-first folder structure is approved and will be used as the blueprint for `lib/` directory creation.

---

### 🔗 References
- [`lib/main.dart`](../mobile_app/lib/main.dart) — Bug fixes applied
- [`pubspec.yaml`](../mobile_app/pubspec.yaml) — Dependency manifest
- [`docs/architecture.md`](./architecture.md) — Folder structure blueprint
- [Flutter Setup Audit Report](./flutter_audit_report.md) — Full environment audit

---

### 🎯 Objective
After completing the log in and sign up flow we made and finalised the design and data for the user dashboard and made sure that all the data is connected and we prioritized the working and user flow forst. the database, backend logic and the UI layout has been defined after I have created the low level diagram for the following.

*Log maintained by Sahaj Srivastava · Updated after each working session*
