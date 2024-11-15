# Android Release Integration Guide

This guide explains how to set up and configure your Flutter project for Android release builds using the automated setup script. The script handles keystore generation, configuration files, and necessary build.gradle modifications.

## Prerequisites

- Flutter development environment
- Java Development Kit (JDK) installed
- Basic understanding of Android app signing

## Installation

1. Download the `flutter-android-release.sh` script to your Flutter project's root directory
2. Make the script executable:
   ```bash
   chmod +x flutter-android-release.sh
   ```
3. Run the script:
   ```bash
   ./flutter-android-release.sh
   ```
   ```bash
   bash flutter-android-release.sh
   ```

## What the Script Does

### 1. Keystore Generation
- Creates a new keystore file at `keys/upload-keystore.jks`
- Prompts for custom keystore information:
  - Key alias
  - Key password
  - Keystore password
  - Personal/Organization information
  - Location details

### 2. Configuration Files
Creates/updates the following files:

#### `android/key.properties`
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=../../keys/upload-keystore.jks
```

#### Modifies `android/app/build.gradle`
- Adds keystore properties configuration
- Configures signing settings for release builds
- Updates signing configuration from debug to release

### 3. AndroidManifest.xml
- Checks for INTERNET permission
- Offers to add if missing

## Default Values

The script uses these default values if no custom input is provided:
- Keystore location: `keys/upload-keystore.jks`
- Key alias: `upload`
- Key password: `123456`
- Keystore password: `123456`
- Validity: 10,000 days

## Usage Instructions

1. **Backup Your Project**
   - Create a backup of your project before running the script
   - Especially important if you already have release configurations

2. **Run the Script**
   ```bash
   ./flutter-android-release.sh
   ```

3. **Follow the Prompts**
   - Enter custom values when prompted
   - Press Enter to use default values
   - Confirm any file overwrites

4. **Verify Installation**
   Check that the following files were created/modified:
   - `keys/upload-keystore.jks`
   - `android/key.properties`
   - `android/app/build.gradle`

## Building Release APK

After running the script, you can build your release APK:

```bash
flutter build apk --release
```

The signed APK will be available at:
`build/app/outputs/flutter-apk/app-release.apk`

## Building App Bundle

For Google Play Store submission:

```bash
flutter build appbundle --release
```

The signed app bundle will be available at:
`build/app/outputs/bundle/release/app-release.aab`

## Important Notes

1. **Store Credentials Safely**
   - Keep your keystore file secure
   - Save passwords in a safe location
   - Losing these means losing ability to update your app

2. **Version Control**
   - Add `key.properties` to `.gitignore`
   - Never commit sensitive credentials
   - Keep keystore file backup in a secure location

3. **Troubleshooting**
   If you encounter issues:
   - Check JDK installation
   - Verify file permissions
   - Ensure all paths are correct
   - Check for existing conflicting configurations

## Security Recommendations

1. **Use Strong Passwords**
   - Avoid using default passwords
   - Use complex passwords for production apps

2. **Keystore Protection**
   - Store keystore file securely
   - Create secure backups
   - Document recovery procedures

3. **Production Settings**
   - Change all default values
   - Use organization-specific information
   - Set appropriate validity period

## Supporting Different Platforms

The script supports:
- Linux (apt-based distributions)
- macOS (using Homebrew)
- Windows (manual JDK installation required)

## License

This script is provided as-is under the MIT license. Feel free to modify and distribute as needed.