# Roadmap and TODO

What is planned, in the order we intend to build it. Items move to the README feature list as they ship. Anything never built is deleted before release.

**Current goal: a portfolio-quality app.** It should visibly solve the expense-tracking problem, be smart in ways a reviewer can see in a demo, and show careful engineering. Publishing to the Play Store is not the goal for now; the store work is parked below, and the GitHub release APK is enough for demos.

## Now: test what is built

Push, merge to `dev`, promote to `uat`, and try the build on a few phones. Then use the app for real for about two weeks: real use finds what tests cannot, and gives honest stories for the case study.

- Camera scan and the recovery of a photo lost when Android closes the app (it is switched on; see `ScanFeatures.cameraEnabled`). On the Infinix X6528 test phone (3.8 GB RAM) Android can kill the app seconds after the system camera opens. Read the kill reason from `adb logcat` if it happens, and test a release build, not a debug one.
- A PDF receipt, a large photo, a password-protected PDF, and the message shown when Android closes the app while a file is being chosen.
- Recurring expenses and the Repeat box (on a dev build, Settings, Developer, Pretend today is, shows a bill being added on its due date).
- The currency converter with and without internet, Safe to spend, and the heads-up cards.
- Cold start time on a release build.
- The receipt preview on the add form: from the small thumbnail and from the top-bar "View receipt" button, including after scrolling down the form, with pinch and double-tap zoom, for a photo, a camera picture and a PDF.
- Back up and restore: with and without a password, and restoring on a second phone or after a reinstall.

## Build next, in this order

All of it is plain Dart on the phone: exact numbers worked out in code, shown with written text. A language model could be added later behind a switch, on phones that support it.

1. **Polish.** Use the bundled Inter font in the app itself (the files are already in `assets/fonts` for the PDF; set `AppTypography.fontFamily` and declare them under `fonts:` in `pubspec.yaml`), the app PIN below as a fallback to biometrics, and a pass over empty states and onboarding.
2. **A better first screen, and better insights.** The app opens on a plain list of expenses that keeps scrolling, which is fine for finding things but a weak first impression. People expect the first screen to answer "how am I doing?" at a glance. Research first, without bias (what the best expense trackers show on their first screen, and what users of this kind of app say they want), then pick **3 to 5** things to put there. The starting ideas, to be checked against that research:
   - **A greeting by name.** Onboarding asks for a first name (kept only on the phone, like everything else; it is optional) so the top of the app can say "Good morning, Maja". Needs a name step in onboarding and a way to change it in Settings.
   - **How I am doing against my target:** this month's spending against the overall budget (and Safe to spend), in one glance, with a clear prompt to set a budget when there is none.
   - **A small bar chart of spending per month for the current year**, so the trend is clear at a glance (the chart can be tapped to open that month on the Summary).
   - **A clear Add expense action** (it exists today) kept visible, with the recent expenses shown as a short list under the insights and a "see all" link, instead of the whole scrolling list.
   - **Heads-up cards** (already built) and this month against last month with the biggest change.
   - Also on the list of insights: an alert for a subscription that changed price.
   The Expenses list stays one tap away (search and filters already work there). Decide the final 3 to 5 after the research, and keep the screen calm: a few strong things, not a dashboard of everything.

## Portfolio showcase (cheap, high value)

Most reviewers will not install the app, so the repository has to show it.

- **Sample-data mode** (dev flavor): fills the app with realistic expenses, budgets and recurring bills so screenshots and demos look alive, and so anyone can try it.
- **README:** current screenshots (the old ones predate scanning files, converting, Safe to spend and alerts), a 60 to 90 second demo video or GIFs, CI and coverage badges, a one-line link to the release APK, and a short architecture diagram.
- **Case study page:** the problem, the decisions and trade-offs (on-device ML Kit OCR instead of a cloud service, plain Dart insights, no account), the testing and release pipeline, and what would come next. This roadmap already holds most of the material.
- Be plain about what "smart" means here: on-device receipt reading, a vendor-to-category memory, and rule-based insights. No cloud AI, by choice, for privacy.

## Done

