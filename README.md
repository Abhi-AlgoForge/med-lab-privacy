# MedLab - Medicine App with AI Analysis

A comprehensive Flutter medicine identification and medication reminder app with Gemini AI integration.

## Features

### 1. Medicine Identification
- Take photos of medicine tablets or scan from gallery
- AI-powered analysis using Gemini shows:
  - Medicine name (brand and generic)
  - Chemical contents / active ingredients
  - General use and purpose
  - Harmful content warnings with caution icons
  - Age-specific precautions
  - Drug interaction warnings against previously scanned medicines

### 2. Medication Reminders
- **Manual Entry**: Add medicines with custom timing
- **Prescription Scanning**: AI reads prescriptions to create reminders automatically
- Schedule reminders for Morning, Afternoon, or Night, before or after eating
- Exact-alarm scheduling so reminders fire on time even under Doze
- Toggle reminders on/off; swipe to delete

### 3. Bill Analysis
- Scan medical / pharmacy bills
- AI flags overcharges, double-charges, unnecessary items

### 4. User Profile + Dose Tracking
- One-time profile collects name, age, weight, height, meal times
- Streak calendar + dose history

### 5. Monetization
- Free tier: 3 scans/day with interstitial ads
- Pro (monthly subscription): unlimited scans, no ads

## Setup

### Prerequisites
- Flutter SDK (latest stable, SDK ^3.9.2)
- Android Studio / Xcode for mobile development
- A Firebase project with Remote Config enabled
- A Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)

### Installation

1. **Clone the repo & install deps**
   ```bash
   flutter pub get
   ```

2. **Provide the Gemini API key** — the code does NOT hardcode it. There are two paths:

   - **Build-time fallback** via `--dart-define`:
     ```bash
     flutter run --dart-define=GEMINI_API_KEY=your-key-here
     ```
   - **Runtime override** via Firebase Remote Config: set a parameter named
     `gemini_api_key` in the Firebase Remote Config console. The app fetches
     it at startup so you can rotate keys without shipping an update.

3. **Drop `google-services.json` into `android/app/`** (download from your
   Firebase project). Already gitignored.

4. **Android signing** — copy `android/key.properties.example` (if present)
   to `android/key.properties` and point it at your release keystore:
   ```
   storeFile=/absolute/path/to/medlab-release.jks
   storePassword=<strong-password>
   keyAlias=<alias>
   keyPassword=<strong-password>
   ```
   `key.properties` and `*.jks` are both gitignored.

5. **Run in development**
   ```bash
   flutter run --dart-define=GEMINI_API_KEY=your-key-here
   ```

6. **Build a release App Bundle** (Play Store requires AAB, not APK):
   ```bash
   flutter build appbundle --release \
     --dart-define=GEMINI_API_KEY=your-key-here \
     --obfuscate \
     --split-debug-info=build/symbols
   ```
   The bundle lands in `build/app/outputs/bundle/release/app-release.aab`.
   Upload `build/symbols/` to Play Console too so crash stacks de-obfuscate.

## Project Structure

```
lib/
├── main.dart                      # Entry point + splash + routing
├── theme/app_theme.dart           # Light + dark theme tokens
├── models/                        # Plain Dart data classes
├── services/
│   ├── gemini_service.dart        # Gemini API calls + drug-interaction checks
│   ├── storage_service.dart       # Local persistence (SharedPreferences)
│   ├── notification_service.dart  # Reminders via flutter_local_notifications
│   ├── subscription_service.dart  # IAP + Pro entitlement
│   ├── ad_service.dart            # AdMob interstitials (Pro suppresses)
│   └── report_service.dart        # Share bill / medicine reports
├── widgets/                       # Reusable UI building blocks
└── screens/
    ├── onboarding/                # First-launch intro
    ├── profile/                   # Profile setup + profile screen
    ├── home/                      # Bottom-nav hub
    ├── medicine_scanner/          # Camera + medicine + bill analysis + chat
    ├── bill_scanner/              # Bill result view
    ├── reminders/                 # Manual / scan add + list + streak calendar
    ├── history/                   # Past scans + prescriptions
    └── paywall/                   # Pro subscription screen
```

