# Comprehensive PDF Reader & Utility Application
**Course**: Mobile Application Development  
**Instructor**: Muhammad Abrar Saddique  
**Submission**: Lab – Mid Task (100 Marks)

---

## 📖 Project Overview
This application is a feature-rich, high-performance mobile PDF Reader and Utility Suite built using **Flutter** and **SQLite (`sqflite`)**. It provides an intuitive, modern Material 3 interface that allows users to open, read, organize, and annotate PDF documents, while offering utility features including a **multi-page document scanner**, **PDF-to-image converter**, **reading session & progress tracking**, **local notifications**, and **multi-format data export (CSV, PDF, and Email)**.

---

## 🎯 Marks Distribution & Feature Verification

| # | Component | Marks | Implementation Details in This Project |
|---|---|---|---|
| 1 | **Project Setup & Design** | 10 | Production Flutter project structure with clean architecture (`database/`, `models/`, `providers/`, `screens/`, `services/`, `widgets/`), Material 3 theming (Light/Dark mode), and state management via `Provider`. |
| 2 | **Database Integration** | 10 | Robust SQLite database (`DatabaseHelper`) managing relational tables: `documents`, `bookmarks`, `reading_history`, and `user_settings` with foreign key cascades, migrations, and CRUD APIs. |
| 3 | **PDF Reading & Document Management** | 20 | Integrated `syncfusion_flutter_pdfviewer` with pinch-to-zoom, scroll head/status, page indicator, jump-to-page dialog, favorite toggle, page bookmarking, renaming, tags, and document deletion. |
| 4 | **Advanced / Utility Features** | 20 | Camera & gallery document scanner to multi-page PDF, PDF-to-image rasterization (PNG/JPG), light/dark & reading background themes (Sepia, Night, Cream), reading progress bar with resume, and CSV/PDF export. |
| 5 | **Notification & Search Functionality** | 10 | `flutter_local_notifications` for daily reading target reminders and new document notifications; real-time library search by title, tags, and description with filter chips. |
| 6 | **Scanner & Conversion Implementation** | 10 | Hardware camera/gallery integration with multi-page image capture, sequencing, compilation to PDF via `pdf` package, and page-by-page image extraction via `printing`. |
| 7 | **User Interface** | 10 | Responsive navigation bar with 5 distinct views: Library, Favorites/Bookmarks, Recents & Reading History, Document Scanner, and Settings. |
| 8 | **Documentation & GitHub Submission** | 10 | Structured `Lab-Mid` folder containing `lib/`, `android/`, `pubspec.yaml`, and complete documentation. |
| **Total** | | **100** | **Complete Implementation** |

---

## 🏗️ Architecture & Folder Structure

```
pdf_reader_utility_app/
│
├── pubspec.yaml                 # Dependencies and asset declarations
├── README.md                    # Detailed documentation and setup guide
│
├── Lab-Mid/                     # Required GitHub submission package
│   ├── lib/
│   ├── android/
│   ├── pubspec.yaml
│   └── README.md
│
├── android/                     # Android native configuration
│   └── app/src/main/
│       ├── AndroidManifest.xml  # Permissions (Camera, Storage, Notifications)
│       └── kotlin/              # MainActivity.kt
│
└── lib/
    ├── main.dart                # App entrypoint, Provider registration, themes
    │
    ├── models/
    │   ├── pdf_document.dart    # PDF document entity with metadata and progress
    │   ├── bookmark.dart        # Saved page bookmark entity with notes
    │   ├── reading_history.dart # Session timestamp logs
    │   └── user_settings.dart   # Theme, background colors, and goal preferences
    │
    ├── database/
    │   └── db_helper.dart       # SQLite singleton database helper & CRUD operations
    │
    ├── providers/
    │   ├── document_provider.dart # Document library state, filters, favorites, history
    │   └── theme_provider.dart    # ThemeMode, reading backgrounds, notification settings
    │
    ├── services/
    │   ├── pdf_service.dart          # Import PDF, rasterize to PNG, compile images to PDF
    │   ├── export_service.dart       # Export to CSV, generate PDF summary report, share
    │   └── notification_service.dart # Local notification scheduler and triggers
    │
    ├── screens/
    │   ├── main_navigation_screen.dart    # Bottom Navigation controller
    │   ├── library_screen.dart            # All PDFs catalog, tag filters, sorting, import
    │   ├── favorites_bookmarks_screen.dart# 2 Tabs: Favorite PDFs & Bookmarked Pages
    │   ├── recent_history_screen.dart     # Resume reading & session timeline log
    │   ├── pdf_viewer_screen.dart         # Core PDF reader, zoom, jump, sepia/night modes
    │   ├── document_details_screen.dart   # Metadata editor (title, tags, description)
    │   ├── scanner_screen.dart            # Camera/gallery scanner to PDF compiler
    │   ├── pdf_to_image_screen.dart       # Convert PDF pages to high-res images
    │   ├── export_screen.dart             # CSV, PDF report, and email share hub
    │   ├── search_screen.dart             # Real-time search across title, tags & notes
    │   └── settings_screen.dart           # Themes, reading goals, notification test
    │
    └── widgets/
        ├── document_card.dart    # Reusable card with progress indicator & popup menu
        ├── progress_bar.dart     # Percentage and page indicator
        └── empty_state.dart      # Clean fallback view for empty states
```