**Done:** onboarding redesign, safe-area fixes, color-coded snackbars, the expense loop (edit, delete with undo, list grouped by day), an optional title, category management, adding a category from the expense form, scanning a receipt from a photo or a PDF in the Files app, the camera option with recovery of a photo lost to an app restart, exporting a month as a PDF or CSV, choosing a currency (the Kenyan shilling by default), converting an amount from another currency with the daily rate, remembering the category for each vendor, an app lock that never locks the user out, monthly budgets with progress on the Summary, recurring expenses added when they come due, backup and restore to a file (optionally password-protected), a Repeat box on the add form, a tap-through from Summary categories and budgets to their expenses, search and filters on the expense list, typing an expense in one line, pasting an M-Pesa message, Safe to spend, heads-up cards for duplicates, large expenses and a category above normal, the app version in Settings, and a dev-only Pretend today is tool.

## TODO: app PIN (brainstormed, not built; part of Polish above)

An optional PIN of the app's own, besides the biometric and phone-screen-lock check that exists now. The main reason: on a shared phone, family may know the phone's PIN, and a separate app PIN keeps spending private from them. It also helps phones with no screen lock.

**Decided so far**
- Settings, Security gets "App lock" with three modes: Off, Phone lock (fingerprint, face or phone screen lock, as today), and App PIN with an optional fingerprint shortcut.
- 4 to 6 digits, entered twice to set. The PIN is never stored: only a salted slow hash, in Android's secure storage (`flutter_secure_storage`).
- After 5 wrong tries the lock waits 30 seconds, then longer each time, and the wait survives closing the app. Nothing erases automatically, because that risks losing data.
- Forgot the PIN: there is no account to recover through. Reset it by confirming with the phone's own screen lock, and only if there is none, offer erase and start over with a clear warning. Backup and restore to a file (see Decided next) softens that case.
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

## TODO: later, not planned yet

**Rollover and rebalancing.** Optional: unused budget carries over, and the app suggests moving money from an unused category to an overspent one. Without a history of old limits, rollover uses today's limit.

**More ways to get a PDF receipt in (not decided).** Choosing a PDF or photo from the Files app is done (page 1 of a PDF is read; a password-protected PDF is refused). Two ideas remain:
- **Share a receipt to the app:** from the email app, Share and choose SpendWise IQ (PDF or image). It uses the same Android share-target code as M-Pesa capture, so build them together if both are done.
- **Read the text inside the PDF** instead of reading a picture of it. Emailed receipts usually contain real text, which is exact where OCR can slip; ML Kit is then only needed for scanned PDFs. Needs a PDF package that can extract text with positions.

**Ask what kind of file first, then open the matching picker (not decided, waiting for tester feedback).** The Files app is the system picker, so it looks and behaves differently across phone makers and Android versions. Idea: the Add sheet asks first, with three options: **Photo** (image_picker, the Android photo picker), **File or PDF** (file_selector, the Files app, as now), and **Camera** (direct photo, already built but switched off). Not a priority. Decide after testers try the single Choose a receipt file option on different phones.

**Own gallery picker, like WhatsApp's (no longer needed, and not recommended).** It would list every album in one place, but the cause above is PDFs, not the layout. It needs the broad photo permission (`READ_MEDIA_IMAGES`), and Google Play restricts that to apps whose main purpose is a gallery or photo manager; a custom picker does not qualify automatically and needs a declaration that the system picker is not enough, and an app that fails can be removed from Google Play. It also contradicts the app's promise that it only receives the photo the user chooses (the privacy policy says so), so the policy and Data safety form would change, and the permission prompt is a worse first impression for a privacy-first app. On top of that: thumbnail loading on low-memory phones, behavior differences between phone makers, and a package such as `photo_manager` to maintain (effort: large). Revisit only if sharing and "Choose a file" prove not enough.

**Split expenses and IOUs.** Goal: personal totals show what the user actually spent, and money lent to friends does not distort the budget. A first version: a "my share" amount on an expense (a new nullable column, empty meaning the full amount), and a simple list of who owes whom, which the user marks settled or part-paid (people and debts tables). The Summary, budgets, exports and the expense list would all use one shared "effective amount" rule, so no total is missed. Everything stays on the phone, so settling up is manual. The largest piece of work (effort: large), and the most valuable for chamas and lending.

