# ADIC Flutter POC

A Flutter proof-of-concept application implementing secure authentication and data storage.

## Features

- Secure authentication using Flutter AppAuth
- Local data storage using Isar database
- Secure storage for sensitive data
- Network connectivity monitoring
- State management using Provider

## Prerequisites

- Flutter SDK (^3.7.2)
- Dart SDK (^3.7.2)
- Android Studio / Xcode (for platform-specific development)

## Getting Started

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Apply patch packages:
   ```bash
   dart run patch_package apply
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Dependencies

- flutter_secure_storage: ^8.0.0
- provider: ^6.0.5
- http: ^1.1.0
- flutter_appauth: ^6.0.2
- shared_preferences: ^2.5.3
- isar: ^3.1.0
- connectivity_plus: ^5.0.2
- internet_connection_checker: ^1.0.0+1

## Development

- Run code generation for Isar:
  ```bash
  flutter pub run build_runner build
  ```
- Run tests:
  ```bash
  flutter test
  ```

## Project Structure

- `lib/` - Main application code
- `android/` - Android platform-specific code
- `ios/` - iOS platform-specific code
- `web/` - Web platform-specific code
- `patches/` - Package patches