## Permissions

### Android
- Camera (medicine + prescription + bill scanning)
- `POST_NOTIFICATIONS` + `SCHEDULE_EXACT_ALARM` (medication reminders)
- `RECEIVE_BOOT_COMPLETED` (reschedule reminders after device restart)
- Internet (Gemini API + Firebase)
- `com.android.vending.BILLING` (Play Billing)

`READ_EXTERNAL_STORAGE` and `WRITE_EXTERNAL_STORAGE` are capped at SDK 32
(Android 13+ uses the Photo Picker, which needs no permission). `USE_EXACT_ALARM`
is intentionally NOT requested to keep the Play Console restricted-permission
surface minimal.

### iOS
- `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`
- Notification permission requested at runtime via UNUserNotificationCenter

## Before First Play Store / App Store Upload

These items live outside the code and must be done by a human:

1. **Rotate the release keystore password** — the included `key.properties`
   uses a weak placeholder. Change it to a strong password BEFORE the first
   Play upload, because the upload key gets locked in afterwards. Back up
   the `.jks` file and the password to a secure location (e.g., a password
   manager and `d:/secrets/`). Losing the JKS means you can never ship an
   update to that listing.
2. **Replace AdMob test IDs** in [lib/services/ad_service.dart:13](lib/services/ad_service.dart#L13)
   and [android/app/src/main/AndroidManifest.xml:34](android/app/src/main/AndroidManifest.xml#L34)
   with your production AdMob app ID + ad unit IDs.
3. **Add `GADApplicationIdentifier`** to `ios/Runner/Info.plist` — without
   it, `MobileAds.initialize()` crashes on iOS launch.
4. **Wire UMP consent** before `AdService().initialize()` in
   [lib/main.dart](lib/main.dart) for EU GDPR compliance.
5. **Rewrite `PRIVACY_POLICY.md`** — the current draft references removed
   authentication features. It must accurately describe Gemini data sharing,
   AdMob, Play Billing, and local medical data storage.
6. **Wire Terms of Service / Privacy links in the paywall** —
   [lib/screens/paywall/paywall_screen.dart](lib/screens/paywall/paywall_screen.dart)
   ships placeholder inline text; replace with hosted URLs once the policy
   pages are live (consider adding the `url_launcher` package).
7. **Add Firebase Crashlytics** — production crashes are otherwise invisible.
8. **Implement server-side IAP receipt verification** —
   [lib/services/subscription_service.dart](lib/services/subscription_service.dart)
   currently grants Pro on client-side checks only, which is bypassable on
   rooted devices.
9. **Generate adaptive Android icon + dedicated notification icon** — the app
   currently uses only the legacy launcher icon, which clips on Android 8+
   and renders as a blank white square in notifications.
10. **Drop `ios/Runner/GoogleService-Info.plist`** into the iOS project so
    Firebase Remote Config works on iOS.

## Notes

- All user data is stored locally (SharedPreferences). No account required.
- The `db_pass` file that used to sit in this directory has been moved to
  `d:/secrets/final_med_lab_db_pass` and is gitignored from accidental
  re-inclusion.
- Test that medication reminders fire correctly across DST transitions and
  device reboots before launch.

## Troubleshooting

### "Failed to analyze medicine / prescription / bill"
- Confirm `GEMINI_API_KEY` was passed via `--dart-define` or set in
  Firebase Remote Config under `gemini_api_key`.
- Check the device has internet connectivity.
- Verify the photo is clear and shows medicine / prescription / bill content.

### Notifications not firing on time
- Grant the notification permission when prompted.
- On Android 12+, the Exact Alarms permission is also required — the app
  requests it via the plugin, but the user can revoke it from system settings.
- Verify meal times are set in the profile (reminders are anchored to them).

### Camera not working
- Grant camera permission when prompted (a rationale dialog appears first).
- If permission was permanently denied, the app offers to open system
  settings.

## License

This project is for educational / commercial use as configured.

## Credits

Built with Flutter and powered by Google Gemini AI.
