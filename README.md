# dBiller

Generic Billing Application with Flutter Frontend and FastAPI Backend.

## Features

- **User Management**: Registration, Login (JWT), Role-based access.
- **Device Security**: Max 2 devices per account.
- **Inventory**: Manage products, stock, prices, image recognition.
- **Billing (POS)**: Cart system, total calculation, billing history.
- **Infrastructure**: Neon (PostgreSQL), Railway (Backend), Cloudflare R2 (Images).

## Project Structure

- `backend/`: FastAPI application.
- `frontend/`: Flutter application.

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
    - Connects to localhost:8001.

## Production

for production build:

- Frontend: `flutter build web -t lib/main_prod.dart` or `flutter build apk -t lib/main_prod.dart`
- Backend: Deploy to Railway (uses Procfile).

## License Generation

To create a new registration key for the admin user:

### Local Development

1.  Navigate to `backend/`.
2.  Ensure your virtual environment is active.
3.  Run: `python generate_license.py`

### Production (Railway)

You can run the script using the Railway CLI or via a one-off command in the dashboard (if supported), or run it locally by connecting to the production database:

**Option 1: Run locally against Prod DB**

1.  Get your `DATABASE_URL` from Railway.
2.  Run in your local terminal:
    - **Windows (PowerShell)**:
      ```powershell
      $env:DATABASE_URL="postgresql://user:pass@host:port/dbname..."
      python generate_license.py
      ```
    - **Linux/Mac**:
      ```bash
      export DATABASE_URL="postgresql://user:pass@host:port/dbname..."
      python generate_license.py
      ```

**Option 2: Railway CLI**

```bash
railway run python generate_license.py
```

## Documentation

See `setup_guide.md` and `walkthrough.md` in `docs/` artifacts (or requested location).
