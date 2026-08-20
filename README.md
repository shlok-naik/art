# Unfinished

A Flutter app for tracking creative projects, sharing progress, and connecting
with other artists.

## Getting started

### 1. Prerequisites

- Install [Flutter](https://docs.flutter.dev/get-started/install) and make
  sure `flutter doctor` has no blocking issues.
- Install [Android Studio](https://developer.android.com/studio) for the
  Android SDK and emulator.
- Use VS Code with the Flutter extension or Android Studio as your editor.

### 2. Clone the repository

```bash
git clone https://github.com/shlok-naik/art.git
cd art
```

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Configure Supabase

Create a `.env` file in the project root with your Supabase project URL and
publishable (anon) key. The file is ignored by Git and must not be committed.

```dotenv
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-publishable-anon-key
```

The Flutter app communicates with Supabase directly, so no local backend is
needed to run the current features.

### 5. Run the app

You can run on a physical Android device or an Android emulator.

**Physical phone**

1. Enable Developer Options and USB debugging on the phone.
2. Connect it by USB and accept the debugging prompt.
3. Confirm Flutter detects it:

   ```bash
   flutter devices
   ```

4. Start the app:

   ```bash
   flutter run
   ```

**Android emulator**

1. Open Android Studio, then open the Virtual Device Manager.
2. Create and start an emulator.
3. Run `flutter run` from the project directory.

Flutter will detect a connected device or running emulator automatically. If
more than one is available, it will let you choose.

### 6. Making changes

Hot reload is enabled while `flutter run` is active. Save a file and press
`r` in the terminal to reload, or `R` for a full restart.

## Testing

Run the full test suite with:

```bash
flutter test
```

Offline unit tests live in `test/unit/`. They cover small pieces of app logic
without requiring a device, a running backend, or a Supabase connection.
