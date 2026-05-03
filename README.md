# 🚶‍♂️ Step Counter - Kinetic Pulse

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Status](https://img.shields.io/badge/Status-Active%20Development-brightgreen?style=for-the-badge)

A modern Flutter-based step counter application that tracks daily steps in real time and helps users monitor their fitness activity with a clean, responsive, and user-friendly interface.

---

# 📱 Overview

**Step Counter - Kinetic Pulse** is a fitness tracking app built using Flutter and Dart.

This app counts the user's steps in real time using the device step sensor and displays useful health-related information such as daily steps, distance, calories burned, active minutes, goal progress, weekly activity, and monthly activity.

The main goal of this project is to provide a simple, beautiful, and practical step tracking experience for users who want to monitor their daily movement and fitness progress.

---

# ✨ Key Highlights

- 🚶 Real-time step counting
- 🎯 Daily step goal tracking
- 📊 Weekly and monthly activity overview
- 🔥 Calories burned estimation
- 📍 Distance calculation
- ⏱️ Active minutes tracking
- 📅 Date-wise activity history
- 🌙 Light and dark theme support
- 📱 Clean and modern mobile UI
- 🏠 Android home widget support
- 🔔 Step alert and notification settings
- ⚙️ Background tracking support on Android
- 💾 Local data saving using SharedPreferences

---

# 🚀 Features

## 🏠 Dashboard

The dashboard gives users a quick overview of their daily fitness activity.

- Today's total steps
- Circular step progress indicator
- Daily step goal progress
- Distance walked in kilometers
- Calories burned
- Active minutes
- Live step tracking status
- Simple and clean activity summary

---

## 📊 Activity Tracking

The activity section helps users understand their movement history.

- Weekly activity overview
- Monthly activity overview
- Total steps for selected period
- Average step count
- Best activity day
- Progress against daily goal
- Simple activity visualization

---

## 🎯 Goals

The goals section helps users stay motivated.

- Daily step goal
- Goal progress tracking
- Fitness target monitoring
- Encouragement to complete daily activity

---

## ⚙️ Settings

The settings section includes useful controls for tracking and notifications.

- Step tracking settings
- Background tracking option
- Step alert configuration
- Quiet hours support
- Battery optimization guide
- Notification permission handling
- Widget guide option

---

## 🏠 Android Widget Support

The app supports Android widget-related features so users can quickly view their step information.

- Home screen widget support
- Widget setup guide
- Background service support
- Quick step information access

---

## 🔔 Step Alerts

The app includes step alert settings to help users stay active.

- Enable or disable step alerts
- Set step alert interval
- Configure quiet hours
- Avoid alerts during rest time

---

## 🛠️ Technology Stack

## Frontend

- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **Material Design** - Modern UI components
- **Google Fonts** - Beautiful typography

## Step Tracking & Storage

- **pedometer** - Real-time step sensor data
- **permission_handler** - Permission management
- **shared_preferences** - Local data storage
- **intl** - Date and number formatting

## Android Native Support

- Kotlin native code
- Foreground service
- Home screen widget support
- Background tracking support
- Battery optimization handling

---

# 📦 Key Packages

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

# 📋 Prerequisites

Before running this project, make sure you have installed:

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Android emulator or physical Android device
- Git

Check Flutter installation:

```bash
flutter doctor
```

---

# ⚙️ Installation & Setup

## 1️⃣ Clone the Repository

```bash
git clone https://github.com/mehedi77k/step-counter.git
cd step-counter
```

## 2️⃣ Install Dependencies

```bash
flutter pub get
```

## 3️⃣ Run the App

For Android:

```bash
flutter run
```

For Web:

```bash
flutter run -d chrome
```

For Windows:

```bash
flutter run -d windows
```

To see available devices:

```bash
flutter devices
```

Run on a specific device:

```bash
flutter run -d <device-id>
```

---

## 📁 Project Structure

```text
step-counter/
│
├── android/                        
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

# 🔐 Required Permissions

The app may require the following permissions depending on the platform:

### Android

- Activity Recognition permission
- Notification permission
- Foreground service permission
- Background activity permission
- Battery optimization exemption for better background tracking

Without the required permissions, real-time step counting and background tracking may not work properly.

---

# 🧠 How the App Works

1. The app requests motion or activity recognition permission.
2. After permission is granted, it listens to step sensor data.
3. Step count is updated in real time.
4. Daily step data is saved locally.
5. Weekly and monthly activity history is generated from saved data.
6. Distance, calories, and active minutes are calculated from step count.
7. On Android, background service helps continue tracking.
8. Widget support allows users to view step data from the home screen.

---

# 📊 Calculations Used

The app estimates fitness metrics using simple formulas:

```text
Distance:
steps × 0.00075 = distance in km

Calories:
steps × 0.04 = calories burned

Active Minutes:
steps ÷ 120 = active minutes
```

These values are approximate and may vary depending on user height, weight, walking speed, and walking style.

---

# 🎨 UI/UX Design

The app uses a modern fitness dashboard style.

### Design Features

- Smooth rounded cards
- Circular step progress indicator
- Clean bottom navigation
- Light and dark theme support
- Large readable typography
- Fitness-focused interface
- Responsive layout

## Main Screens

- Dashboard
- Activity
- Goals
- Settings

---

# 🧪 Testing Checklist

Use this checklist before final release:

- [ ] App runs successfully
- [ ] Step permission request works
- [ ] Real-time step counting works
- [ ] Daily step count saves correctly
- [ ] Weekly activity data displays correctly
- [ ] Monthly activity data displays correctly
- [ ] Distance calculation works
- [ ] Calories calculation works
- [ ] Active minutes update correctly
- [ ] Daily goal progress works
- [ ] Settings screen works
- [ ] Step alert settings save correctly
- [ ] Background tracking works on Android
- [ ] Home widget option works
- [ ] Dark mode UI looks good
- [ ] App works after restart

---

# 🚀 Build Commands

## Android APK

```bash
flutter build apk --release
```

## Android App Bundle

```bash
flutter build appbundle --release
```

## Web

```bash
flutter build web --release
```

## Windows

```bash
flutter build windows --release
```

---

# ⚠️ Known Limitations

- Step tracking depends on the device's physical step sensor.
- Some devices may restrict background services.
- Battery optimization may stop background tracking on some Android phones.
- Web and desktop platforms may not support real physical step counting.
- Calories and distance are estimated values.

---

# 💡 Future Improvements

Possible future updates:

- User profile system
- Height and weight-based calorie calculation
- Daily, weekly, and monthly reports
- Fitness achievement badges
- Water reminder
- Heart rate integration
- Google Fit integration
- Cloud sync support
- More home screen widgets
- Better charts and analytics
- Export activity report as PDF
- Custom step goals
- Leaderboard or challenge system

---

# 🐛 Troubleshooting

## Step counter is not working

Try the following commands:

```bash
flutter clean
flutter pub get
flutter run
```

Also check:

- Activity permission is allowed
- Notification permission is allowed
- Battery optimization is disabled
- Device has step sensor support
- App is not restricted in background

---

## App does not run

Run:

```bash
flutter doctor -v
```

Then fix any Flutter setup issues shown in the terminal.

---

## Dependencies problem

Run:

```bash
flutter pub get
flutter pub upgrade
```

---

# 🤝 Contributing

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

# 👨‍💻 Developer

**Mehedi Hasan**

- GitHub: [@mehedi77k](https://github.com/mehedi77k)
- Project: Step Counter App
- Built with Flutter and Dart

---

# 📞 Support

If you face any issue or have suggestions, please open an issue in the GitHub repository.

Repository:  
https://github.com/mehedi77k/step-counter

---

# 📌 Project Status

```text
Status: Active Development
Version: 1.0.0+1
Platform: Flutter
Main Language: Dart
```

---

# ⭐ Show Your Support

If you like this project, please give it a star on GitHub.

