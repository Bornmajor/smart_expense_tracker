# Releasing to Google Play

Pushing a version tag builds a signed app bundle in GitHub Actions and uploads it to the **internal testing** track with [Fastlane](https://docs.fastlane.tools/). Testers get the update from the Play Store.

```
git tag v0.1.0  ->  GitHub Actions  ->  flutter build appbundle  ->  fastlane internal  ->  Play internal testing
```

## How the pieces fit

| Piece | File | Job |
|---|---|---|
| Signing config | `android/app/build.gradle.kts` | Signs the release build with your **upload key** when `android/key.properties` exists |
| Fastlane | `android/Gemfile`, `android/fastlane/` | Uploads the finished `.aab` to Play. It does not build the app, Flutter does |
| Workflow | `.github/workflows/release.yml` | Writes secrets to files, builds, then runs Fastlane |

Without `key.properties` (a fresh clone), release builds fall back to the debug key so `flutter run --release` still works. Google Play rejects a debug-signed bundle, so that build can never be published by mistake.

## One-time setup (you do this)

### 1. Create the upload key

Run once, keep the file and passwords safe, and never commit them (`*.jks` and `key.properties` are git-ignored).

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`keytool` ships with the JDK that comes with Android Studio. Back the file up somewhere private, for example a password manager. Play App Signing keeps the real app-signing key, so a lost upload key can be reset through Play support, but it is slow.

To build a signed bundle on your own machine, copy `android/key.properties.example` to `android/key.properties`, fill it in, and put `upload-keystore.jks` in `android/`.

### 2. Create the app in Play Console

1. Play Console, **Create app**: name SpendWise IQ, default language, App (not game), Free.
2. Accept the declarations.
3. Choose **Play App Signing** when asked (the default).

### 3. Upload the first bundle by hand

The Play API only works after the app has had at least one upload through the console.

```bash
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` under **Testing, Internal testing, Create new release**. Roll it out when Play allows it. The store listing and the other setup tasks Play shows (privacy policy, content rating, data safety) are also needed before the app goes beyond testing.

### 4. Create a service account for Fastlane

1. [Google Cloud Console](https://console.cloud.google.com/): create or pick a project, enable **Google Play Android Developer API**.
2. **IAM and admin, Service accounts, Create**. Then open it, **Keys, Add key, JSON**. A JSON file downloads.
3. Play Console, **Users and permissions, Invite new users**. Use the service account's email and give it access to this app with the permission to **release to testing tracks**.

Permissions can take a while to take effect.

### 5. Add the testers

Play Console, **Testing, Internal testing, Testers**: create an email list and add the Gmail addresses. Share the **opt-in link** with them. Internal testing allows up to 100 testers and updates reach them in minutes.

### 6. Add the GitHub secrets

Repository **Settings, Secrets and variables, Actions, New repository secret**:

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | The keystore encoded as one line of text (command below) |
| `ANDROID_KEYSTORE_PASSWORD` | The keystore password |
| `ANDROID_KEY_ALIAS` | `upload` (the alias from step 1) |
| `ANDROID_KEY_PASSWORD` | The key password |
| `PLAY_SERVICE_ACCOUNT_JSON` | The full contents of the service account JSON file |

Encode the keystore on Windows (PowerShell) and paste the result into the secret:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
```

## Releasing

1. Set the user-facing version in `pubspec.yaml`, for example `version: 1.0.0+1`. The part before `+` is the version name testers see.
2. Merge to `main`, then tag and push:

```bash
git tag v1.0.0
git push origin v1.0.0
```

You can also run the workflow by hand from the **Actions** tab.

The workflow replaces the build number with `run number + 100`, because Play needs a higher version code for every upload and the run number only goes up. You do not need to bump the `+N` part yourself.

## Troubleshooting

- **"Missing repository secret ..."**: add that secret (step 6).
- **"Only releases with status draft may be created on draft app"**: the app has never been published. Set the environment variable `PLAY_RELEASE_STATUS` to `draft` in the workflow, then roll the release out in Play Console. Switch back later.
- **"Version code ... has already been used"**: re-run the workflow, which gets a new run number, or raise the offset in `release.yml`.
- **Permission or 403 errors from Google**: the service account is missing app access in Play Console (step 4), or it is too soon after granting it.
- **Check the key without uploading**: run `bundle exec fastlane validate` from `android/` with `PLAY_JSON_KEY_FILE` set. Fastlane needs Ruby, which is awkward on Windows, so running it in CI is easier.

## Later: production

New personal developer accounts must usually run a **closed test with at least 12 testers for 14 days** before they can apply for production access. Check the current rules in Play Console, because Google changes them. Start the closed test early. Fastlane can target it by changing `track` in the `Fastfile`.
