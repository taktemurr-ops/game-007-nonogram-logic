# Game 007 — Nonogram Logic

Original 160-stage offline nonogram puzzle built with Flutter. It includes 20
original bitmap drawings with 8 transformations each; taps, marked empty cells,
undo and redo; free reveal hint; local progress and save/restore; classic, daily,
timed, zen gameplay; Turkish / English / Arabic UI; settings and local-data
removal. No ad, payment, account or analytics SDK is enabled.

## Run

```sh
flutter create --platforms=android,ios --project-name game_007_nonogram_logic .
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug
```

`flutter create` generates the `android/` and `ios/` host directories for
this source-only repository. iOS verification additionally needs macOS + Xcode.

## Release status

**Not certified for a store release** until CI logs, emulator and physical
Android tests, signed iOS tests, privacy disclosures, accessibility checks,
icon/screenshots, and store signing are complete. Ads and purchases have not
been configured: they must not be described as implemented. See
`docs/RELEASE_READINESS.md` for all remaining verifications.

## Originality

All picture patterns are defined in `lib/game/nonogram_catalog.dart`; no
third-party artwork is copied. Commercial dependencies and branding require
separate review before release.
