# AGENTS.md

## 1. Project Mission

This project is an international student innovation project focused on:

- Green and low-carbon living
- Environmental protection awareness
- Connected community participation
- AI-assisted waste sorting education

The product is an AI-based intelligent waste sorting and identification app built with Dart and Flutter.

Core user-facing modules:

1. Home
2. Classification
3. Eco behavior assessment and rewards
4. Community forum
5. Messages
6. Profile

All code changes must preserve this mission and module set.

## 2. Scope and Architecture Constraints

Repository structure:

- `frontend/`: Flutter client app
- `backend/`: Dart server (`shelf`) with MySQL-backed data service
- `dev-android.ps1`: local Android + backend launch workflow

Architecture expectations:

- Frontend and backend remain decoupled through REST APIs.
- Frontend must not embed backend credentials or SQL logic.
- Backend must not depend on frontend UI models.
- Shared behavior is synchronized through API contracts, not direct code coupling.

## 3. Frontend Constraints (Flutter)

### 3.1 Navigation and Feature Boundaries

Do not remove or repurpose the six top-level destinations defined in:

- `frontend/lib/app/app_shell.dart`

Tabs must remain conceptually aligned with:

- Home
- Classify
- Rewards
- Forum
- Messages
- Profile

### 3.2 Configuration and Environment

API base URL is controlled through compile-time define:

- `API_BASE_URL`
- Default value in `frontend/lib/core/config/app_config.dart` is `http://10.0.2.2:8080`

Any environment-specific behavior must use configuration flags, not hardcoded one-off edits in feature pages.

### 3.3 API Access

All backend calls should go through:

- `frontend/lib/core/services/api_client.dart`

Avoid introducing scattered ad-hoc HTTP calls inside feature widgets unless there is a strong documented reason.

### 3.4 Offline/Mock Behavior

When backend is unavailable, app behavior should degrade gracefully using local fallback or mock data:

- `frontend/lib/core/state/mock_data.dart`

Do not make the app crash or become unusable if the backend temporarily fails.

## 4. Backend Constraints (Dart + Shelf)

### 4.1 Server and Routing

Server entry and setup:

- `backend/bin/server.dart`
- `backend/lib/src/server.dart`

Routes are defined in:

- `backend/lib/src/routes.dart`

Preserve existing endpoint semantics unless explicitly migrating with backward compatibility notes.

### 4.2 Data Service Abstraction

Keep `WasteDataService` as the backend contract:

- `backend/lib/src/services/waste_data_service.dart`

Current production implementation is MySQL-based:

- `backend/lib/src/services/mysql_waste_data_service.dart`

In-memory implementation is for fallback/testing:

- `backend/lib/src/services/in_memory_waste_data_service.dart`

Do not bypass the service layer by embedding SQL in route handlers.

### 4.3 Database Configuration

Environment-driven DB config is centralized in:

- `backend/lib/src/config/database_config.dart`

Use environment variables (`DB_HOST`, `DB_PORT`, etc.) for deployment-specific settings.
Do not hardcode environment-specific credentials in new code.

## 5. API Contract Constraints

The following endpoints are part of the current baseline and should remain stable:

- `GET /health`
- `GET /categories`
- `POST /classify`
- `GET /eco-actions`
- `GET /rewards`
- `GET /forum-posts`
- `GET /messages`
- `GET /profile`

If an endpoint payload changes:

1. Update backend route response
2. Update frontend model parsing and API client
3. Update tests and documentation together in the same change

No silent contract drift is allowed.

## 6. AI Feature Constraints

Current classifier behavior is keyword/rule-based (prototype stage).

Allowed:

- Improve matching quality
- Add confidence calibration
- Prepare extension points for future ML/CV models

Not allowed without explicit scope approval:

- Breaking the existing `/classify` response shape
- Introducing heavyweight model runtimes that block local development
- Removing fallback behavior in low-connectivity scenarios

## 7. UX and Product Constraints

All UI changes must keep environmental education and behavior motivation visible:

- Clear waste category guidance
- Actionable recycling tips
- Reward feedback loop
- Community engagement cues

Do not replace educational content with purely cosmetic UI.

## 8. Code Quality Constraints

General:

- Keep changes minimal, purposeful, and reversible.
- Prefer clear naming over clever shortcuts.
- Avoid broad refactors unrelated to the requested task.

Dart/Flutter:

- Keep `flutter analyze` clean where feasible.
- Add or update tests for behavior changes when practical.

Backend:

- Keep routes thin and business logic in services.
- Handle invalid input with explicit JSON errors and status codes.

## 9. Local Development and Integration Constraints

Typical local run flow:

1. Start backend:
   - `cd backend`
   - `dart pub get`
   - `dart run bin/server.dart`
2. Start frontend:
   - `cd frontend`
   - `flutter pub get`
   - `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080`

Windows helper script:

- `dev-android.ps1` may be used for one-command startup.

When editing startup scripts:

- Keep behavior observable through clear logs.
- Avoid destructive process/file operations.

## 10. Documentation Constraints

When behavior, setup, or contracts change, update documentation in the same pull/change set:

- `README.md`
- Relevant inline comments
- This `AGENTS.md` file if governance rules evolve

## 11. Non-Goals

The following are out of scope unless explicitly requested:

- Rebranding away from eco/green mission
- Removing any of the six core modules
- Replacing Dart/Flutter stack with another framework
- Introducing incompatible API redesign without migration path

## 12. Change Acceptance Checklist

A change is acceptable only if:

1. It supports or preserves the green-tech mission.
2. It does not break core six-module navigation.
3. Frontend-backend API compatibility is maintained.
4. Local Android emulator flow remains workable.
5. Documentation and tests are updated when needed.

