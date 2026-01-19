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

## Superadmin and Organization Flow

### Bootstrap a Superadmin

- Set `SUPERADMIN_USERNAME` and `SUPERADMIN_PASSWORD` in the backend environment before starting the API.
- On first startup, the backend creates a single superadmin account (superadmins can only be created by the backend).
- Log in with those credentials to access superadmin-only pages (Organizations, Plan Manager, Superadmin Dashboard).

### Register Organizations

- `/register` creates a new organization and assigns the first user as the organization admin.
- Admin email is required and used for subscription communication.
- Superadmins can also onboard organizations from the Superadmin Dashboard (payments are recorded manually).
- Superadmins can manage admins and users across organizations.
- Organizations list and management are superadmin-only.

### Manage Plans and Subscriptions

- Superadmins manage the subscription catalog in Plan Manager and can activate/deactivate plans.
- Superadmins can onboard organizations and assign or change their plans.
- Organization admins (or users with `subscriptions.manage`) can view, change, or opt out in `My Subscriptions`.
- Cancellations within 7 days receive a full refund (`refund_eligible = true`); later cancellations are marked as `cancelled`.

### Seeded Plans

- **Basic**: core features, 1 admin user only, analytics disabled.
- **Premium**: unlimited users, analytics disabled.
- **Enterprise**: unlimited users with analytics.
- Plan limits are stored in `subscription.limits` (`max_users`, `analytics_enabled`). Update pricing in Plan Manager.
- New organizations are auto-assigned to the Basic plan.

### Razorpay Payments

- Set `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` in the backend environment.
- Create order: `POST /payments/razorpay/order` (requires `subscriptions.manage`).
- Verify payment: `POST /payments/razorpay/verify` (creates the organization subscription).
- Android checkout uses `razorpay_flutter` and is wired from `My Subscriptions`.

### Permissions and Roles

- Permissions are fixed and seeded at startup (admins and superadmins always have all permissions).
- Default permissions include:
  `users.view`, `users.manage`, `roles.view`, `roles.manage`, `permissions.view`, `permissions.assign`,
  `subscriptions.view`, `subscriptions.manage`, `plans.manage`, `invoices.view`, `invoices.manage`,
  `orders.view`, `orders.manage`, `inventory.view`, `inventory.manage`, `suppliers.view`, `suppliers.manage`,
  `checkout.manage`, `analytics.view`.
- Default roles seeded: `Manager`, `Billing`, `Inventory` (admins can assign roles and permissions).
- At least one admin must remain active per organization.

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
