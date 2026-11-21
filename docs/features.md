# Features

Everything the app does today, and what is still to come. The [README](../README.md) has the short version with screenshots. Status: [x] built.

## Built

- [x] Light and dark themes with a shared design system (colors, spacing, typography)
- [x] Welcome screen and a four-step introduction, shown once, with an optional first name on the last screen
- [x] Manual expense entry with validation (optional title and vendor), stored offline on the device
- [x] Expense list grouped by day, with daily totals and category names
- [x] Edit an expense, or delete it by swiping (with Undo) or from the edit screen
- [x] Categories you manage yourself: create, rename and delete (deleting moves the expenses to Other)
- [x] Add a category from the expense form with the New chip, without losing what you typed
- [x] Monthly summary: total and spending by category, with a month switcher
- [x] Settings: theme (system, light, dark) and About
- [x] Optional app lock with fingerprint, face or the phone's screen lock, turned on from Settings. If the phone can no longer check you, the lock screen offers to turn the lock off, so you are never locked out of your own data
- [x] Scan a receipt: take a photo with the camera or choose a photo or PDF, and the app reads the vendor, date and total on your phone, suggests a category, and fills the expense form for you to check before saving. The photo is temporary and is deleted afterwards
- [x] Export a month as a PDF report or a CSV spreadsheet from the Summary screen, shared or saved from the system share sheet. Nothing is uploaded by the app; the file goes only where you send it
- [x] Choose the currency amounts are shown in (it starts with the currency of the phone's country). Saved amounts are relabelled, not converted
- [x] Remember the category you use for each vendor, so the next expense or scan starts with it
- [x] Monthly budgets for each category and overall, with progress bars on the Summary that turn amber near the limit and red when passed
- [x] Recurring expenses and subscriptions, added automatically when they come due (weekly, monthly or yearly), with what they add up to each month. A "Repeat this expense" box on the add form turns a scanned or typed bill into one
- [x] Convert an amount in another currency with the latest daily rate (downloaded once a day, saved on the phone, rate and date shown)
- [x] "Safe to spend" on the Summary: an amount a day for the rest of the month, after spending so far and upcoming recurring bills (needs an overall budget)
- [x] Heads-up cards on the Summary: possible duplicate charge, unusually large expense, a category above a usual month (rules on the phone, nothing sent anywhere)
- [x] Back up everything to a file in your Downloads folder (optionally password-protected with AES-256) and restore it, with a confirmation that shows what is in the backup. If Android closes the app while the file is being chosen, the app says so and reopens the restore page
- [x] Delete all my data from Settings, with a backup reminder and a typed confirmation; the app then starts again as a fresh install
- [x] Tap a Summary category or budget to open the expenses behind it for that month
- [x] Search expenses by vendor or title and filter them by category, dates and amount
- [x] Type an expense in one line ("lunch 350 at Java yesterday"); a plain on-device parser fills in the form for you to check
- [x] Paste an M-Pesa confirmation message to fill in an expense (no SMS permission; the same message is not added twice)
- [x] A Home screen: greeting by name, this month against the budget with what is safe to spend, a bar chart of the year, the latest expenses and heads-up cards
- [x] Insights on the phone: this month against the same stretch of last month with the biggest change, a heads-up when a subscription changes price, and the budget as a line on the year chart
- [x] A nudge to set a budget for a category that is a big share of the month but has none

## Still to come

The build order, with the reasons for it, is in the [roadmap](roadmap.md). In short:

- Check the personas with five real people ([personas](personas.md))
- A sample-data mode for demos
- Income, savings goals, bill reminders and tags, which the personas asked for
- Later: split expenses, CSV import, app shortcuts, an app PIN
