# Releasing to Google Play

Pushing to `uat` sends a build to **internal testing**. Pushing to `main` sends a build to **production**, after you approve it. Pushing to `dev` sends nothing. Which branch to use when is in [branching.md](branching.md). This page is how the uploads work and how to set them up.

```
push to uat   ->  CI passes  ->  build  ->  fastlane internal    ->  Play internal testing
                                         +  GitHub pre-release with the APK
push to main  ->  CI passes  ->  you approve  ->  build  ->  fastlane production  ->  Play production (draft)
                                                          +  GitHub release with the APK (the latest)
```

## How the pieces fit

| Piece | File | Job |
|---|---|---|
| Signing config | `android/app/build.gradle.kts` | Signs the release build with your **upload key** when `android/key.properties` exists |
| Fastlane | `android/Gemfile`, `android/fastlane/` | Uploads the finished `.aab` to Play (lanes below). It does not build the app, Flutter does |
| CI | `.github/workflows/ci.yml` | Format, analysis, tests and coverage on pull requests into `dev`, `uat` and `main`, on pushes to `dev`, and when the release workflow calls it |
| Release | `.github/workflows/release.yml` | Runs on a push to `uat` or `main`. First job: CI. Then writes secrets to files, builds, runs Fastlane, and publishes the GitHub release |
| Dev build | `.github/workflows/dev-build.yml` | By hand: builds an APK for your own phone, uploads nothing to Play |

### Flavors

Two flavors keep builds from your computer apart from the Play app. Android will not update an app signed with a different key, which shows as "Can't install" in Play.

| Flavor | App id | Name on the phone | Used for |
| --- | --- | --- | --- |
| `dev` (the default) | `com.bornmajor.spendwiseiq.dev` | SpendWise IQ Dev | `flutter run`, `flutter run --release`, the manual dev-build workflow |
| `prod` | `com.bornmajor.spendwiseiq` | SpendWise IQ | Only the release workflow, for Play |

- Defined in `android/app/build.gradle.kts` (`productFlavors`). The default comes from `default-flavor: dev` in `pubspec.yaml`.
- The ids differ, so the two apps have separate data and can be installed together.
- The flavor is chosen by the build command, not by the branch. `uat` and `main` still go to Play because the release workflow passes `--flavor prod`.
- Fastlane picks up `build/app/outputs/bundle/prodRelease/app-prod-release.aab`.
- Later, a Firebase or Google sign-in setup would need one config per app id.

**The dev icon.** The dev app has a grey icon with a white "DEV" label, so it is never mistaken for the Play app. Its files live in `android/app/src/dev/res/` and override the main ones for that flavor only; `prod` keeps `android/app/src/main/res/`. To change it:
1. Edit `tool/make_dev_icon.ps1` (it recolors the production artwork and adds the label), then run `powershell -File tool/make_dev_icon.ps1`. It writes `assets/branding/dev/`.
2. Run `dart run flutter_launcher_icons`. The settings are in `flutter_launcher_icons-dev.yaml`.
3. Commit the changed files under `android/app/src/dev/` and `assets/branding/dev/`.

Without `key.properties` (a fresh clone), release builds fall back to the debug key so `flutter run --release` still works. Google Play rejects a debug-signed bundle, so that build can never be published by mistake.

### Fastlane lanes

| Lane | What it does |
|---|---|
| `internal` | Uploads the built bundle to the internal testing track |
| `production` | Uploads it to the production track as a **draft** (nothing reaches users until you press Roll out) |
| `promote` | Moves the latest release from one track to another **without rebuilding**: `bundle exec fastlane promote from:internal to:production` |
| `validate` | Checks the service account key without uploading |

