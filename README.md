# AI-Based Intelligent Waste Sorting And Identification App

This repository contains a starter full-stack framework for a green innovation project: an AI-based intelligent waste sorting and identification app built with Dart and Flutter.

The app pages are written in English and cover the required modules:

- Home
- AI Classification
- Eco Assessment & Rewards
- Community Forum
- Messages
- Profile

## Project Structure

```text
.
+-- frontend/        # Flutter mobile app
|   +-- lib/
|   |   +-- app/     # App shell and bottom navigation
|   |   +-- core/    # Models, services, state, theme
|   |   +-- features/# Six main feature pages
|   +-- pubspec.yaml
+-- backend/         # Dart HTTP API server
    +-- bin/
    +-- lib/src/
    +-- pubspec.yaml
```

## Run The Backend

Install Dart SDK first, then run:

```bash
cd backend
dart pub get
dart run bin/server.dart
```

The default API address is:

```text
http://localhost:8080
```

Available starter endpoints:

- `GET /health`
- `GET /categories`
- `POST /classify`
- `GET /eco-actions`
- `GET /rewards`
- `GET /forum-posts`
- `GET /messages`
- `GET /profile`

Example classification request:

```bash
curl -X POST http://localhost:8080/classify \
  -H "Content-Type: application/json" \
  -d "{\"itemName\":\"plastic bottle\"}"
```

## Run The Frontend

Install Flutter SDK first, then generate platform files and run:

```bash
cd frontend
flutter create .
flutter pub get
flutter run
```

For Android Emulator, `localhost` points to the emulator itself. Use the backend host alias:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

The existing `lib/` code and `pubspec.yaml` are the main application framework.

## Development Notes

- The frontend currently uses mock data for stable UI previews.
- `ApiClient` is ready to connect to the Dart backend.
- The backend uses in-memory sample data and keyword-based classification as a replaceable AI placeholder.
- Later AI integration can be added through an image upload endpoint, an ML model service, or a cloud vision API.
