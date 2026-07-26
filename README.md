# art

A Flutter project.

## Getting started (clone and run)

### 1. Prerequisites

- Install [Flutter](https://docs.flutter.dev/get-started/install) and make sure `flutter doctor` runs with no blocking issues.
- Install [Android Studio](https://developer.android.com/studio) (needed for the Android SDK, and for the emulator if you don't have a physical phone).
- A code editor — [VS Code](https://code.visualstudio.com/) with the Flutter extension, or Android Studio itself, both work well.

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

Copy `.env.example` to `.env`, then fill in the values for your Supabase
project. The `.env` file is intentionally ignored by Git and must not be
committed.

```bash
cp .env.example .env
```

### 5. Run the backend

The Projects feature calls a small FastAPI backend (`backend/`) that proxies
requests to Supabase. It needs to be running locally for that feature to work.

```bash
cd backend
python -m venv .venv
.venv/Scripts/activate   # .venv/bin/activate on macOS/Linux
pip install -r requirements.txt
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

Leave this running in its own terminal. `.env`'s `BACKEND_URL` points the
Flutter app at it (`http://localhost:8000` by default). If you're running on
a physical phone over USB rather than an emulator, `localhost` on the phone
isn't your computer — first run `adb reverse tcp:8000 tcp:8000` so the
phone's `localhost:8000` tunnels back to your machine.

### 6. Run the app

You can run on a physical Android phone or on a virtual device (emulator) created in Android Studio.

**Option A: Physical phone**

1. On your phone, enable Developer Options (Settings → About phone → tap "Build number" 7 times).
2. In Developer Options, enable "USB debugging".
3. Connect the phone to your computer via USB (accept the debugging prompt on the phone).
4. Check the device is detected:
   ```bash
   flutter devices
   ```
5. Run the app:
   ```bash
   flutter run
   ```

**Option B: Virtual device (Android emulator)**

1. Open Android Studio → **More Actions** → **Virtual Device Manager**.
2. Click **Create Device**, pick a phone profile, and download a system image, then finish the setup.
3. Start the emulator from the Virtual Device Manager (or it will auto-start when you run the app).
4. Run the app:
   ```bash
   flutter run
   ```

Flutter will detect the running emulator or connected phone automatically. If more than one device is available, `flutter run` will let you pick which one to launch on.

### 7. Making changes

Hot reload is enabled by default while `flutter run` is active — save a file and press `r` in the terminal to see changes instantly, or `R` for a full hot restart.
