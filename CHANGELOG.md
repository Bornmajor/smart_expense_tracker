# Changelog

What changed for users, newest first. The format follows [Keep a Changelog](https://keepachangelog.com/), and versions follow [semantic versioning](https://semver.org/).

Add entries under **Unreleased** as you merge into `dev`. When a release goes to production, rename that section to the version and date, and start a new empty **Unreleased**.

## [Unreleased]

First release. Nothing has been published to Google Play yet.

### Added

- Welcome screen and a three-step introduction, shown once
- Add expenses by hand with an amount, date, category, and an optional title and vendor
- Scan a receipt: choose a photo and the vendor, date, total and a likely category are read on your phone and filled into the expense form for you to check. Nothing is uploaded, and the photo is deleted afterwards
- Edit an expense, and delete it by swiping (with Undo) or from the edit screen
- Expenses grouped by day, with a total for each day and the category name on every row
- Monthly summary with the total and spending by category, and a month switcher
- Export a month as a PDF report or a CSV spreadsheet from the Summary screen, and share or save it from the system share sheet
- Categories you manage yourself: create, rename and delete. Deleting a category moves its expenses to Other
- A New chip on the expense form to add a category without leaving the form
- Light, dark and system themes
- Optional fingerprint or face lock, turned on from Settings
- Color-coded messages for success, warnings and errors
- Everything is stored on the phone and works offline, with no account
- A downloadable APK on the GitHub Releases page, for installing without Google Play
- A Privacy policy link under Settings, About
- Choose the currency amounts are shown in, from Settings (it starts with the currency of your country)
- The category you use for a vendor is remembered, and suggested the next time you scan or type that vendor
- The app lock works on phones that only have a screen lock, and never leaves you locked out: if the phone can no longer check it's you, the lock screen explains why and offers to turn the lock off
- Monthly budgets: set a limit for each category and one for everything, and see on the Summary how much of each you have used. The bar turns amber near the limit and red once it is passed
