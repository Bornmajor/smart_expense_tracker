# Roadmap and TODO

What is planned, in the order we intend to build it. Items move to the README feature list as they ship. Anything never built is deleted before release.

## Up next

1. **Release setup and early testers** (code done, your setup remains). The `dev`, `uat` and `main` flow is built: `uat` sends a build to Play internal testing and `main` sends one to production after approval (see [branching](branching.md) and [releasing](releasing.md)). Still needed: the GitHub secrets, a first internal release, and a **closed test with testers started early**, because new personal accounts have needed 12 testers for 14 days before production.
2. **Scan a receipt with the camera** (the gallery route is done). The camera path, its "Use this photo / Retake" preview and the recovery of a photo lost to an app restart are built and tested, but switched off (`ScanFeatures.cameraEnabled` in `lib/features/scan/scan_features.dart`). On the Infinix X6528 test phone (3.8 GB RAM, swap nearly full) Android kills the app about two seconds after the system camera opens, which looks like a crash; the photo is recovered, but the restart is rough. Before turning it on: test a release build, read the kill reason from `adb logcat` right after a kill (the low-memory killer naming the app, or a vendor cleaner), and choose between keeping the system camera, an in-app camera (`camera` package) or Google's ML Kit document scanner. Recovery also needs wiring at app start, after the biometric unlock, so a recovered photo opens straight on the preview.
**Done:** onboarding redesign, safe-area fixes, color-coded snackbars, the expense loop (edit, delete with undo, list grouped by day), an optional title, category management, and adding a category from the expense form, scanning a receipt photo from the gallery, and exporting a month as a PDF or CSV from the Summary screen., choosing a currency, and remembering the category for each vendor.

**Still to look at for export:** the PDF embeds the Inter font (`assets/fonts`), which covers Latin, Greek and Cyrillic. A vendor name in another script (Chinese, Arabic, and so on) would show as blank boxes in the PDF; the CSV is fine. Try the share sheet on a real phone before the first release. The privacy policy needs one line saying a report leaves the app only when the user shares it.

**Privacy and store forms (before the first public release):**
- Publish the privacy policy as a web page on Google Sites (not a PDF, not editable, public, no sign-in). The text is in [privacy-policy.md](privacy-policy.md), with an optional HTML version. Paste the text straight into the page rather than embedding it.
- The "Privacy policy" row under Settings, About is built (it opens the page in the browser). The published address is set in `lib/core/links/app_links.dart` (the row stays hidden if it is ever emptied); Google requires the link inside the app as well as in the Play listing.
- Data safety form: do not answer "no data collected". Google says ML Kit sends performance and usage metrics to Google, and the release app has the `INTERNET` permission because of it. Declare it as the form's questions require, and check the current form before submitting.
- Decide about device backups: `android:allowBackup` is not set, so Android may back the app's data up to the user's Google account. The policy says so. Setting it to `false` would keep expenses out of backups, at the cost of not restoring them on a new phone.
- Keep the policy, the Data safety form and the real behavior in step whenever something changes (for example when report export ships).

**Before the first public release:** remove the temporary OCR test screen (`lib/features/scan/debug/`, its route in `app_router.dart` and the Developer entry in Settings). On iOS, ML Kit needs two manual Xcode steps (linker flags and the Latin model bundle) that are not done yet; see the plugin's README.

## Planned: prompt sheet

A bottom sheet that tells the user about a feature they have not tried, or a task still pending.

**Example:** the first prompt introduces the biometric lock: "Lock SpendWise IQ with your fingerprint or face, and open it quickly."

**What the user sees**
- A bottom sheet on the home screen with an icon, a title, a short description, and three choices:
  - **Primary action** (for the example, "Turn on"): does the thing, or opens the right Settings screen.
  - **Remind me later**: closes the sheet. It shows again on the **next app start**.
  - **Not interested**: closes the sheet and it is **never shown again**.
- Taking the action also ends the prompt for good.

**Rules**
- At most **one** prompt per app start. If several are waiting, the one with the highest priority is shown.
- Never over the welcome, onboarding or lock screens. Not on the very first session after onboarding, so the user sees the app first.
- A prompt is skipped when it no longer applies, for example the biometric lock is already on, or the device has no biometrics.
- "Remind me later" is remembered for the current run only. "Not interested" and a completed action are saved on the device.

**Likely prompts, in order**
1. Turn on the biometric lock.
2. Try receipt scanning (when scanning ships).
3. A monthly report is ready to export (at the start of a new month).

**How it fits the architecture**
- A new `announcements` feature. The domain layer holds a prompt entity (id, priority, eligibility) and a repository that stores which prompts were dismissed or completed.
- A `SelectPromptToShow` use case holds the real logic: which prompts apply, their priority, and one per start. It gets unit tests.
- A cubit shows the chosen prompt, and a sheet widget (with a widget test) is shown by the app shell.
- Choices are saved in `shared_preferences`, one entry per prompt id.

## Later

- **Decided next, in this order:** monthly budgets per category and overall with progress bars; recurring expenses and subscriptions (added when the app opens, no background service); insights written in plain Dart (month against last month, biggest change, budget pace, subscription cost, unusual expenses), with a plain-text wording layer so a language model can be added later on phones that support it; then backup and restore to a file.
- Search and filters.
- More charts.

- A different currency on each expense (today one currency is used for all amounts).
- Optional receipt attachment.
- Use the bundled Inter font in the app itself (the files are already in assets/fonts for the PDF; set `AppTypography.fontFamily` and declare them under `fonts:` in pubspec.yaml).
- Change the iOS bundle id from `com.example.smartExpenseTracker` when iOS work starts.