One workflow serves both branches, so one run counter gives every upload a higher version code than the last. Play needs that across all tracks.

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
flutter build appbundle --release --flavor prod
```

Upload `build/app/outputs/bundle/prodRelease/app-prod-release.aab` under **Testing, Internal testing, Create new release**. Roll it out when Play allows it. The store listing and the other setup tasks Play shows (privacy policy, content rating, data safety) are also needed before the app goes beyond testing.

### 4. Create a service account for Fastlane

1. [Google Cloud Console](https://console.cloud.google.com/): create or pick a project, enable **Google Play Android Developer API**.
2. **IAM and admin, Service accounts, Create**. Then open it, **Keys, Add key, JSON**. A JSON file downloads.
3. Play Console, **Users and permissions, Invite new users**. Use the service account's email and give it access to this app with the permissions to **release to testing tracks** and **release to production**.

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

### 7. Create the branches (after this is merged into `main`)

The release workflow starts on a push to `uat` or `main` and is read from the branch that was pushed, so the default branch setting does not affect it. Create the branches from `main`, once this change is in it:

```bash
git checkout main
git pull
git branch dev
git branch uat
git push -u origin dev uat
```

Then, in GitHub:

1. **Settings, Branches, Default branch**: switch it to `dev`, so new pull requests target it.
2. **Settings, Rules** (or Branches, Add rule): for `dev`, `uat` and `main`, require a pull request and passing CI checks before merging.

### 8. Create the GitHub environments

**Settings, Environments, New environment**:

| Environment | Setup | Why |
|---|---|---|
| `internal` | Nothing to add | Used when `uat` is released |
| `production` | **Required reviewers**: add yourself | A production upload waits until you approve the run |

If you do limit them with "Deployment branches", allow `uat` for `internal` and `main` for `production`, or the release job will be blocked.

### 9. Optional repository variables

**Settings, Secrets and variables, Actions, Variables**. Without these, the safe defaults apply.

| Variable | Default | Meaning |
|---|---|---|
| `PLAY_INTERNAL_STATUS` | `completed` | Set to `draft` if Play says the app has never been published |
| `PLAY_PRODUCTION_STATUS` | `draft` | `draft` waits for you to press Roll out. `inprogress` rolls out by itself at the fraction below |
| `PLAY_PRODUCTION_ROLLOUT` | none | A fraction such as `0.1` for 10%. Only used with `inprogress` |

## Releasing

**To testers:** merge `dev` into `uat` (a merge commit, see [branching.md](branching.md)). CI runs and the build is uploaded to internal testing. Testers get it from the Play Store in minutes, and the same build appears on the GitHub Releases page as a pre-release.

**To production:**

1. Bump the version name in `pubspec.yaml` and update [CHANGELOG.md](../CHANGELOG.md), in a pull request through `dev` and `uat`.
2. Merge `uat` into `main`. CI runs, then the run waits for your approval in GitHub.
3. Approve it. The bundle is uploaded to production as a draft, and a tag such as `v1.2.0` and a GitHub release with the APK are created (see [GitHub release](#github-release-apk-download)).
4. In Play Console, open the draft, add "What's new", and press **Roll out**. Start with a small percentage.
5. Watch **Android vitals**, then raise the rollout. **Halt rollout** if something is wrong.

The [release checklist](release-checklist.md) has the full list.

A run also starts by hand from the **Actions** tab, on `uat` or `main` only. CI still runs first.

**For your own phone:** **Actions, Dev build, Run workflow**, on any branch. It builds an APK you can download for a week and uploads nothing to Play. It is signed with the debug key, so uninstall the Play version first.

### GitHub release (APK download)

The repository is public, so the **Releases** page lets anyone download the app without Google Play:
- **`main` (production):** a release such as `v1.2.0`, marked as the **Latest**. This is what the README's download link points to.
- **`uat` (testing):** a **pre-release** such as `v1.2.0-uat.123`, named with the workflow run number. Each `uat` push gets its own, so earlier test builds stay downloadable. It is marked "Pre-release", so it never becomes the Latest.

What the release workflow does, in order:
1. Builds the `prod` bundle for Play, then also a `prod` **APK**, with the same code, signing key and build number. This happens before anything is uploaded to Play, so a failure here leaves Play untouched and the run can simply be started again.
2. Checks the APK is signed with the upload key. It stops the run if it finds the debug key, because a debug-signed file is not safe to publish.
3. Writes `spendwise-iq-<version>.apk`, a `.sha256` checksum, and the release text. The text is the [CHANGELOG.md](../CHANGELOG.md) section headed `## [<version>]`, followed by install steps. If that heading does not exist yet it uses `## [Unreleased]`, so rename Unreleased to the version when you bump it (step 1 above).
4. After the Play upload (and, for `main`, your approval), the `publish` job creates the release or pre-release with those files. A `uat` pre-release starts with a note saying it is a test build.