**Share an M-Pesa message to the app.** Pasting works today. The next step is Share on the message and choose SpendWise IQ, which needs an Android share target (native code), and can be built together with sharing a receipt to the app. Parsing was written from the common English confirmations; real, sanitized samples (names and numbers removed) would help test it, including Fuliza and other shapes.

**More ways to capture.** App shortcuts feed the same pre-filled add-expense form as scanning, typing a line and M-Pesa capture, and nothing saves without the user checking it.

- **Typed quick add.** Type one line such as "lunch 350 cafe yesterday" and get the form filled in. A plain Dart parser finds the amount (including "1.5k"), the date words (today, yesterday, a weekday, "on 12 Nov") and the vendor after "at"; the rest becomes the title. The category comes from vendor memory, then the word list used for scanning. It guesses, so the form still shows. English only to start; Swahili words such as "jana" could be added. Effort: small to medium.
- **App shortcuts.** Long-press the app icon for "Add expense" or "Scan receipt", using the `quick_actions` package. If the app lock is on, the shortcut waits until the user unlocks and then continues. Android shows only a few shortcuts and launchers differ a little. A home-screen widget is a separate, larger job with native code. Effort: small.
- **Voice entry** is not planned: phone speech services can send audio to Google. If wanted, make it opt-in.

**More later ideas**

- **CSV import.** Bring expenses in from a spreadsheet or another app (backup and restore to a file is built; this is separate).
- Auto-open the converter when a scan sees "$" or "USD" in the receipt.
- A different currency on each expense (today one currency is used for all amounts, with the original amount kept on a converted expense).
- Optional receipt attachment.
- Change the iOS bundle id from `com.example.smartExpenseTracker` when iOS work starts.

## Parked: Play Store launch (not a goal for now)

1. **Release setup and early testers** (code done, your setup remains). The `dev`, `uat` and `main` flow is built: `uat` sends a build to Play internal testing and `main` sends one to production after approval (see [branching](branching.md) and [releasing](releasing.md)). Still needed: the GitHub secrets, a first internal release, and a **closed test with testers started early**, because new personal accounts have needed 12 testers for 14 days before production.

**Still to look at for export:** the PDF embeds the Inter font (`assets/fonts`), which covers Latin, Greek and Cyrillic. A vendor name in another script (Chinese, Arabic, and so on) would show as blank boxes in the PDF; the CSV is fine. Try the share sheet on a real phone before the first release. The privacy policy needs one line saying a report leaves the app only when the user shares it.

**Privacy and store forms (before the first public release):**
- Publish the privacy policy as a web page on Google Sites (not a PDF, not editable, public, no sign-in). The text is in [privacy-policy.md](privacy-policy.md), with an optional HTML version. Paste the text straight into the page rather than embedding it.
- The "Privacy policy" row under Settings, About is built (it opens the page in the browser). The published address is set in `lib/core/links/app_links.dart` (the row stays hidden if it is ever emptied); Google requires the link inside the app as well as in the Play listing.
- Data safety form: do not answer "no data collected". Google says ML Kit sends performance and usage metrics to Google, and the release app has the `INTERNET` permission because of it. Declare it as the form's questions require, and check the current form before submitting.
- Decide about device backups: `android:allowBackup` is not set, so Android may back the app's data up to the user's Google account. The policy says so. Setting it to `false` would keep expenses out of backups, at the cost of not restoring them on a new phone.
- Keep the policy, the Data safety form and the real behavior in step whenever something changes (for example when report export ships).

**Before the first public release:** remove the temporary OCR test screen (`lib/features/scan/debug/`, its route in `app_router.dart` and the Developer entry in Settings). On iOS, ML Kit needs two manual Xcode steps (linker flags and the Latin model bundle) that are not done yet; see the plugin's README.

Also for a public release: the Financial features declaration, a store listing with screenshots, and the Play Data safety form must mention the exchange-rate download (no personal data is sent).
