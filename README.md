# Doomscroll Stop

A Flutter app that monitors selected apps usage on Android and sends alerts when time limits are exceeded. Only works on **Android**.

---

## Main Features

- **App selection**: Browse and pick installed apps to track.
- **Time limits**: Set a daily usage limit per app (in minutes).
- **App jump detection**: Total session time is calculated even if the user changes the app for some time and then resumes it. No cheating!
- **Background tracking**: Start/stop an Android foreground service that monitors usage continuously. Optimized to only check at key calculated times.
- **Alerts**: Receive a high-priority notification when a time limit is exceeded.
- **Stats page**: View total foreground time for each tracked app over the last 24 hours.
- **Permission management**: Guided banners for requesting Notification and Usage Access permissions, including handling the permanently-denied state.

---

## Running (or building the apk of) the app

Install flutter from [flutter.dev](https://flutter.dev/docs/get-started/install)

**Only works in Android**

To run:
```bash
flutter run
```

To build the apk:
```bash
flutter build apk --release
```

Please accept grant all permissions (Notification Access and Usage Access) to the app when asked.

---

## Flutter App

### Architecture

The app uses a layered architecture with clear separation of concerns:

| Layer | Technology | Purpose |
|---|---|---|
| UI | Flutter widgets (`features/`, `widgets/`) | Render screens, handle interactions |
| State | Riverpod `AsyncNotifierProvider` | Reactive state, async loading, error handling |
| External APIs | Services (`services/`) | Platform communication, permission checks |
| Data | Repositories + `db_service/` | Persist app limits via SharedPreferences |

**Dependency injection** is handled by [GetIt](https://pub.dev/packages/get_it), registered at startup in `service_locator.dart`. Services are accessed through interfaces so they can be replaced in tests.

**Platform communication** goes through a single `MethodChannel` named `com.example.doomscroll_stop/doomscroll`. The `MethodChannelService` exposes typed Dart methods that map to Android handlers.

### Folder Structure

```
lib/
├── main.dart
├── app.dart
├── service_locator.dart              # GetIt singleton registrations
│
├── models/                           # Immutable data types
│   ├── app_info.dart                 # Installed apps data class
│   └── permission_state.dart
│
├── providers/                        # Riverpod state management
│   ├── permission_provider.dart      # Notification & usage access permissions
│   ├── app_preferences_provider.dart # App limits: retrieve, save, and start Android service
│   ├── installed_apps_provider.dart  # Non-system app list from Android
│   └── doomscroll_background_service_provider.dart  # Android service running state, start and stop
│
├── repositories/
│   └── preferences_repository.dart   # Interface over app limits state storage
│
├── services/
│   ├── method_channel_service/       # Dart ↔ Android bridge (MethodChannel)
│   ├── permission_service/           # Request and check OS permissions
│   └── db_service/                   # SharedPreferences wrapper
│
├── features/
│   ├── home/                         # Main screen with actions, permission and service status
│   ├── preferences/                  # Add/remove apps and edit time limits
│   └── stats/                        # Last 24-hour usage statistics list and details per app
│
└── widgets/
    ├── permission_banner.dart        # Inline permission status and request buttons
    └── service_status_banner.dart    # Shows if background tracking is active
```

---

## Android

### How It Works

```
User sets limit in UI
        │
        ▼
appPreferencesProvider.saveAndApply()
        │ MethodChannel: startService(limits, threshold)
        ▼
DoomscrollDetectionService.onStartCommand()
        │ starts coroutine loop
        ▼
  ┌──────────────────────────────────────────────────────────┐
  │  Poll loop                                               │
  │                                                          │
  │  getEvents()                                             │
  │       │                                                  │
  │  processEvents()      ← calculates session info          │
  │       │                                                  │
  │  performCheck()       ← compares session vs limit        │
  │       │                                                  │
  │  [limit exceeded?]                                       │
  │       │ yes                                              │
  │  sendAlert()                                             │
  │  restartSession()                                        │
  │                                                          │
  │  delay(computeNextCheckDelay())                          │
  └──────────────────────────────────────────────────────────┘
```

The user saves their app limits in the UI, which triggers `appPreferencesProvider.saveAndApply()`. This calls `startService()` over the `MethodChannel`, launching `DoomscrollDetectionService` as a foreground service with a persistent silent notification.

The service then runs a continuous coroutine polling loop on a background thread:

- **`getEvents()`** — fetches raw `ACTIVITY_RESUMED` / `ACTIVITY_PAUSED` events from `UsageStatsManager` since the last check.
- **`processEvents()`** — feeds those events into `DoomscrollDetector` to update each app's accumulated session time, accounting for app-switching gaps (jump detection).
- **`performCheck()`** — compares each app's session time against its configured limit.
- If a limit is exceeded, **`sendAlert()`** fires a high-priority notification via `NotificationManager`, then **`restartSession()`** resets that app's counter.
- **`delay(computeNextCheckDelay())`** — sleeps until the moment the next app is closest to its limit, avoiding unnecessary polling.

The loop repeats until `stopService()` is called from Dart, which cancels the coroutine scope and stops the foreground service.

### Service Architecture

The Android side is built around a **Foreground Service** that runs a polling loop in a Kotlin coroutine. Concerns are split across small, focused classes:

```
android/.../com/example/doomscroll_stop/
├── MainActivity.kt                    # MethodChannel handler; bridges Dart and Android
├── DoomscrollDetectionService.kt      # Foreground Service lifecycle; owns the polling loop
├── DoomscrollDetector.kt              # App session calculation and limit detection
├── UsageStatsProvider.kt              # Event normalization and usage aggregation
├── NotificationHelper.kt              # Notification channels and alert builder
├── PackageManagerProvider.kt          # Installed app list and icon bitmap conversion
└── UsageStats/
    ├── UsageStatsRepository.kt        # Interface for event queries
    └── DefaultUsageStatsRepository.kt # UsageStatsManager implementation
```

### How the Service Works

The user saves their app limits in the UI, which triggers `appPreferencesProvider.saveAndApply()`. This calls `startService()` over the `MethodChannel`, launching `DoomscrollDetectionService` as a foreground service with a persistent silent notification.

The service then runs a continuous coroutine polling loop on a background thread:

- **`getEvents()`** — fetches raw `ACTIVITY_RESUMED` / `ACTIVITY_PAUSED` events from `UsageStatsManager` since the last check.
- **`processEvents()`** — feeds those events into `DoomscrollDetector` to update each app's accumulated session time, accounting for app-switching gaps (jump detection).
- **`performCheck()`** — compares each app's session time against its configured limit.
- If a limit is exceeded, **`sendAlert()`** fires a high-priority notification via `NotificationManager`, then **`restartSession()`** resets that app's counter.
- **`delay(computeNextCheckDelay())`** — sleeps until the moment the next app is closest to its limit, avoiding unnecessary polling.

The loop repeats until `stopService()` is called from Dart or Android Intent ('stop' button in notification), which cancels the coroutine scope and stops the foreground service.

### Android Permissions used

| Permission | Why |
|---|---|
| `PACKAGE_USAGE_STATS` | Read per-app foreground time; user must grant via Settings |
| `FOREGROUND_SERVICE` | Start a foreground service |
| `FOREGROUND_SERVICE_SPECIAL_USE` | Required on Android 12+ for the `specialUse` foreground service type |
| `POST_NOTIFICATIONS` | Show alerts on Android 13+ |