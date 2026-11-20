# Roadmap and TODO

What is planned, in the order we intend to build it. Items move to the README feature list as they ship. Anything never built is deleted before release.

## Up next

1. **Release setup and early testers** (code done, your setup remains). The `dev`, `uat` and `main` flow is built: `uat` sends a build to Play internal testing and `main` sends one to production after approval (see [branching](branching.md) and [releasing](releasing.md)). Still needed: the GitHub secrets, a first internal release, and a **closed test with testers started early**, because new personal accounts have needed 12 testers for 14 days before production.
2. **Scan a receipt with the camera** (the gallery route is done). The camera path, its "Use this photo / Retake" preview and the recovery of a photo lost to an app restart are built and tested, but switched off (`ScanFeatures.cameraEnabled` in `lib/features/scan/scan_features.dart`). On the Infinix X6528 test phone (3.8 GB RAM, swap nearly full) Android kills the app about two seconds after the system camera opens, which looks like a crash; the photo is recovered, but the restart is rough. Before turning it on: test a release build, read the kill reason from `adb logcat` right after a kill (the low-memory killer naming the app, or a vendor cleaner), and choose between keeping the system camera, an in-app camera (`camera` package) or Google's ML Kit document scanner. Recovery also needs wiring at app start, after the biometric unlock, so a recovered photo opens straight on the preview.
**Done:** onboarding redesign, safe-area fixes, color-coded snackbars, the expense loop (edit, delete with undo, list grouped by day), an optional title, category management, and adding a category from the expense form, scanning a receipt photo from the gallery, and exporting a month as a PDF or CSV from the Summary screen., choosing a currency, remembering the category for each vendor, and monthly budgets with progress on the Summary.

**Still to look at for export:** the PDF embeds the Inter font (`assets/fonts`), which covers Latin, Greek and Cyrillic. A vendor name in another script (Chinese, Arabic, and so on) would show as blank boxes in the PDF; the CSV is fine. Try the share sheet on a real phone before the first release. The privacy policy needs one line saying a report leaves the app only when the user shares it.

**Privacy and store forms (before the first public release):**
- Publish the privacy policy as a web page on Google Sites (not a PDF, not editable, public, no sign-in). The text is in [privacy-policy.md](privacy-policy.md), with an optional HTML version. Paste the text straight into the page rather than embedding it.
- The "Privacy policy" row under Settings, About is built (it opens the page in the browser). The published address is set in `lib/core/links/app_links.dart` (the row stays hidden if it is ever emptied); Google requires the link inside the app as well as in the Play listing.
- Data safety form: do not answer "no data collected". Google says ML Kit sends performance and usage metrics to Google, and the release app has the `INTERNET` permission because of it. Declare it as the form's questions require, and check the current form before submitting.
- Decide about device backups: `android:allowBackup` is not set, so Android may back the app's data up to the user's Google account. The policy says so. Setting it to `false` would keep expenses out of backups, at the cost of not restoring them on a new phone.
- Keep the policy, the Data safety form and the real behavior in step whenever something changes (for example when report export ships).

**Before the first public release:** remove the temporary OCR test screen (`lib/features/scan/debug/`, its route in `app_router.dart` and the Developer entry in Settings). On iOS, ML Kit needs two manual Xcode steps (linker flags and the Latin model bundle) that are not done yet; see the plugin's README.

## TODO: app PIN (brainstormed, not built)

An optional PIN of the app's own, besides the biometric and phone-screen-lock check that exists now. The main reason: on a shared phone, family may know the phone's PIN, and a separate app PIN keeps spending private from them. It also helps phones with no screen lock.

