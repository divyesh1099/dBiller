# Setup & Testing Guide

## 1. Prerequisites
-   **Docker Desktop** (Installed & Running)
-   **Python 3.10+**
-   **Flutter SDK**
-   **PostgreSQL Client** (Optional, for debugging)

## 2. Infrastructure (Database)
Start the local PostgreSQL database using Docker.
```bash
docker-compose up -d
```
*   **User**: `dbiller_user`
*   **Password**: `dbiller_password`
*   **DB Name**: `dbiller_dev`
*   **Port**: `5432`

## 3. Backend Setup
1.  Navigate to `backend/`.
2.  Create/Update `.env` file:
    ```bash
    DATABASE_URL=postgresql://dbiller_user:dbiller_password@localhost:5432/dbiller_dev
    SECRET_KEY=dev_secret_key
    # R2 Config (Required for Image Uploads)
    R2_ENDPOINT_URL=...
    R2_ACCESS_KEY_ID=...
    R2_SECRET_ACCESS_KEY=...
    R2_BUCKET_NAME=dbiller-images
    ```
3.  Install dependencies:
    ```bash
    pip install -r requirements.txt
    ```
4.  **Start Backend**:
    ```bash
    uvicorn main:app --reload --port 8001
    ```
    *   The database tables will be created automatically on startup.

## 4. License Generation
Onboarding is restricted. You must generate a License Key to register a new user.
1.  Ensure Backend is running (or at least DB is up).
2.  Run the generator script:
    ```bash
    python generate_license.py
    ```
3.  Copy the output Key (e.g., `550e8400-e29b-...`).

## 5. Frontend Setup
1.  Navigate to `frontend/`.
2.  Get dependencies:
    ```bash
    flutter pub get
    ```
3.  **Run in Dev Mode**:
    ```bash
    flutter run -t lib/main_dev.dart
    ```
    *   Select Chrome or a connected Mobile Device.

## 6. Testing Flow
1.  **Register**:
    *   Go to `/register` (via "Create Account" on Login).
    *   Enter Username, Password.
    *   Enter the **License Key** generated in Step 4.
    *   Submit -> Success.
2.  **Login**:
    *   Log in with the new credentials.
    *   You are now on the Dashboard.
3.  **Test Features**:
    *   **Inventory**: Add a product (requires R2 config for images).
    *   **Billing**: Create a bill.
    *   **Device Limit**: Try logging in from a 3rd different device (Incognito, different browser) -> Should be blocked.
