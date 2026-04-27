<p align="center">
  <img src="https://img.shields.io/badge/Dart-3.4+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart 3.4+">
  <img src="https://img.shields.io/badge/Flutter-3.4+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter 3.4+">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge" alt="License: MIT">
  <img src="https://img.shields.io/badge/Status-Prototype-brightgreen?style=for-the-badge" alt="Status: Prototype">
</p>

<h1 align="center">🌿 EcoSort AI</h1>
<h3 align="center">AI-Based Intelligent Waste Sorting & Identification App</h3>

<p align="center">
  <strong>A full-stack green-tech mobile application that helps users sort waste intelligently, earn eco-rewards, and build sustainable communities — powered by Dart & Flutter.</strong>
</p>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Project Architecture](#-project-architecture)
- [Tech Stack](#-tech-stack)
- [Screens & Modules](#-screens--modules)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Running the Backend](#running-the-backend)
  - [Running the Frontend](#running-the-frontend)
- [API Reference](#-api-reference)
- [Project Structure](#-project-structure)
- [Roadmap](#-roadmap)
- [Environment Variables](#-environment-variables)
- [Database Schema](#-database-schema)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌍 Overview

**EcoSort AI** is an intelligent waste sorting assistant designed to promote environmental sustainability through technology. The application helps users identify the correct waste category for everyday items, tracks their eco-friendly actions, awards points that can be redeemed for rewards, and fosters community engagement through a built-in forum.

The current prototype uses a **keyword-based classification engine** as a stand-in for AI, making it easy to replace with a real machine-learning model, computer vision API, or cloud-based AI service in future iterations.

> 🎯 **Goal**: Make waste sorting simple, rewarding, and community-driven — one scan at a time.

---

## ✨ Features

### Core Capabilities

| Module | Description |
|---|---|
| 🏠 **Home** | Dashboard with quick stats, green score overview, and recent eco-actions |
| 🤖 **AI Classification** | Classify waste items by name or image; view category details and disposal tips |
| 🌱 **Eco Assessment & Rewards** | Track completed eco-actions, earn points, and redeem rewards like coupons and badges |
| 💬 **Community Forum** | Browse and participate in discussions about waste sorting, volunteering, and environmental topics |
| ✉️ **Messages** | In-app notifications and message threads from EcoSort AI, clubs, and the reward center |
| 👤 **Profile** | User profile with green score, total recycled weight, level, and activity history |

### Waste Categories

| Category | Bin Color | Examples |
|---|---|---|
| ♻️ **Recyclable** | Blue | Plastic bottles, cardboard, glass jars, aluminum cans |
| 🍃 **Organic** | Green | Fruit peels, vegetable scraps, tea leaves, eggshells |
| ☣️ **Hazardous** | Red | Batteries, paint, medicine, pesticide bottles |
| 🗑️ **Residual** | Gray | Used tissues, ceramics, dust, contaminated packaging |

### Smart Classification Engine

- **Keyword matching** classifies items in real time with confidence scoring
- Examples: `"plastic bottle"` → Recyclable (94%), `"banana peel"` → Organic (94%)
- Designed as a pluggable module — swap in a real AI/ML model when ready

---

## 🏗 Project Architecture

```text
┌─────────────────────────────────────────────────┐
│                   Flutter App                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐ │
│  │  Screens  │ │  Models  │ │  Services/State  │ │
│  │ (6 pages) │ │ (Dart)   │ │  (API + Mock)    │ │
│  └──────────┘ └──────────┘ └──────────────────┘ │
└──────────────────────┬──────────────────────────┘
                       │ HTTP (REST JSON)
                       ▼
┌─────────────────────────────────────────────────┐
│              Dart Shelf Backend                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐ │
│  │  Routes  │ │  Service │ │  Seed Data        │ │
│  │ (REST)   │ │ (Logic)  │ │  (4 Categories)   │ │
│  └──────────┘ └──────────┘ └──────────────────┘ │
└─────────────────────────────────────────────────┘
```

The system follows a **client-server** architecture:

- **Frontend**: Flutter mobile app with feature-based folder structure, using `ApiClient` for HTTP communication and `MockData` for offline development previews
- **Backend**: Lightweight Dart HTTP server built with the `shelf` package, exposing RESTful JSON endpoints and in-memory seed data

---

## 🛠 Tech Stack

### Frontend (Flutter)

| Dependency | Version | Purpose |
|---|---|---|
| `flutter` | SDK | Cross-platform UI framework |
| `http` | ^1.2.2 | HTTP client for API communication |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |
| `flutter_lints` | ^4.0.0 | Lint rules for code quality |

### Backend (Dart)

| Dependency | Version | Purpose |
|---|---|---|
| `shelf` | ^1.4.2 | Modular HTTP server framework |
| `shelf_router` | ^1.1.4 | Declarative route definitions |
| `lints` | ^4.0.0 | Static analysis rules |
| `test` | ^1.25.8 | Unit testing framework |

### Development Tools

- **Language**: Dart (SDK >=3.4.0 <4.0.0)
- **UI Design**: Material Design 3
- **Code Editor**: VS Code / Android Studio
- **Version Control**: Git & GitHub

---

## 📱 Screens & Modules

The app features a **bottom navigation bar** with six tabs:

| # | Tab | Icon | Description |
|---|---|---|---|
| 1 | **Home** | 🏠 | Welcome dashboard with green score and quick actions |
| 2 | **Classify** | 🤖 | AI-powered waste identification and category lookup |
| 3 | **Rewards** | 🎁 | Eco-action tracking, point balance, and reward redemption |
| 4 | **Community** | 💬 | Forum with posts about sorting tips, volunteer events, and campus news |
| 5 | **Messages** | ✉️ | Notification inbox with read/unread status |
| 6 | **Profile** | 👤 | User details, level, recycling statistics, and settings |

---

## 🚀 Getting Started

### Prerequisites

Ensure the following tools are installed on your development machine:

- **[Dart SDK](https://dart.dev/get-dart)** (version >=3.4.0)
- **[Flutter SDK](https://docs.flutter.dev/get-started/install)** (version >=3.4.0)
- **Git** (for version control)
- A **code editor** (VS Code or Android Studio recommended)
- An **Android Emulator** or **iOS Simulator** (or a physical device)

Verify your installation:

```bash
dart --version
flutter --version
```

### Running the Backend

1. **Navigate to the backend directory:**

```bash
cd backend
```

2. **Install dependencies:**

```bash
dart pub get
```

3. **Start the server:**

```bash
dart run bin/server.dart
```

If you want to enable Alibaba Cloud image classification, set credentials in
environment variables before starting:

```powershell
$env:ALIYUN_ACCESS_KEY_ID="your_access_key_id"
$env:ALIYUN_ACCESS_KEY_SECRET="your_access_key_secret"
$env:ALIYUN_REGION_ID="cn-shanghai"
dart run bin/server.dart
```

The API server will start at **`http://localhost:8080`**. You should see a confirmation message in the terminal.

4. **Verify the server is running:**

```bash
curl http://localhost:8080/health
```

Expected response:

```json
{
  "status": "ok",
  "service": "EcoSort AI Backend",
  "version": "0.1.0"
}
```

### Running the Frontend

1. **Navigate to the frontend directory:**

```bash
cd frontend
```

2. **Generate platform-specific files (first time only):**

```bash
flutter create .
```

3. **Install dependencies:**

```bash
flutter pub get
```

4. **Run the app:**

```bash
# For a connected device or emulator
flutter run

# For Android Emulator (use host alias to reach localhost backend)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

> 💡 **Note**: The Android Emulator uses `10.0.2.2` as an alias for the host machine's `localhost`. If you're running on a physical device, make sure both the device and the backend server are on the same network and use the host machine's actual IP address.

---

## 📡 API Reference

### Base URL

```text
http://localhost:8080
```

### Endpoints

| Method | Endpoint | Description | Response |
|---|---|---|---|
| `GET` | `/health` | Health check | `{ status, service, version }` |
| `GET` | `/categories` | List all waste categories | `[{ id, title, description, binColor, examples, recyclingTips }]` |
| `POST` | `/classify` | Classify a waste item by name | `{ itemName, category, confidence, suggestions }` |
| `POST` | `/classify-image` | Classify waste from base64 image via Aliyun model | `{ itemName, category, confidence, suggestions }` |
| `GET` | `/vision-logs` | Get latest image-recognition logs | `[{ requestId, imageUrl, elements, rawPayload }]` |
| `GET` | `/eco-actions` | List eco-friendly actions | `[{ id, title, impact, points, completed }]` |
| `GET` | `/rewards` | List available rewards | `[{ id, title, description, requiredPoints, redeemed }]` |
| `GET` | `/forum-posts` | List community forum posts | `[{ id, author, title, content, tag, likes, replies, createdAt }]` |
| `POST` | `/forum-posts` | Create a new forum post | `{ id, ... }` |
| `POST` | `/forum-posts/:postId/like` | Toggle like for one post | `{ id, ... , likedByMe }` |
| `GET` | `/forum-posts/:postId/comments?userId=u1` | List nested comments of one post | `[{ id, content, replies: [...] }]` |
| `POST` | `/forum-posts/:postId/comments` | Create comment/reply | `{ id, postId, parentCommentId, ... }` |
| `POST` | `/forum-comments/:commentId/like` | Toggle like for one comment | `{ id, likes, likedByMe, ... }` |
| `GET` | `/messages` | List user message threads | `[{ id, sender, preview, updatedAt, unread }]` |
| `GET` | `/profile` | Get current user profile | `{ id, name, email, city, level, greenScore, totalRecycledKg, avatarInitials }` |

### Example: Classify a Waste Item

**Request**

```bash
curl -X POST http://localhost:8080/classify \
  -H "Content-Type: application/json" \
  -d '{"itemName": "plastic bottle"}'
```

**Response**

```json
{
  "itemName": "plastic bottle",
  "category": {
    "id": "recyclable",
    "title": "Recyclable Waste",
    "binColor": "Blue",
    "description": "Clean paper, plastic, glass, and metal that can be reused.",
    "examples": ["Plastic bottles", "Cardboard", "Glass jars", "Aluminum cans"],
    "recyclingTips": [
      "Rinse containers before disposal.",
      "Flatten cardboard to save space."
    ]
  },
  "confidence": 0.94,
  "suggestions": [
    "Rinse containers before disposal.",
    "Flatten cardboard to save space."
  ]
}
```

### Example: Get Waste Categories

```bash
curl http://localhost:8080/categories
```

### Example: Classify an Image

```bash
curl -X POST http://localhost:8080/classify-image \
  -H "Content-Type: application/json" \
  -d "{\"fileName\":\"bottle.jpg\",\"imageBase64\":\"<BASE64_IMAGE_DATA>\",\"submittedBy\":\"u1\"}"
```

---

## Environment Variables

### Backend (MySQL)

- `DB_HOST` (default: `localhost`)
- `DB_PORT` (default: `3308`)
- `DB_USER` (default: `root`)
- `DB_PASSWORD` (default: `123456`)
- `DB_NAME` (default: `20260419_ai_intelligent_waste_sorting_identification_app`)
- `DB_CHARSET` (default: `utf8`)

### Backend (Aliyun Vision)

- `ALIYUN_ACCESS_KEY_ID` (required for image classification)
- `ALIYUN_ACCESS_KEY_SECRET` (required for image classification)
- `ALIYUN_REGION_ID` (optional, default: `cn-shanghai`)

### Frontend

- `API_BASE_URL` (default Android emulator: `http://10.0.2.2:8080`)

---

## Database Schema

The backend automatically creates all tables at startup.  
Image recognition logs are stored in `vision_classification_logs`:

```sql
CREATE TABLE IF NOT EXISTS vision_classification_logs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  submitted_by VARCHAR(128) NULL,
  source_file_name VARCHAR(255) NOT NULL,
  image_url TEXT NOT NULL,
  request_id VARCHAR(128) NOT NULL,
  category_label VARCHAR(128) NOT NULL,
  category_score DOUBLE NOT NULL,
  rubbish_label VARCHAR(255) NOT NULL,
  rubbish_score DOUBLE NOT NULL,
  mapped_category_id VARCHAR(32) NOT NULL,
  mapped_category_title VARCHAR(128) NOT NULL,
  raw_response_json LONGTEXT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_vision_logs_created (created_at DESC)
);
```

Forum/community module uses these additional tables:

```sql
CREATE TABLE IF NOT EXISTS forum_post_likes (
  post_id VARCHAR(32) NOT NULL,
  user_id VARCHAR(32) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (post_id, user_id)
);

CREATE TABLE IF NOT EXISTS forum_comments (
  id VARCHAR(40) PRIMARY KEY,
  post_id VARCHAR(32) NOT NULL,
  parent_comment_id VARCHAR(40) NULL,
  author_id VARCHAR(32) NULL,
  author VARCHAR(128) NOT NULL,
  content TEXT NOT NULL,
  likes INT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS forum_comment_likes (
  comment_id VARCHAR(40) NOT NULL,
  user_id VARCHAR(32) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (comment_id, user_id)
);
```

---

## 📁 Project Structure

```text
AI-basedIntelligentWasteSortingAndIdentification/
├── README.md                           # Project documentation
├── .gitignore                          # Git ignore rules
│
├── backend/                            # Dart Shelf HTTP API Server
│   ├── pubspec.yaml                    # Backend dependencies & metadata
│   ├── analysis_options.yaml           # Dart static analysis config
│   │
│   ├── bin/
│   │   └── server.dart                 # Server entry point
│   │
│   ├── lib/
│   │   └── src/
│   │       ├── server.dart             # Server setup & middleware
│   │       ├── routes.dart             # REST API route definitions
│   │       ├── models/
│   │       │   └── app_models.dart     # Data models (Category, User, etc.)
│   │       └── services/
│   │           └── waste_data_service.dart  # Business logic & classification engine
│   │
│   └── test/
│       └── waste_data_service_test.dart # Unit tests for the service layer
│
└── frontend/                           # Flutter Mobile Application
    ├── pubspec.yaml                    # Frontend dependencies & assets
    ├── analysis_options.yaml           # Flutter lint rules
    │
    ├── assets/                         # Static assets (images, fonts, etc.)
    │
    ├── lib/
    │   ├── main.dart                   # App entry point
    │   │
    │   ├── app/
    │   │   ├── waste_sorting_app.dart  # MaterialApp configuration & theme
    │   │   └── app_shell.dart          # Bottom navigation bar shell
    │   │
    │   ├── core/
    │   │   ├── config/
    │   │   │   └── app_config.dart     # App-wide configuration constants
    │   │   ├── models/                 # Dart data models
    │   │   │   ├── app_user.dart
    │   │   │   ├── eco_action.dart
    │   │   │   ├── forum_post.dart
    │   │   │   ├── message_thread.dart
    │   │   │   ├── reward.dart
    │   │   │   └── waste_category.dart
    │   │   ├── services/
    │   │   │   └── api_client.dart     # HTTP client for backend communication
    │   │   ├── state/
    │   │   │   └── mock_data.dart      # Mock data for offline development
    │   │   └── theme/
    │   │       └── app_theme.dart      # Material Design 3 theme definitions
    │   │
    │   └── features/                   # Feature-based UI modules
    │       ├── home/
    │       │   └── home_page.dart      # Home dashboard screen
    │       ├── classify/
    │       │   └── classify_page.dart  # AI classification screen
    │       ├── rewards/
    │       │   └── rewards_page.dart   # Eco rewards & points screen
    │       ├── community/
    │       │   └── community_page.dart # Community forum screen
    │       ├── messages/
    │       │   └── messages_page.dart  # In-app messages screen
    │       └── profile/
    │           └── profile_page.dart   # User profile screen
    │
    └── test/
        └── widget_test.dart            # Basic widget test
```

---

## 🗺 Roadmap

- [x] Project scaffolding (Flutter + Dart Shelf)
- [x] Keyword-based classification engine
- [x] Six core feature screens with mock data
- [x] REST API with 8 endpoints
- [x] Unit tests for backend service
- [ ] **Image-based classification** (camera/gallery input + computer vision)
- [ ] Replace keyword engine with a real **ML model** (TensorFlow Lite / cloud vision API)
- [ ] **Persistent database** (PostgreSQL / Firebase Firestore)
- [ ] **User authentication** (email/password + social login)
- [ ] Push notifications for eco-tips and reward alerts
- [ ] Leaderboard & gamification enhancements
- [ ] Multi-language support (i18n)
- [ ] iOS and web platform support
- [ ] CI/CD pipeline for automated testing & deployment

---

## 🤝 Contributing

Contributions are welcome! This is a green-tech open-source project aiming to make a positive environmental impact.

### How to Contribute

1. **Fork** this repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** your changes: `git commit -m 'feat: add amazing feature'`
4. **Push** to your branch: `git push origin feature/amazing-feature`
5. **Open** a Pull Request

### Commit Convention

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` — A new feature
- `fix:` — A bug fix
- `docs:` — Documentation changes
- `refactor:` — Code restructuring without functional changes
- `test:` — Adding or updating tests
- `chore:` — Maintenance tasks (dependency updates, config changes)

### Development Notes

- The **frontend currently uses mock data** for stable UI previews. Switch to `ApiClient` by changing the data source in the feature pages.
- The **backend uses in-memory seed data** and a keyword-based classifier. This is intentionally simple so it can be replaced with a real AI service.
- All **UI text is in English**. i18n support is planned for a future release.

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <sub>Built with ❤️ for a greener planet 🌍</sub>
  <br>
  <sub>© 2025 EcoSort AI. All rights reserved.</sub>
</p>