**Decided so far**
- Settings, Security gets "App lock" with three modes: Off, Phone lock (fingerprint, face or phone screen lock, as today), and App PIN with an optional fingerprint shortcut.
- 4 to 6 digits, entered twice to set. The PIN is never stored: only a salted slow hash, in Android's secure storage (`flutter_secure_storage`).
- After 5 wrong tries the lock waits 30 seconds, then longer each time, and the wait survives closing the app. Nothing erases automatically, because that risks losing data.
- Forgot the PIN: there is no account to recover through. Reset it by confirming with the phone's own screen lock, and only if there is none, offer erase and start over with a clear warning. Backup and restore to a file (see Later) softens that case.
- The PIN hashing and the attempt limit are plain Dart and the best things to test. One reusable PIN pad widget.

**Still to decide:** PIN length (4 to 6, or fixed at 6), whether the fingerprint shortcut is offered, whether to add "hide in recent apps", and an auto-lock delay setting (the app locks after 30 seconds away today).

**Honest limits:** the PIN is a gate on the screen, not encryption. The database stays unencrypted, and a short PIN could be guessed offline by someone who extracts the hash. It stops casual snooping, not forensics. Encrypting the database from the PIN is possible later but is a much bigger job.

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

## Decided next, in this order

All of it is plain Dart on the phone: exact numbers worked out in code, shown with written text. A language model can be added later behind a switch, on phones that support it.

1. **Recurring expenses and subscriptions.** Due ones are added when the app opens (no background service), marked so the user can edit or skip them.
2. **Safe-to-spend and smart alerts.** A card such as "KSh 850 a day left this month", from the overall budget, spending so far and upcoming recurring bills, with the sum shown. Plus in-app alerts: a possible duplicate charge, a subscription that changed price, a category running well above normal this month, an unusually large expense. Month against last month, and the biggest change. Alerts show when the app is open; push alerts from the background are not planned, because some phones kill background apps.
3. **Backup and restore to a file**, optionally protected with a password, plus CSV import. This replaces cloud sync: a new phone gets the data back without a server.
4. **M-Pesa paste or share capture.** Share a confirmation message to the app, or paste it, and a plain Dart parser pre-fills the add-expense form (amount, who or what was paid, date, transaction code). The user checks it before saving. It needs no SMS permission: Google Play restricts SMS access to the default SMS app apart from narrow exceptions that need a declaration and review. The transaction code is stored on the expense (a new column) so the same message cannot be added twice. Needs real sample messages, with names and numbers removed, to build and test the parser.
5. **Rollover and rebalancing.** Optional: unused budget carries over, and the app suggests moving money from an unused category to an overspent one. Without a history of old limits, rollover uses today's limit.
6. **Split expenses and IOUs.** A first version: a "my share" amount on an expense, and a simple list of who owes whom. Totals count only the user's share. The largest piece of work.

## TODO: more ways to capture (later, not planned yet)

Both feed the same pre-filled add-expense form as scanning and M-Pesa capture, and nothing saves without the user checking it.

- **Typed quick add.** Type one line such as "lunch 350 cafe yesterday" and get the form filled in. A plain Dart parser finds the amount (including "1.5k"), the date words (today, yesterday, a weekday, "on 12 Nov") and the vendor after "at"; the rest becomes the title. The category comes from vendor memory, then the word list used for scanning. It guesses, so the form still shows. English only to start; Swahili words such as "jana" could be added. Effort: small to medium.
- **App shortcuts.** Long-press the app icon for "Add expense" or "Scan receipt", using the `quick_actions` package. If the app lock is on, the shortcut waits until the user unlocks and then continues. Android shows only a few shortcuts and launchers differ a little. A home-screen widget is a separate, larger job with native code. Effort: small.
- **Voice entry** is not planned: phone speech services can send audio to Google. If wanted, make it opt-in.

## Later

- Search and filters.
- More charts.

- A different currency on each expense (today one currency is used for all amounts).
- Optional receipt attachment.
- Use the bundled Inter font in the app itself (the files are already in assets/fonts for the PDF; set `AppTypography.fontFamily` and declare them under `fonts:` in pubspec.yaml).
- Change the iOS bundle id from `com.example.smartExpenseTracker` when iOS work starts.
