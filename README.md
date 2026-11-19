# Energy Drink Roulette

A lightweight web application built with **Flutter** and **Material 3** that randomly picks three energy drinks from a database and provides a built-in side applet for adding new entries if needed.

## API Connection

The application automatically resolves the backend URL based on the build mode (`kDebugMode`):
- **Debug / Local Development:** `http://localhost:8080/api/drinks`
- **Release / Production Build:** `/api/drinks` (relative path, designed to be served directly by `energyroller-api`)

## Getting Started

### Prerequisites

- Flutter SDK `3.50.0` or newer
- Running instance of [`energyroller-api`](../energyroller-api) on port `8080`

### Local Development

1. Install dependencies:

   ```bash
   flutter pub get
   ```

2. Run static analysis:

   ```bash
   flutter analyze
   ```

3. Launch the app:

   ```bash
   flutter run
   ```

To test across other devices in your local network (LAN):

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000
```

## Production Build

Compile the web bundle for deployment:

```bash
flutter build web
```

The compiled static assets are generated in `build/web/` and can be served directly by the `energyroller-api` backend.