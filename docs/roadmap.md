# Roadmap and TODO

What is planned, in the order we intend to build it. Items move to the README feature list as they ship. Anything never built is deleted before release.

## Up next

1. **Release pipeline and early testers** (code done, setup in progress). Fastlane run from GitHub Actions, release signing, and uploads to the Google Play internal testing track after CI passes on `main`. Still needed: GitHub secrets, the first manual upload, and testers. Start a closed test early.
2. **Category management.** Create, rename and delete categories (name required and unique; deleting moves expenses to "Other").
3. **Optional receipt scanning.** Camera or gallery, on-device OCR, a receipt parser and category suggestion, filling the same expense form. Manual entry always keeps working.
4. **Monthly report export.** PDF and CSV for a month, shared or saved from the system share sheet.

**Done recently:** onboarding redesign, safe-area fixes, color-coded snackbars, and the expense loop (edit, delete with undo, list grouped by day with category names).

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

- Budgets with progress and alerts.
- Search and filters.
- More charts.
- Recurring expenses.
- Multi-currency.
- Optional receipt attachment.
- Bundle the Inter font.
- Change the iOS bundle id from `com.example.smartExpenseTracker` when iOS work starts.
