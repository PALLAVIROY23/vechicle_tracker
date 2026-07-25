# Real-Time Vehicle Tracker & Location Dashboard App

A Flutter app that simulates real-time vehicle tracking on a Google Map, built with GetX for state management, dependency injection, and routing. A mock delivery van moves along a live route while the app shows live telemetry, a persisted ETA-alerts preference, and destination search with simulated autocomplete.

## Features

- **Live map tracking** — `google_maps_flutter` renders a moving marker driven by a mock `Stream<VehicleModel>` that ticks every few seconds, with custom per-status marker icons (moving / stopped / offline) and a polyline trail behind the vehicle.
- **Marker updates without re-rendering the screen** — only the map's `markers`/`polylines` props rebuild per tick (wrapped in `Obx`); the `GoogleMap` widget itself is never recreated, so panning and zoom stay smooth.
- **Vehicle details panel** — a persistent bottom sheet shows driver name, vehicle ID, live speed, live status, and last-updated time.
- **Manual offline toggle** — a small FAB forces the vehicle online/offline on demand, so you can demo the "Offline" state without waiting for the random simulation to trigger it.
- **ETA Alerts** — a switch persisted via `GetStorage`. When enabled, the controller checks the live distance to the selected destination on each tick and fires a one-time "arriving soon" alert once the vehicle is in range.
- **Search & autocomplete** — a debounced search field backed by a mock places service, plus a persisted "Recent" history list. Selecting a result re-routes the mock vehicle toward it.
- **Splash screen** — a dedicated `splash` module/route shown on launch before handing off to `home`.

## Project structure

```
lib/
  main.dart
  app/
    data/
      models/
        vehicle_model.dart
        search_result_model.dart
      repository/
        storage_repository.dart
    modules/
      splash/
        binding.dart
        controller.dart
        view.dart
      home/
        binding.dart
        controller.dart
        view.dart
    routes/
      app_pages.dart
      app_routes.dart
    utils/
      constants.dart
  components/
    appSnackBaar.dart
  services/
    location_service.dart
    places.dart
```

## What's in each folder

**`lib/`** is the app root — `main.dart` is the entry point, and everything else hangs off `app/`, plus two supporting packages (`components/`, `services/`) that sit outside `app/` on purpose, since neither depends on GetX.

**`lib/app/`** holds everything GetX-specific: models, persistence, feature modules, routing, and shared constants.

