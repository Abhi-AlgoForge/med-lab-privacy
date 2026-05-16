# MedLab - Medicine App with AI Analysis

A comprehensive Flutter medicine identification and medication reminder app with Gemini AI integration.

## Features

### 1. Medicine Identification
- Take photos of medicine tablets or scan from gallery
- AI-powered analysis using Gemini API shows:
  - Medicine name (brand and generic)
  - Chemical contents/active ingredients
  - General use and purpose
  - Harmful content warnings with caution icons
  - Age-specific precautions

### 2. Medication Reminders
- **Manual Entry**: Add medicines with custom timing
- **Prescription Scanning**: AI reads prescriptions to create reminders automatically
- Schedule reminders for:
  - Morning, Afternoon, or Night
  - Before or After eating
- Smart notifications based on your meal timings
- Toggle reminders on/off
- Swipe to delete

### 3. User Profile
- One-time setup collects:
  - Name, age, weight, height
  - Breakfast, lunch, dinner timings
- Used to calculate reminder notification times

### 4. Onboarding
- Beautiful 3-page introduction
- Skip option available
- Shows only on first launch

## Setup

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / Xcode for mobile development
- Gemini API Key (get it from [Google AI Studio](https://makersuite.google.com/app/apikey))

### Installation

1. **Clone or navigate to the project**
   ```bash
   cd d:/final_med_lab
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Gemini API Key**
   
   Open `lib/services/gemini_service.dart` and replace:
   ```dart
   static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
   ```
   
   With your actual API key:
   ```dart
   static const String _apiKey = 'your-actual-api-key';
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

5. **Build APK for Android**
   ```bash
   flutter build apk --release
   ```
   
   The APK will be in `build/app/outputs/flutter-apk/app-release.apk`

## Project Structure

```
lib/
├── main.dart                     # App entry point with splash screen
├── theme/
│   └── app_theme.dart           # Blue color palette and design system
├── models/
│   ├── user_profile.dart        # User data model
│   ├── medicine.dart            # Medicine analysis model
│   └── medication_reminder.dart # Reminder data model
├── services/
│   ├── gemini_service.dart      # Gemini AI integration
│   ├── storage_service.dart     # Local data persistence
│   └── notification_service.dart # Medication notifications
├── widgets/
│   ├── rounded_button.dart      # Animated button component
│   ├── medicine_card.dart       # Medicine display card
│   └── reminder_card.dart       # Reminder list item
└── screens/
    ├── onboarding/              # 3-page intro flow
    ├── profile/                 # User profile setup
    ├── home/                    # Main navigation hub
    ├── medicine_scanner/        # Camera and analysis
    └── reminders/               # Reminder management
```

## Design

- **Color Palette**: Blue theme (#2196F3, #1976D2, #0D47A1)
- **UI Style**: Modern, rounded corners, smooth animations
- **Responsiveness**: Adapts to all screen sizes
- **Animations**: Button press effects, page transitions

## Permissions

### Android
- Camera (medicine scanning)
- Storage (image selection)
- Notifications (medication reminders)
- Internet (Gemini API calls)

### iOS
- Camera access
- Photo library access
- Notification permissions

## Notes

- First launch shows onboarding flow
- User profile setup is required before using the app
- Notifications are scheduled based on meal timings
- All data is stored locally using SharedPreferences
- Internet connection required for AI features

## Troubleshooting

### "Failed to analyze medicine"
- Ensure Gemini API key is correctly set
- Check internet connection
- Verify image is clear and shows medicine information

### Notifications not working
- Grant notification permissions when prompted
- Check device notification settings
- Ensure meal timings are set in profile

### Camera not working
- Grant camera permission when prompted
- Check device camera is functioning
- Try using gallery option instead

## Future Enhancements

- Database integration for medicine history
- Share results with doctors
- Multi-language support
- Medicine interaction checker
- Refill reminders

## License

This project is for educational/demonstration purposes.

## Credits

Built with Flutter and powered by Google Gemini AI.
