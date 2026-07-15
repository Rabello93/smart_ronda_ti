# Implementation Plan: Fix Build Failure and Version Mismatches

The project is currently failing to build because it references non-existent versions of Gradle (`8.14.0`), Android Gradle Plugin (`8.11.1`), and Kotlin (`2.2.20`). This plan corrects these versions to stable releases and updates dependencies to resolve build-time warnings.

## User Review Required

> [!IMPORTANT]
> The project was configured with future version numbers that do not exist yet (e.g., Gradle 8.14, Kotlin 2.2). I am downgrading these to the latest stable versions.

> [!WARNING]
> I am also updating `compileSdk` to `35` (Android 15) as `36` is currently in preview and may cause compatibility issues with some plugins.

## Proposed Changes

### Build Configuration

#### [MODIFY] [gradle-wrapper.properties](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/android/gradle/wrapper/gradle-wrapper.properties)
- Change `gradle-8.14.0-all.zip` to `gradle-8.11-all.zip`.

#### [MODIFY] [settings.gradle.kts](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/android/settings.gradle.kts)
- Change Android Application Plugin version from `8.11.1` to `8.7.3`.
- Change Kotlin Android Plugin version from `2.2.20` to `2.1.0`.

#### [MODIFY] [app/build.gradle.kts](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/android/app/build.gradle.kts)
- Lower `compileSdk` to `35`.

### Dependencies

#### [MODIFY] [pubspec.yaml](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/pubspec.yaml)
- Update `share_plus` to `^13.0.0`.
- Update `flutter_secure_storage` to `^10.0.0`.
- (Optional) Update other packages to resolve the "62 packages have newer versions" warning.

## Verification Plan

### Automated Tests
- Run `flutter pub get` to verify dependency resolution.
- Run `flutter build apk --release` to verify the fix for the Gradle download error.
- Run `flutter build web --release` to check if WASM warnings are reduced/resolved.

### Manual Verification
- Verify the generated APK name follows the custom format: `smart_ronda_ti_v3.2.6.apk`.
