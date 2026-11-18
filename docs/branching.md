# Branching and versioning

Three long-lived branches, each one a stage. Code only moves forward through them.

```
feature/*  --PR-->  dev  --PR-->  uat  --PR-->  main
                     |             |             |
                  CI only      Play internal   Play production
                (no upload)    testing         (you approve first)
```

| Branch | What it is | What a push does |
|---|---|---|
| `dev` | Where everyday work lands. May be rough | CI only (format, analysis, tests, coverage). Nothing is uploaded, so no tester is notified |
| `uat` | A build ready for testers | CI, then the app is uploaded to the **internal testing** track |
| `main` | What users get | CI, then (after you approve) the app is uploaded to the **production** track |

How uploads work is in [releasing.md](releasing.md).

## Daily flow

1. Start from `dev`: `git checkout dev && git pull && git checkout -b feat/my-change`.
2. Open a pull request into `dev`. **Squash and merge** is fine here.
3. Repeat. Batch many small changes in `dev`. Testers hear nothing.
4. When you want testing: open a pull request from `dev` into `uat` and **merge** it (see the rule below). Testers get the update from the Play Store.
5. When testing is happy: open a pull request from `uat` into `main` and **merge** it. Approve the production run in GitHub. Press **Roll out** in Play Console when the release is ready.

## Rules that keep three branches painless

- **Promote with a merge commit, never squash.** A squash rewrites history, so `dev`, `uat` and `main` drift apart and later pull requests show fake conflicts. Use "Create a merge commit" for `dev` to `uat` and `uat` to `main`. Squash only feature branches into `dev`.
- **Only promote forward.** Never commit straight to `uat` or `main`.
- **Protect all three branches:** require a pull request and passing CI before merging.
- **Keep the workflow files identical on all three.** They travel with every promotion, so this happens by itself.
- **`dev` is the default branch**, so new pull requests target it.

## Versioning

- **Version name** (`1.2.0`, what users see): [semantic versioning](https://semver.org/) in `pubspec.yaml`. Patch for fixes, minor for new features, major for big changes. Bump it in the pull request that starts a release.
- **Version code** (the number after `+`): Play needs a higher one for every upload. CI sets it from the run number of the single release workflow, so you never touch it.
- **Tags:** a production upload creates a tag such as `v1.2.0` and a GitHub release with generated notes. If the tag exists, it is left alone.
- **Changelog:** keep [CHANGELOG.md](../CHANGELOG.md) up to date with what users will notice.

## Hotfixes

A serious bug in production:

1. Branch `hotfix/short-name` from `main`, fix it, and open a pull request into `main`.
2. Merge it, approve the release, and roll it out.
3. Merge `main` back into `dev` and `uat`, so the fix is not lost.