- **`data/models/`** — plain data classes with no logic and no GetX dependency. `vehicle_model.dart` defines `VehicleModel` (id, driver name, position, speed, status, timestamp) and the `VehicleStatus` enum. `search_result_model.dart` defines the shape returned by the mock places search.
- **`data/repository/`** — `storage_repository.dart` wraps `GetStorage` behind a typed API (`etaAlertsEnabled`, `addSearchHistory()`, etc.) so nothing else in the app touches a raw storage key directly. If `GetStorage` ever gets swapped for `SharedPreferences` or `Hive`, this is the only file that changes.
- **`modules/`** — each feature is its own folder following the standard `get_cli` shape: `binding.dart` for DI, `controller.dart` for state and logic, `view.dart` for UI.
  - **`splash/`** — the screen shown on launch, before startup work like `GetStorage.init()` necessarily finishes. Kept separate so startup concerns don't bloat the tracking screen's controller.
  - **`home/`** — the main screen: map, search, and the vehicle details panel. `HomeController` owns three related concerns — live tracking, the ETA toggle, and destination search — together in one class rather than three separate controllers (see [Architecture](#architecture) for why). `view.dart` contains the `Scaffold` — the `GoogleMap`, the floating search bar, the FAB stack, and the bottom sheet — along with their private supporting widgets, all in one file rather than split into a `views/widgets/` tree.
- **`routes/`** — `app_routes.dart` defines route name constants, `app_pages.dart` maps each one to its view and binding. Adding a screen means adding one entry here plus a new module folder — nothing else needs to know it exists.
- **`utils/`** — cross-cutting constants that don't belong to any one feature. Currently just the mock route's coordinates and the app's theme color.

**`lib/components/`** holds shared, feature-agnostic helpers. `appSnackBaar.dart` centralizes snackbar presentation (`AppSnackbar.success(...)`, `.info(...)`, `.error(...)`) so every controller gets consistent styling without repeating `Get.snackbar(...)` boilerplate. It lives outside `app/` because it has no dependency on GetX's DI/module system.

**`lib/services/`** is the raw data layer, kept outside `app/` and outside any single module since both files are plain Dart with zero GetX or UI knowledge:

- **`location_service.dart`** — simulates a live GPS feed. Wraps a `Timer.periodic` and a broadcast `StreamController<VehicleModel>`, walking a route and occasionally simulating stops. In production this file's internals would become a WebSocket, Firebase listener, or HTTP polling client — the controller's contract (`Stream<VehicleModel>`) wouldn't need to change.
- **`places.dart`** — simulates the Google Places Autocomplete API against a small in-memory seed list, with an artificial delay so loading states are real and demoable without a billed Places API key.

## Architecture

`HomeController` owns live vehicle tracking, the ETA alerts toggle, and destination search all together, as separated blocks of state within one class rather than three separate controllers — it keeps `binding.dart` to a single registration and avoids splitting apart state that all belongs to the same screen.

Services know nothing about GetX. `LocationService` and `PlacesService` are plain Dart classes, which is what makes the mock data swappable for a real implementation later without touching the controller or any UI.

The repository is the only thing that touches `GetStorage` directly — controllers call `repository.etaAlertsEnabled`, never `GetStorage.read(...)`.

`Obx` is scoped as tightly as possible in `view.dart`. The map's marker/polyline set, the bottom sheet's vehicle fields, and the ETA switch each rebuild independently, so flipping the toggle never rebuilds the map, and a marker tick never rebuilds the toggle.

Bindings own construction, not widgets — `HomeBinding` is where `HomeController` and its dependencies get instantiated via `Get.lazyPut`; `view.dart` only ever calls `Get.find<HomeController>()`.

## How it works

**Live tracking**

`LocationService` walks a route (`AppConstants.mockRoute`, or a freshly generated route toward a searched destination) on a timer, emitting a new `VehicleModel` on a broadcast stream. `HomeController.onInit()` subscribes and writes into `Rxn<VehicleModel> vehicle`. `view.dart` wraps `GoogleMap`'s `markers`/`polylines` in `Obx`, so only those props get diffed on each tick, and the bottom sheet listens to the same value independently.

**ETA alerts**

Selecting a destination in search sets the target location, builds a new route toward it, and resets a per-trip "already alerted" flag. On every tick, if ETA Alerts is on and the vehicle hasn't been alerted for this trip yet, the live distance to the destination gets checked. Once in range, a one-time "Arriving soon" snackbar fires and the flag flips so it doesn't repeat every tick. Turning the toggle off just stops that check from firing — the preference itself still persists across restarts.

## Environment

This project targets Android only. Built and tested against:

```
Flutter 3.41.6 • channel stable
Dart 3.11.4
```

## Setup

1. Install Flutter 3.41.6 (or a compatible stable) — [flutter.dev/get-started](https://flutter.dev).
2. Enable the Maps SDK for Android in Google Cloud Console for the project the API key below belongs to.
3. Add the Google Maps API key to `android/app/src/main/AndroidManifest.xml`, as a direct child of `<application>` (not inside `<activity>`):
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="AIzaSyC5PFaNF3AIdl6ed-WuMI9Gyowmf5GY_gQ" />
   ```
   Restrict this key in Google Cloud Console (Credentials → key → Application restrictions → Android apps, with this app's package name and SHA-1 fingerprint) before pushing to a public repository — an unrestricted key committed to GitHub can be used by anyone and billed to your account.
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Run:
   ```bash
   flutter run
   ```

## Packages used

| Package | Purpose |
|---|---|
| `get` | State management, dependency injection, routing, snackbars |
| `google_maps_flutter` | Map rendering, markers, polylines |
| `get_storage` | Persisted key-value storage for the ETA toggle and search history |
| `geolocator` | Distance calculation for the ETA/geofence alert check |
| `uuid` | Unique identifiers for generated search suggestions |

Double check this against the `dependencies:` block in `pubspec.yaml` — adjust rows to match what's actually declared there.

## Extending toward production

- Replace `LocationService` with a real stream (Firebase Realtime Database, WebSocket, or MQTT) — `HomeController` depends only on `Stream<VehicleModel>`, so nothing else needs to change.
- Replace `PlacesService.search()` with a call to the real Google Places Autocomplete REST API.
- Upgrade the ETA/geofence check into a proper local notification (`flutter_local_notifications`) instead of an in-app snackbar, so alerts still surface when the app is backgrounded.
