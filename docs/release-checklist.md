# Release checklist

## Before merging `dev` into `uat` (internal testing)

- [ ] CI is green on `dev`
- [ ] Version name in `pubspec.yaml` is right (bump it if this starts a new release)
- [ ] `CHANGELOG.md` lists what users will notice

## Before merging `uat` into `main` (production)

- [ ] Testers have used the build and found no blocking problems
- [ ] Tried on a real phone: first launch, add, edit and delete an expense, categories, biometric lock, dark theme
- [ ] Upgrade checked: install the previous version first, then update, and make sure the data is still there
- [ ] `CHANGELOG.md` has a dated entry for this version
- [ ] Privacy policy page is published (public, no sign-in, opens when signed out), its address is set in `lib/core/links/app_links.dart` and in the Play listing, and **Settings, About, Privacy policy** opens it on a real phone
- [ ] The published policy, the Play Data safety form and what the app really does all agree (ML Kit usage metrics, backups, exported reports)
- [ ] Store listing is current: description, screenshots, feature graphic
- [ ] "What's new" text is ready to paste in Play Console

## After the production upload

- [ ] Approve the run in GitHub when it asks
- [ ] In Play Console, open the draft release, add "What's new", and roll out (start small, for example 10%)
- [ ] Watch crashes and ANRs under **Quality, Android vitals** for a day
- [ ] Raise the rollout step by step to 100%, or **Halt rollout** if something is wrong
- [ ] Check the `vX.Y.Z` tag and GitHub release were created
