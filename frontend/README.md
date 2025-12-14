# dBiller (Flutter)

Point-of-sale app with inventory, billing, and image-based item recognition (OCR).

## Tech stack
- Flutter + Riverpod + GoRouter
- Dio HTTP client
- Image Picker + Camera + File Picker

## Setup
1) Install Flutter (stable channel) and Android Studio / Xcode toolchains.
2) Install dependencies:
   ```bash
   flutter pub get
   ```
3) Configure API base URLs in `lib/core/config.dart` and environment entrypoints:
   - `lib/main_dev.dart` for local/dev
   - `lib/main_prod.dart` for production (update `apiBaseUrl` to your server).

## App name and IDs
- Android app id: `com.dbiller.app`
- Web title/name: `dBiller`

## Assets
- App/logo: `assets/logo.png` (launcher icons generated via `flutter_launcher_icons`).

## Build commands
- Android AAB (Play):  
  ```bash
  flutter build appbundle --release --target lib/main_prod.dart
  ```
- Android APK (split per ABI):  
  ```bash
  flutter build apk --release --split-per-abi --target lib/main_prod.dart
  ```
- Web (release):  
  ```bash
  flutter build web --release --target lib/main_prod.dart
  ```

## Signing (Android)
- Keystore path: `android/app/release.keystore`
- Config file: `android/key.properties`  
  ```
  storePassword=<store_pass>
  keyPassword=<key_pass>
  keyAlias=dbiller
  storeFile=release.keystore
  ```

## CI
GitHub Actions workflow: `.github/workflows/flutter-build.yml`
- Builds AAB, split APKs, and web on push to `main`.
- Set secrets: `ANDROID_KEYSTORE_B64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`.

## Privacy
See `PRIVACY_POLICY.md`.