---

## 💾 Database Schema (SQLite)

### 1. `documents`
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `title` (TEXT NOT NULL)
- `file_path` (TEXT NOT NULL UNIQUE)
- `file_size` (INTEGER NOT NULL)
- `total_pages` (INTEGER NOT NULL DEFAULT 1)
- `last_read_page` (INTEGER NOT NULL DEFAULT 1)
- `last_read_time` (TEXT)
- `is_favorite` (INTEGER NOT NULL DEFAULT 0)
- `tags` (TEXT - JSON encoded list)
- `description` (TEXT)
- `created_at` (TEXT NOT NULL)

### 2. `bookmarks`
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `document_id` (INTEGER NOT NULL, FK to documents)
- `page_number` (INTEGER NOT NULL)
- `title` (TEXT NOT NULL)
- `note` (TEXT)
- `created_at` (TEXT NOT NULL)

### 3. `reading_history`
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `document_id` (INTEGER NOT NULL, FK to documents)
- `page_number` (INTEGER NOT NULL)
- `duration_seconds` (INTEGER NOT NULL DEFAULT 0)
- `timestamp` (TEXT NOT NULL)

### 4. `user_settings`
- `id` (INTEGER PRIMARY KEY)
- `theme_mode` (TEXT NOT NULL DEFAULT 'system')
- `reading_bg_color` (TEXT NOT NULL DEFAULT 'white')
- `notification_sound` (TEXT NOT NULL DEFAULT 'default')
- `reading_goal_minutes` (INTEGER NOT NULL DEFAULT 30)
- `notifications_enabled` (INTEGER NOT NULL DEFAULT 1)
- `reminder_time` (TEXT NOT NULL DEFAULT '20:00')

---

## 🚀 How to Run the Project

### Prerequisites
1. Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (version >= 3.5.0).
2. Install Android Studio with Android SDK (API 34) and an Android Emulator or connected physical device with USB Debugging enabled.

### Running Steps
```bash
# 1. Navigate to project directory
cd "C:\Users\AR\.gemini\antigravity\scratch\pdf_reader_utility_app"

# 2. Get dependencies
flutter pub get

# 3. Run the app on emulator or device
flutter run

# 4. (Optional) Build release APK
flutter build apk --release
```
The generated APK will be placed at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 📤 GitHub Submission Instructions
As requested by instructor Muhammad Abrar Saddique:
1. Clone the required GitHub repository shared by the instructor.
2. Ensure the `Lab-Mid` folder contains:
   - `lib/`
   - `android/`
   - `pubspec.yaml`
   - `README.md`
3. Commit and push:
```bash
git add Lab-Mid/
git commit -m "Submission: Lab - Mid Task (Comprehensive PDF Reader & Utility Application)"
git push origin main
```
