# Step Counter - Kinetic Pulse

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Kotlin](https://img.shields.io/badge/Kotlin-7F52FF?style=for-the-badge&logo=kotlin&logoColor=white)
![Status](https://img.shields.io/badge/Status-Completed-success?style=for-the-badge)

A modern Flutter-based step counter application that tracks daily steps in real time, monitors fitness activity, supports Android background tracking, and provides home-screen widget integration.

---

## Overview

**Step Counter - Kinetic Pulse** is a completed fitness tracking application built with **Flutter** and **Dart**.

The app uses the device step sensor to count steps in real time and provides useful activity metrics such as daily steps, distance walked, calories burned, active minutes, goal progress, weekly activity, and monthly activity.

It also includes Android-specific features such as foreground service support, background step tracking, notification alerts, battery optimization guidance, and home-screen widgets.

The goal of this project is to provide a clean, responsive, and practical step tracking experience for users who want to monitor their daily movement and fitness progress.

---

## Key Features

- Real-time step counting
- Daily step goal tracking
- Weekly and monthly activity overview
- Distance calculation
- Calories burned estimation
- Active minutes tracking
- Date-wise activity history
- Light and dark theme support
- Clean modern Flutter UI
- Android foreground service support
- Background step tracking
- Android home-screen widget support
- Step milestone alerts
- Quiet hours for notifications
- Battery optimization guidance
- Local data persistence using SharedPreferences

---

## Application Screens

The app includes the following main sections:

| Screen | Description |
|---|---|
| Dashboard | Shows today's steps, goal progress, distance, calories, and active minutes |
| Activity | Displays weekly and monthly activity summaries |
| Goals | Allows users to view and manage daily step goals |
| Settings | Provides tracking, notification, background service, and widget options |

---

## System Architecture

```text
Device Step Sensor
        │
        ▼
Flutter Application
        │
        ├── Step Tracking Controller
        │   ├── Real-time step updates
        │   ├── Daily step calculation
        │   ├── Weekly and monthly history
        │   └── Local data storage
        │
        ├── Dashboard UI
        │   ├── Step count
        │   ├── Goal progress
        │   ├── Distance
        │   ├── Calories
        │   └── Active minutes
        │
        └── Android Native Layer
            ├── Foreground service
            ├── Background tracking
            ├── Notification alerts
            └── Home-screen widgets
```

---

## Technology Stack

| Category | Technologies |
|---|---|
| Framework | Flutter |
| Language | Dart |
| Native Android | Kotlin |
| UI | Material Design, Google Fonts |
| Step Tracking | pedometer |
| Permissions | permission_handler |
| Local Storage | shared_preferences |
| Date Formatting | intl |
| Platform Support | Android, Web, Windows, Linux, macOS, iOS |

---

## Core Features

### Dashboard

The dashboard provides a real-time summary of the user's daily fitness activity.

Features include:

- Today's total steps
- Circular step progress indicator
- Daily goal progress
- Distance walked in kilometers
- Calories burned
- Active minutes
- Live tracking status
- Clean activity summary cards

---

### Activity Tracking

The activity section helps users understand movement patterns over time.

Features include:

- Weekly activity overview
- Monthly activity overview
- Total steps for selected period
- Average step count
- Best activity day
- Progress against daily goal
- Simple activity visualization

---

### Goal Tracking

The goals section helps users stay consistent with their daily fitness targets.

Features include:

- Daily step goal
- Goal progress monitoring
- Fitness target tracking
- Visual progress feedback
- Motivation-focused interface

---

### Settings

The settings section provides control over tracking behavior, alerts, widgets, and background service options.

Features include:

- Step tracking settings
- Background tracking controls
- Step alert configuration
- Alert interval configuration
- Quiet hours support
- Notification permission handling
- Battery optimization guidance
- Widget setup guidance

---

### Android Background Tracking

The app includes Android background tracking support using native Kotlin code.

Features include:

- Foreground service for continuous tracking
- Persistent notification support
- Background step count updates
- Boot and restart handling
- Battery optimization guidance
- Background service status monitoring

> Background tracking behavior may vary depending on Android version, device manufacturer, and battery optimization settings.

---

### Android Home-Screen Widgets

The app supports Android widget functionality so users can view step information directly from the home screen.

Features include:

- Home-screen step widget support
- Step count display
- Goal progress display
- Distance and calorie information
- Widget refresh support
- Multiple widget layout support

---

### Step Alerts

The app includes step alert settings to help users stay active throughout the day.

Features include:

- Enable or disable step alerts
- Configure alert interval
- Milestone-based step notifications
- Quiet hours support
- Notification permission handling

---

## Calculations Used

The app estimates activity metrics using step-based formulas.

```text
Distance:
steps × 0.00075 = distance in kilometers

Calories:
steps × 0.04 = calories burned

Active Minutes:
steps ÷ 120 = active minutes
```

These calculations are approximate. Actual values may vary depending on the user's height, weight, walking speed, stride length, and walking style.

---

## Dependencies

The project uses the following major Flutter packages:

```yaml
dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8
  pedometer: ^4.1.1
  permission_handler: ^11.4.0
  intl: ^0.20.2
  google_fonts: ^6.3.0
  shared_preferences: ^2.5.3
```

---

## Prerequisites

Before running this project, make sure the following tools are installed:

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- Android emulator or physical Android device
- Git

Check your Flutter installation:

```bash
flutter doctor
```

---

## Installation and Setup

### 1. Clone the Repository

```bash
git clone https://github.com/mehedi77k/step-counter.git
cd step-counter
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Check Available Devices

```bash
flutter devices
```

### 4. Run the App

For Android:

```bash
flutter run
```

For a specific device:

```bash
flutter run -d <device-id>
```

For Web:

```bash
flutter run -d chrome
```

For Windows:

```bash
flutter run -d windows
```

---

## Android Permission Requirements

The app may require the following permissions depending on the Android version:

- Activity Recognition permission
- Notification permission
- Foreground service permission
- Background activity permission
- Battery optimization exemption

These permissions are required for accurate step counting, background tracking, notifications, and widget updates.

If permissions are denied, some features may not work correctly.

---

## Project Structure

```text
step-counter/
│
├── android/
│   └── app/
│       └── src/
│           └── main/
│               ├── AndroidManifest.xml
│               └── kotlin/
│                   └── com/
│                       └── example/
│                           └── step_counter_app/
│                               ├── MainActivity.kt
│                               ├── StepForegroundService.kt
│                               └── StepCounterWidgetProvider.kt
│
├── ios/
├── web/
├── windows/
├── macos/
├── linux/
├── test/
│
├── lib/
│   ├── main.dart
│   │
│   └── src/
│       └── modules/
│           ├── step_tracker_controller.part.dart
│           ├── settings.part.dart
│           └── shared_widgets.part.dart
│
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
└── README.md
```

---

## Important Files

| File | Purpose |
|---|---|
| `lib/main.dart` | Main app entry point, UI layout, navigation, dashboard, activity, and goals screens |
| `lib/src/modules/step_tracker_controller.part.dart` | Core step counting logic, storage, permissions, background service integration, alerts, and widget settings |
| `lib/src/modules/settings.part.dart` | Settings screen, notification settings, background protection guide, and battery optimization help |
| `lib/src/modules/shared_widgets.part.dart` | Shared reusable UI widgets |
| `android/app/src/main/AndroidManifest.xml` | Android permissions, services, receivers, and widget declarations |
| `android/app/src/main/kotlin/.../MainActivity.kt` | Flutter-to-Android native method channel bridge |
| `android/app/src/main/kotlin/.../StepForegroundService.kt` | Android foreground service for background step tracking |
| `android/app/src/main/kotlin/.../StepCounterWidgetProvider.kt` | Android widget provider implementation |

---

## How the App Works

1. The app requests the required motion or activity recognition permission.
2. After permission is granted, it starts listening to step sensor data.
3. The step count updates in real time.
4. Daily step values are stored locally using SharedPreferences.
5. Weekly and monthly activity data are generated from saved records.
6. Distance, calories, and active minutes are calculated from the step count.
7. On Android, the foreground service helps continue tracking in the background.
8. Widget support allows users to view step information from the home screen.
9. Notification alerts can notify users when step milestones are reached.

---

## Build Commands

### Android APK

```bash
flutter build apk --release
```

### Android App Bundle

```bash
flutter build appbundle --release
```

### Web

```bash
flutter build web --release
```

### Windows

```bash
flutter build windows --release
```

### Clean Build

```bash
flutter clean
flutter pub get
flutter run
```

---

## Testing Checklist

Use this checklist before final release or presentation:

- [ ] App launches successfully
- [ ] Step permission request works
- [ ] Real-time step counting works
- [ ] Daily step count updates correctly
- [ ] Step count persists after app restart
- [ ] Weekly activity data displays correctly
- [ ] Monthly activity data displays correctly
- [ ] Distance calculation works
- [ ] Calories calculation works
- [ ] Active minutes update correctly
- [ ] Daily goal progress works
- [ ] Goals screen works correctly
- [ ] Settings screen works correctly
- [ ] Step alert settings save correctly
- [ ] Quiet hours work correctly
- [ ] Notification permission works
- [ ] Background tracking works on Android
- [ ] Foreground service starts correctly
- [ ] Home-screen widget displays step data
- [ ] Widget refresh works correctly
- [ ] Dark mode UI displays correctly
- [ ] App works after device restart
- [ ] Battery optimization guidance opens correctly

---

## Troubleshooting

### Step Counter Is Not Working

Run:

```bash
flutter clean
flutter pub get
flutter run
```

Then check:

- Activity Recognition permission is allowed.
- The device has a physical step counter sensor.
- The app is not restricted in the background.
- Battery optimization is disabled for the app.
- The app has notification permission if using foreground service alerts.
- You are testing on a physical Android device, not only an emulator.

---

### Background Tracking Stops

Some Android devices aggressively restrict background services.

Check:

- Battery optimization is disabled for the app.
- The app is allowed to run in the background.
- Autostart permission is enabled if your device requires it.
- The foreground service notification is visible.
- The app is not manually stopped from system settings.

---

### Widget Does Not Update

Check:

- The app has been opened at least once.
- Background tracking is enabled.
- The widget is added correctly to the home screen.
- Battery optimization is not blocking updates.
- The device launcher supports widgets properly.

---

### App Does Not Run

Run:

```bash
flutter doctor -v
```

Fix any issues shown in the Flutter environment report.

Then run:

```bash
flutter pub get
flutter run
```

---

### Dependency Issues

Run:

```bash
flutter pub get
flutter pub upgrade
```

If the issue continues, clean the project:

```bash
flutter clean
flutter pub get
```

---

## Known Limitations

- Step tracking depends on the device's physical step sensor.
- Some emulators may not support real step sensor data.
- Background tracking behavior may differ across Android manufacturers.
- Battery optimization can stop background services on some devices.
- Web and desktop platforms may not support real physical step counting.
- Distance and calorie values are estimates, not medical measurements.
- Widget behavior may vary depending on launcher and Android version.

---

## Privacy and Data Storage

The app stores step-related data locally on the user's device using SharedPreferences.

The project does not require a cloud database for core functionality.

Recommended privacy practices:

- Do not collect unnecessary personal data.
- Keep health and activity data stored securely.
- Inform users about required permissions.
- Use step and health data only for fitness tracking purposes.
- Follow applicable privacy and platform guidelines before publishing.

---

## Future Improvements

Although the core project is complete, the following features can be added in future versions:

- User profile setup
- Height and weight-based calorie calculation
- Custom stride length support
- Daily, weekly, and monthly reports
- Achievement badges
- Streak tracking
- Water reminder
- Heart rate integration
- Google Fit integration
- Cloud sync support
- More home-screen widget layouts
- Improved charts and analytics
- Export activity report as PDF
- Export activity report as CSV
- Leaderboard or challenge system
- Wear OS support

---

## Contributing

Contributions are welcome.

To contribute:

1. Fork the repository

2. Create a new branch

```bash
git checkout -b feature/new-feature
```

3. Commit your changes

```bash
git commit -m "Add new feature"
```

4. Push to your branch

```bash
git push origin feature/new-feature
```

5. Open a Pull Request

---

## Developer

**Mehedi Hasan**

- GitHub: [@mehedi77k](https://github.com/mehedi77k)
- Repository: [step-counter](https://github.com/mehedi77k/step-counter)
- Project: Step Counter - Kinetic Pulse
- Built with Flutter, Dart, and Android native support

---

## Project Status

```text
Status: Completed
Version: 1.0.0+1
Project Type: Fitness Tracking Application
Framework: Flutter
Main Language: Dart
Native Android Language: Kotlin
Primary Platform: Android
Storage: Local SharedPreferences
```

---

## Support

For issues, suggestions, or improvements, open an issue in the GitHub repository:

```text
https://github.com/mehedi77k/step-counter/issues
```

---

## Show Your Support

If this project is useful, consider giving it a star on GitHub.
