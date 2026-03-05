# Privacy Policy for Med Lab

**Last updated:** February 28, 2026

## Overview

Med Lab ("the App") is an AI-powered medicine companion that helps users identify medicines, analyze medical bills, and manage medication reminders. Your privacy is important to us, and this policy explains how we handle your data.

## Data Collection & Storage

### Data stored locally on your device
All user data is stored **exclusively on your device** using local storage. This includes:
- User profile information (name, age group)
- Medication reminders and dose records
- Medicine scan history
- Prescription/bill scan history
- App preferences (theme, feature tour status)

**We do not operate any servers or databases that store your personal data.**

### Authentication
The App uses **Google Sign-In via Firebase Authentication** solely to verify your identity. We receive your:
- Google display name
- Email address
- Profile photo URL

This information is used only for display within the App and is not stored on any external server.

### Camera & Photos
The App requests camera and photo library access to:
- Scan medicine labels and packaging
- Scan medical bills and prescriptions

Images are processed in real-time and are **not stored permanently** by the App. Images are sent to the Google Gemini API for analysis (see Third-Party Services below).

## Third-Party Services

### Google Gemini AI
The App uses Google's Gemini AI API to analyze medicine images and medical bills. When you scan a medicine or bill:
- The image is sent to Google's servers for AI processing
- Google's [privacy policy](https://policies.google.com/privacy) and [Gemini API terms](https://ai.google.dev/terms) apply to this processing
- We do not control how Google handles data sent to their API

### Firebase Authentication
- Used solely for Google Sign-In
- Governed by Google's [Firebase privacy policy](https://firebase.google.com/support/privacy)

### Google Sign-In
- Used for user authentication only
- Governed by Google's [privacy policy](https://policies.google.com/privacy)

## Data Sharing

We **do not sell, trade, or share** your personal data with any third parties, except as described in the Third-Party Services section above (for AI processing and authentication).

## Data Retention

- All local data remains on your device until you uninstall the App or clear its data
- You can clear all App data at any time through your device settings
- Signing out removes your authentication session but preserves local data

## Notifications

The App may send local notifications for medication reminders. These notifications are generated entirely on your device and do not involve any external servers.

## Children's Privacy

The App is not intended for use by children under the age of 13. We do not knowingly collect personal information from children.

## Medical Disclaimer

Med Lab is an **informational tool only** and is NOT a substitute for professional medical advice, diagnosis, or treatment. Always consult a qualified healthcare provider for medical decisions.

## Permissions

The App requests the following device permissions:
- **Camera**: To scan medicine labels and bills
- **Storage**: To access photos from your gallery
- **Notifications**: To send medication reminders
- **Internet**: To communicate with AI services for analysis

## Changes to This Policy

We may update this privacy policy from time to time. Any changes will be reflected in the "Last updated" date above.

## Contact

If you have questions about this privacy policy, please open an issue on our [GitHub repository](https://github.com).

---

*This App is open-source and available for public review.*
