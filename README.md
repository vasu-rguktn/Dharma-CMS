# Dharma Flutter App

A production-ready Flutter application converted from the Next.js Dharma project. This is a legal and law enforcement AI assistant platform with comprehensive case management features.

## Features

- **Authentication**: Firebase Authentication with Email/Password and Google Sign-In
- **Case Management**: Create, view, and manage FIRs and legal cases
- **Complaint Recording**: Save and manage citizen complaints
- **AI Tools**: Legal queries, document drafting, chargesheet generation and vetting
- **Media Analysis**: Analyze images and documents for case investigation
- **Witness Preparation**: Tools for preparing witness statements
- **Dashboard**: Analytics and visualizations for case statistics
- **Role-based Access**: Officer, Supervisor, and Admin roles

## Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / Xcode (for mobile development)
- Firebase project setup

## Installation & Setup

### 1. Clone and Navigate

```bash
cd flutter_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration

#### Option A: Using FlutterFire CLI (Recommended)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

This will automatically generate `lib/firebase_options.dart` with your Firebase project configuration.

#### Option B: Manual Configuration

1. Create a `.env` file in the project root:

```env
FIREBASE_API_KEY=your_api_key_here
FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
FIREBASE_IOS_CLIENT_ID=your_ios_client_id (iOS only)
FIREBASE_IOS_BUNDLE_ID=com.example.nyaySetuFlutter (iOS only)
```

2. Enable the `.env` file in `pubspec.yaml` assets section (already configured)

### 4. Platform-Specific Setup

#### Android

1. Download `google-services.json` from your Firebase project
2. Place it in `android/app/`
3. Update `android/app/build.gradle` minSdkVersion to 21 or higher

#### iOS

1. Download `GoogleService-Info.plist` from your Firebase project
2. Add it to `ios/Runner/` in Xcode
3. Update `ios/Podfile` minimum iOS version to 12.0 or higher

## Running the App

### Development Mode

```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter run -d <device_id>

# List available devices
flutter devices
```

### Building for Production

#### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

#### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

#### iOS

```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode and archive for distribution.

## Testing

### Run All Tests

```bash
flutter test
```

### Run Specific Test File

```bash
flutter test test/widgets/login_screen_test.dart
```

### Code Coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Project Structure

```
lib/
├── config/
│   └── theme.dart              # App theme configuration
├── models/
│   ├── case_doc.dart           # Case/FIR data model
│   ├── case_status.dart        # Case status enum
│   └── user_profile.dart       # User profile model
├── providers/
│   ├── auth_provider.dart      # Authentication state management
│   ├── case_provider.dart      # Case data management
│   └── complaint_provider.dart # Complaint data management
├── router/
│   └── app_router.dart         # GoRouter configuration
├── screens/
│   ├── splash_screen.dart      # Initial loading screen
│   ├── login_screen.dart       # Login page
│   ├── signup_screen.dart      # Registration page
│   ├── dashboard_screen.dart   # Main dashboard
│   ├── cases_screen.dart       # Cases list
│   ├── case_detail_screen.dart # Individual case view
│   ├── new_case_screen.dart    # Create new case
│   └── ...                     # Other feature screens
├── widgets/
│   └── app_scaffold.dart       # Main app layout with sidebar
├── firebase_options.dart       # Firebase configuration
└── main.dart                   # App entry point
```

## State Management

This app uses **Provider** for state management:

- `AuthProvider`: Handles authentication state and Firebase Auth
- `CaseProvider`: Manages case/FIR data from Firestore
- `ComplaintProvider`: Manages complaint data

## Routing

Navigation uses **go_router** with:
- Auth guard for protected routes
- Named routes for all screens
- Dynamic routes for case details (`/cases/:id`)

## Firestore Security Rules

Ensure your Firestore has appropriate security rules. Example:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /cases/{caseId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    match /complaints/{complaintId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
  }
}
```

## Environment Variables

All sensitive configuration is stored in `.env`. **Never commit this file to version control!**

Copy `.env.example` to `.env` and fill in your values.

## Troubleshooting

### Common Issues

1. **Package conflicts**: Run `flutter pub upgrade --major-versions`
2. **Build errors**: Run `flutter clean && flutter pub get`
3. **Firebase not connecting**: Verify `google-services.json` and `GoogleService-Info.plist` are in place
4. **iOS build fails**: Run `cd ios && pod install && cd ..`

### Platform-Specific

#### Android
- Ensure minSdkVersion is 21+
- Enable multidex if needed

#### iOS
- Run `pod repo update` if facing dependency issues
- Ensure deployment target is iOS 12.0+

## Contributing

1. Create a feature branch
2. Make changes
3. Run tests: `flutter test`
4. Run linter: `flutter analyze`
5. Format code: `flutter format .`
6. Submit pull request

## License

[Your License Here]

## Support

For issues and questions, please contact [your-email@example.com]
