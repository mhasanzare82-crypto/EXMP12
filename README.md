# Working

A Persian-first activity tracker built with Flutter.

## Features

- Create and manage named activities.
- Record numeric counts with local date and time.
- View per-activity history and totals.
- Display dates in the Jalali calendar and Persian digits.
- Export records as UTF-8 CSV and share the report.
- Store data locally on the device; no account or backend is required.

## Development

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

## Architecture

The codebase uses a feature-first structure. See [ARCHITECTURE.md](ARCHITECTURE.md) for layer boundaries and responsibilities.

## Android release

Pushes and pull requests targeting `main` run formatting, static analysis, tests, and a release APK build. The APK is uploaded as a GitHub Actions artifact when the workflow succeeds.
