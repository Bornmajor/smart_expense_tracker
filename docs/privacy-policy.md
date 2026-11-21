# SpendWise IQ Privacy Policy

**Effective date:** 18 November 2026
**App:** SpendWise IQ (Android)
**Developer:** [DEVELOPER NAME]
**Contact:** [CONTACT EMAIL]

> This is the text for the public privacy policy page (Google Sites). Replace the two placeholders above, update the effective date when you publish, and keep this file and the published page in step. See `docs/roadmap.md` for what must be checked before the first release.

## The short version

- SpendWise IQ has no accounts and no sign-in.
- Your expenses stay on your phone. The developer does not receive them, and the app does not upload them.
- Receipt photos are read on your phone and then deleted.
- There are no ads, no tracking and no selling of data.
- The app downloads public exchange rates once a day to convert amounts. No personal data is sent for this.
- One part of the app, Google's ML Kit text reader, may send anonymous performance information to Google. Details are in "Google components" below.

## What the app stores on your phone

SpendWise IQ keeps the following in its own private storage on your phone:

- your expenses: amount, date, vendor, an optional title, and the category
- the categories you create or rename
- your settings: the theme, whether the biometric lock is on, and whether you have finished the introduction

Other apps cannot read this storage. The developer cannot see it.

## What the app does not collect

SpendWise IQ does not ask for or collect your name, email address, phone number, location, contacts or microphone. It has no analytics, no advertising identifier and no user account. The app does not ask for permission to use your camera, contacts, location or files.

## Receipt photos

When you choose a photo or a PDF of a receipt, the app receives only that file, through Android's file picker. For a PDF it draws the first page as a picture. It reads the text in the picture on your phone, using Google's ML Kit on-device text recognition, and fills in the expense form for you to check.

The picture the app reads is a temporary copy. It is deleted when you close the form, whether or not you saved the expense, and it is also deleted if reading the photo fails. The app does not upload the photo or the text it reads. Only what you save in the expense is kept.

## Exchange rates

When you enter an amount in another currency, the app converts it using exchange rates. It downloads the rates from a public service, ExchangeRate-API, at most once a day, and keeps them on your phone so conversion works offline. The request contains no expenses, amounts or personal details. Like any website, the service can see your device's IP address. If you never use another currency, the rates are still downloaded in the background, but nothing about you is sent.

## Backup files you create

You can save everything in the app (expenses, categories, budgets and recurring expenses) to one backup file, and restore from it later. The file is made on your phone and handed to Android's share sheet. It goes only where you choose to send it, such as your Google Drive. The app does not upload it, and the developer does not receive it. You can lock the file with a password; it is then encrypted on your phone (AES-256), and if you forget the password nobody, including the developer, can open it. Restoring replaces what is on the phone with the contents of the file, after you confirm.

## M-Pesa messages you paste

You can paste an M-Pesa confirmation message to fill in an expense. The app does not read your text messages and has no permission to do so: a message is only used when you copy and paste it yourself. It is read on your phone to find the amount, who was paid and the date, and the message text is not kept. Only what you save in the expense is stored, together with the M-Pesa transaction code, so the same message is not added twice. Nothing is uploaded.

## Exporting reports

You can export a month of your expenses as a PDF or a CSV file. The file is made on your phone and handed to Android's share sheet. It goes only where you choose to send it, such as your Google Drive or a message to someone. The app does not upload it, and the developer does not receive it.

## Biometric lock

You can turn on a fingerprint or face lock. It uses your phone's own system. The app only learns whether the check passed. It never receives, stores or sends your fingerprint or face data.

## Google components

**ML Kit (text recognition).** The text reading happens on your phone. Google states that ML Kit does not send the images or the recognized text to Google's servers. ML Kit can still contact Google, for example to get fixes and updates, and it sends performance and usage information about itself to Google, such as whether reading worked and how long it took. For this reason the app has permission to use the network. The app's own code does not send your data anywhere. You can read Google's description at https://developers.google.com/ml-kit/terms.

**Google Play.** If you installed the app from Google Play, Google provides the download and, if you have allowed it in your device settings, may give the developer anonymous crash and performance reports.

## Backups

If device backup is turned on, Android may include the app's data in your phone's backup to your Google account. This is controlled by your phone's settings and by Google's backup service. The developer has no access to it. You can turn backups off in your phone's settings.

## Keeping and deleting your data

Your data stays on your phone until you remove it. You can delete expenses and categories inside the app, or everything at once with "Delete all my data" in Settings, which also puts the settings back to the start. It is deleted from your phone at once and cannot be undone; the developer has no copy to delete because nothing is uploaded. Backup files you made earlier, and anything you shared, stay where you saved them until you delete them yourself. Uninstalling the app removes all the data it stored on your phone. Copies in a device backup are separate and are managed in your Google account settings.

## Sharing and selling

The developer does not sell or share your personal data. The developer does not receive it in the first place.

## Children

SpendWise IQ is not directed at children under 13, and the developer does not knowingly collect information from children.

## Changes to this policy

If the app changes in a way that affects your privacy, this page will be updated and the effective date above will change. Significant changes will also be mentioned in the update notes in Google Play.

## Contact

Questions about this policy: [CONTACT EMAIL]
