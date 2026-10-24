# Mobile

Flutter app, Android only for now. Run commands from `mobile/` unless noted.

## Setup

1. Install Flutter **3.47.7** (stable). Use exactly this version: CI uses it, and other versions can format code differently.
2. Install Android Studio, or the Android command-line tools.
3. Run `flutter doctor` until everything is green (iOS and web items don't matter).
4. Start an emulator or connect a phone with USB debugging on.

```bash
cp config.example.json config.json
flutter pub get
flutter run --dart-define-from-file=config.json
```

Start the backend first (see `backend/README.md`). The home screen says whether the app reached the backend's `/health`.

## Config

`config.json` holds the backend address and is not committed. Without it, the app stops at startup with an error.

- **Emulator:** keep `http://10.0.2.2:8000`. The emulator reaches your computer at `10.0.2.2`, not `localhost`.
- **Real phone:** use your computer's local network IP, for example `http://192.168.1.20:8000`. The phone and computer must be on the same Wi-Fi, and the backend must listen on all addresses:

  ```bash
  uv run uvicorn ghbot.main:create_app --factory --reload --host 0.0.0.0
  ```

  > **Warning:** this exposes the dev server, including `/dev/token`, to everyone on the network. Only do it on a network you trust.

Debug builds allow plain HTTP for this. Release builds don't.

## Text and layout

- No user-facing text in Dart code. Add each string to `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb`, then use it through `AppLocalizations.of(context)!`. `flutter pub get` or `flutter run` regenerates the Dart files next to them.
- The app uses the first supported language (English or Arabic) in the phone's ordered preferences. If none matches or the list is empty, it uses English.
- Arabic is right to left. Use start/end (`EdgeInsetsDirectional`, `AlignmentDirectional`), never left/right.

## Checks

CI runs these on every PR that changes `mobile/`.

```bash
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
```

## Dependencies

Add one with `flutter pub add <package>` (or `flutter pub add --dev <package>` for tools). Commit `pubspec.yaml` and `pubspec.lock` together.
