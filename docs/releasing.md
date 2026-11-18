# Releasing to Google Play

Pushing to `uat` sends a build to **internal testing**. Pushing to `main` sends a build to **production**, after you approve it. Pushing to `dev` sends nothing. Which branch to use when is in [branching.md](branching.md). This page is how the uploads work and how to set them up.

```
push to uat   ->  CI passes  ->  build  ->  fastlane internal    ->  Play internal testing
push to main  ->  CI passes  ->  you approve  ->  build  ->  fastlane production  ->  Play production (draft)
```

## How the pieces fit

| Piece | File | Job |
|---|---|---|
| Signing config | `android/app/build.gradle.kts` | Signs the release build with your **upload key** when `android/key.properties` exists |
| Fastlane | `android/Gemfile`, `android/fastlane/` | Uploads the finished `.aab` to Play (lanes below). It does not build the app, Flutter does |
| CI | `.github/workflows/ci.yml` | Format, analysis, tests and coverage on pull requests and pushes to `dev`, `uat` and `main` |
| Release | `.github/workflows/release.yml` | After CI passes on `uat` or `main`: writes secrets to files, builds, runs Fastlane, and tags production releases |
| Dev build | `.github/workflows/dev-build.yml` | By hand: builds an APK for your own phone, uploads nothing to Play |

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
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` under **Testing, Internal testing, Create new release**. Roll it out when Play allows it. The store listing and the other setup tasks Play shows (privacy policy, content rating, data safety) are also needed before the app goes beyond testing.

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

The release workflow runs from the default branch, so `dev` and `uat` must carry the same workflow files. Create them from `main`, once this change is in it:

```bash
git checkout main
git pull
git branch dev
git branch uat
git push -u origin dev uat
```

Then, in GitHub:

1. **Settings, Branches, Default branch**: switch it to `dev`.
2. **Settings, Rules** (or Branches, Add rule): for `dev`, `uat` and `main`, require a pull request and passing CI checks before merging.

### 8. Create the GitHub environments

**Settings, Environments, New environment**:

| Environment | Setup | Why |
|---|---|---|
| `internal` | Nothing to add | Used when `uat` is released |
| `production` | **Required reviewers**: add yourself | A production upload waits until you approve the run |

Do not limit them with "Deployment branches". Automatic runs start from the default branch, so such a limit would block them.

### 9. Optional repository variables

**Settings, Secrets and variables, Actions, Variables**. Without these, the safe defaults apply.

| Variable | Default | Meaning |
|---|---|---|
| `PLAY_INTERNAL_STATUS` | `completed` | Set to `draft` if Play says the app has never been published |
| `PLAY_PRODUCTION_STATUS` | `draft` | `draft` waits for you to press Roll out. `inprogress` rolls out by itself at the fraction below |
| `PLAY_PRODUCTION_ROLLOUT` | none | A fraction such as `0.1` for 10%. Only used with `inprogress` |

## Releasing

**To testers:** merge `dev` into `uat` (a merge commit, see [branching.md](branching.md)). CI runs and the build is uploaded to internal testing. Testers get it from the Play Store in minutes.

**To production:**

1. Bump the version name in `pubspec.yaml` and update [CHANGELOG.md](../CHANGELOG.md), in a pull request through `dev` and `uat`.
2. Merge `uat` into `main`. CI runs, then the run waits for your approval in GitHub.
3. Approve it. The bundle is uploaded to production as a draft, and a tag such as `v1.2.0` and a GitHub release are created.
4. In Play Console, open the draft, add "What's new", and press **Roll out**. Start with a small percentage.
5. Watch **Android vitals**, then raise the rollout. **Halt rollout** if something is wrong.

The [release checklist](release-checklist.md) has the full list.

A run also starts by hand from the **Actions** tab, on `uat` or `main` only. It does not wait for CI, so use it with care.

**For your own phone:** **Actions, Dev build, Run workflow**, on any branch. It builds an APK you can download for a week and uploads nothing to Play. It is signed with the debug key, so uninstall the Play version first.

### Version numbers

The version name comes from `pubspec.yaml`. The build number is replaced by `run number + 100`, because Play needs a higher version code for every upload and the run number only goes up. You never bump the `+N` part yourself.

### Same build to production (optional)

A merge into `main` builds again from the same source. To send the **exact** build testers used, promote it instead:

```bash
cd android
PLAY_JSON_KEY_FILE=play-service-account.json bundle exec fastlane promote from:internal to:production
```

Fastlane needs Ruby, which is awkward on Windows. It works in WSL or any Linux or Mac shell.

## First production release

Google has required new personal developer accounts to run a **closed test with at least 12 testers for 14 days** before they can apply for production access. Check the current rules in Play Console, because Google changes them. Start the closed test early. Production also needs the store listing, privacy policy, content rating and data safety form to be complete, and the first review can take days.

Until production access is granted, `main` uploads to the production track will be refused. Keep releasing to `uat` meanwhile.

## Troubleshooting

- **"Missing repository secret ..."**: add that secret (step 6).
- **A `uat` or `main` push did nothing**: the release workflow only runs after CI succeeds, and only for pushes, not pull requests. Check that CI passed, and that the workflow file is on the default branch (step 7).
- **"Only releases with status draft may be created on draft app"**: the app has never been published. Set the variable `PLAY_INTERNAL_STATUS` to `draft` (step 9), then roll the release out in Play Console.
- **"Version code ... has already been used"**: re-run the workflow, which gets a new run number, or raise the offset in `release.yml`.
- **Permission or 403 errors from Google**: the service account is missing app access in Play Console (step 4), or it is too soon after granting it.
- **The production run never starts**: it is waiting for your approval. Open the run in GitHub and review the deployment.
- **Check the key without uploading**: run `bundle exec fastlane validate` from `android/` with `PLAY_JSON_KEY_FILE` set.