Good to know:
- A run started again on a release that already exists keeps its text and just re-attaches the files.
- The files are also kept as a **workflow artifact** for two weeks (Actions, the run, Artifacts), which is how the build job hands them to the publish job.
- Pre-releases pile up. Delete old ones from the Releases page when you like; it does not affect Play.
- The APK is signed with the upload key but Play signs its copy with its own key, so a phone can have one or the other. The release text says so. To test the Play build, install it from Play.
- Nobody outside the project can use your secrets: the workflow only runs on pushes to `uat` and `main`, not on forks or pull requests.
- To change the notes, edit the changelog before merging to `main`. To fix a published release, edit it on GitHub.

To rehearse the release text on your computer: `dart run tool/release_notes.dart 1.0.0 notes.md`, then open `notes.md`.

### Version numbers

The version name comes from `pubspec.yaml`. The build number is replaced by `run number + 100`, because Play needs a higher version code for every upload and the run number only goes up. You never bump the `+N` part yourself.

### Same build to production (optional)

A merge into `main` builds again from the same source. To send the **exact** build testers used, promote it instead:

```bash
cd android
PLAY_JSON_KEY_FILE=play-service-account.json bundle exec fastlane promote from:internal to:production
```

Fastlane needs Ruby, which is awkward on Windows. It works in WSL or any Linux or Mac shell.

### Promote from GitHub, with no Ruby on your machine

The **Promote on Google Play** workflow does the same thing from the Actions tab (Run workflow). Pick the tracks:

- `internal` to `alpha` sends the internal build to closed testing (closed testing is called `alpha` in the Play API).
- `alpha` to `production` sends the closed-testing build to production. It waits for your approval, and is a draft until you press Roll out, unless `PLAY_PRODUCTION_STATUS` says otherwise.

Nothing is built again, so testers get the same file and version code. If the closed track has a different name in Play Console (a custom closed track), use that track's name in `android/fastlane/Fastfile` instead of `alpha`.

## First production release

Google has required new personal developer accounts to run a **closed test with at least 12 testers for 14 days** before they can apply for production access. Check the current rules in Play Console, because Google changes them. Start the closed test early. Production also needs the store listing, privacy policy, content rating and data safety form to be complete, and the first review can take days.

Until production access is granted, `main` uploads to the production track will be refused. Keep releasing to `uat` meanwhile.

## Troubleshooting

- **"Missing repository secret ..."**: add that secret (step 6).
- **A `uat` or `main` push did nothing**: the release workflow starts on the push itself and runs CI first, so a failed CI stops it. Open the run in the Actions tab and look at the `CI` job. Pull requests never release. The workflow file used is the one on the branch you pushed.
- **"Only releases with status draft may be created on draft app"**: the app has never been published. Set the variable `PLAY_INTERNAL_STATUS` to `draft` (step 9), then roll the release out in Play Console.
- **"Version code ... has already been used"**: start the workflow again with **Run workflow**, which gets a new run number (re-running the same run keeps its number), or raise the offset in `release.yml`.
- **Permission or 403 errors from Google**: the service account is missing app access in Play Console (step 4), or it is too soon after granting it.
- **The production run never starts**: it is waiting for your approval. Open the run in GitHub and review the deployment.
- **Check the key without uploading**: run `bundle exec fastlane validate` from `android/` with `PLAY_JSON_KEY_FILE` set.
