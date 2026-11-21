# PREPA PILOT

Android study companion: professor profiles, spaced revision queue, task planning, semester timeline and grade recap.

## Included in this starter
- Flutter Material 3 dark interface
- Local data storage using `shared_preferences`
- Professor profile cards
- Revision queue with repeat intervals (1 / 3 / 7 / 14 / 30 days)
- Task checklist
- Semester dates and timeline progress
- Grade input and end-of-semester recap / celebration when the user meets their configured average goal
- GitHub Actions workflow that generates a release APK

## Build APK on GitHub
1. Create a new GitHub repository (e.g. `prepa-pilot`).
2. Upload all project files from this folder, including `.github/workflows/build-apk.yml`.
3. Open the **Actions** tab. Select **Build PREPA PILOT APK** and click **Run workflow**, or push to `main`/`master`.
4. When the workflow succeeds, open its run page and download the artifact **prepa-pilot-release-apk**.
5. Extract the APK and install it on your Android phone. If Android asks, allow installation from the source you used to download the APK.

## Local build (optional)
With Flutter installed:
```bash
flutter create --platforms=android --org=app.prepapilot .
flutter pub get
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`

## Notes
- Offline-first: all personal data stays on-device in local preferences.
- The semester start/end and average target can be changed using the settings icon.
- The current version is an MVP. Professor profile editing/deleting is available; notification scheduling and backup/export are planned next improvements.
