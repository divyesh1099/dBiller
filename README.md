# dBiller

Generic Billing Application with Flutter Frontend and FastAPI Backend.

## Features
-   **User Management**: Registration, Login (JWT), Role-based access.
-   **Device Security**: Max 2 devices per account.
-   **Inventory**: Manage products, stock, prices, image recognition.
-   **Billing (POS)**: Cart system, total calculation, billing history.
-   **Infrastructure**: Neon (PostgreSQL), Railway (Backend), Cloudflare R2 (Images).

## Project Structure
-   `backend/`: FastAPI application.
-   `frontend/`: Flutter application.

## Quick Start (Development)

### Backend
1.  Navigate to `backend/`.
2.  Create virtual env: `python -m venv venv` & source it.
3.  Install dependencies: `pip install -r requirements.txt`.
4.  Create `.env` file (see `deployment_setup/setup_guide.md`).
5.  Run: `uvicorn main:app --reload --port 8001`

### Frontend
1.  Navigate to `frontend/`.
2.  Install packages: `flutter pub get`.
3.  Run (Dev Mode): `flutter run -t lib/main_dev.dart`
    -   Connects to localhost:8001.

## Production
for production build:
-   Frontend: `flutter build web -t lib/main_prod.dart` or `flutter build apk -t lib/main_prod.dart`
-   Backend: Deploy to Railway (uses Procfile).

## Documentation
See `setup_guide.md` and `walkthrough.md` in `docs/` artifacts (or requested location).
