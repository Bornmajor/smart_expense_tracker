# SpendWise IQ

**Snap a receipt. Know where your money goes.**

SpendWise IQ is a smart, privacy-first expense tracker. Point your camera at a receipt and the app reads the vendor, date and total on your device, suggests a category, and lets you confirm the details before saving. No typing, no account, no cloud.

## The problem it solves

Most people want to know where their money goes, but tracking it is tedious. Receipts pile up, typing each purchase takes too long, and the habit fades after a week. The apps that automate it usually ask for an account and upload financial data to a server.

SpendWise IQ removes the effort and keeps the data private:

- **Scan instead of type.** On-device text recognition turns a photo of a receipt into an expense in seconds.
- **Smart, but you stay in control.** The app fills in the form and suggests a category. You verify and correct it before anything is saved, so records stay accurate.
- **Private and offline-first.** Everything is stored on your phone and works without internet.
- **Clear picture of your spending.** Monthly totals, category breakdowns and budgets show what is happening and warn you before you overspend.

## Features

Status: `[x]` implemented, `[ ]` planned. Planned items that are never built will be removed from this list before release.

### Implemented

- [x] Light and dark themes with a shared design system (colors, spacing, typography)
- [x] Welcome screen and three-step onboarding, shown once
- [x] Manual expense entry with validation, stored offline on the device
- [x] Expense list, newest first
- [x] Monthly summary: total and spending by category, with a month switcher
- [x] Settings: theme (system, light, dark) and About
- [x] Optional fingerprint / face lock, turned on from Settings

### Planned

**MVP: scan, track, export**
- [ ] Optional receipt scanning with camera capture or gallery import (manual entry always works)
- [ ] On-device OCR that extracts vendor, date and total
- [ ] Review-and-edit form, auto-filled from the scan, confirmed before saving
- [ ] Automatic category suggestion, with manual override
- [ ] Expense list grouped by day, with edit and delete (undo)
- [ ] Custom categories (create and edit)
- [ ] Monthly report as PDF and CSV, shared or saved from the system share sheet

**After the MVP**
- [ ] Budgets with progress and alerts
- [ ] Search and filters (date, category, amount, vendor)
- [ ] More charts and insights
- [ ] Recurring expenses
- [ ] Multi-currency
- [ ] Optional receipt attachment

## Tech stack

| Area | Technology | Status |
|---|---|---|
| Framework | Flutter 3.47 (Dart 3.13), Material 3 | In use |
| Theming | `ThemeData` + `ThemeExtension`, light and dark | In use |
| CI | GitHub Actions (format, analyze, test, coverage) | In use |
| Local database | `drift` (SQLite) | In use |
| State management | `flutter_bloc` (Cubit), `equatable`, `bloc_test` for tests | In use |
| Navigation | `go_router` | In use |
| Settings storage | `shared_preferences` | In use |
| Biometrics | `local_auth` | In use |
| Camera | `camera` / `image_picker` | Planned |
| On-device OCR | `google_mlkit_text_recognition` (ML Kit) | Planned |
| Charts | `fl_chart` (if a chart is added) | Planned |
| Export | `pdf`, `printing`, `csv`, `share_plus` | Planned |

## Architecture

The app uses a feature-first structure with domain, data and presentation layers in each feature. See [docs/architecture.md](docs/architecture.md) for the folder layout, data flow and conventions.

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **3.47.2** (Dart 3.13.2) or newer on the stable channel
- Android Studio (Android SDK and emulator) and/or Xcode (macOS, for iOS)
- A connected device or emulator. Camera features will need a real device.

Check your setup:

```bash
flutter doctor
```

### Install

```bash
git clone <your-repo-url>
cd smart_expense_tracker
flutter pub get
```

### Run

```bash
flutter run
```

Pick a device when prompted, or pass one with `-d <device-id>` (list them with `flutter devices`).

### Test

```bash
flutter test                       # run all tests
dart run tool/coverage.dart        # run tests and enforce 80% coverage
```

We test business logic, utility functions and reusable UI components rather than everything. The coverage script counts every file under `lib/` (not only files a test imports) and skips entry points and generated code.

### Continuous integration

Every pull request and every push to `main` runs the workflow in [`.github/workflows/ci.yml`](.github/workflows/ci.yml):

1. Formatting check (`dart format`)
2. Static analysis (`flutter analyze --fatal-infos`)
3. Tests with a minimum 80% coverage gate

Run the same checks locally before opening a pull request:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
dart run tool/coverage.dart
```
