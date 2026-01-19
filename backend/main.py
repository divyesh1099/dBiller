import os
import io
import csv
import re
import datetime
import json
import logging
import difflib
from decimal import Decimal
from datetime import timedelta
from typing import List, Optional
from fastapi import FastAPI, Depends, HTTPException, status, Form, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import or_, text
from database import engine, Base
import models, schemas, database
import auth

try:
    import razorpay
except Exception:
    razorpay = None

try:
    import pytesseract
    from pytesseract import Output
    from PIL import Image, ImageOps, ImageFilter
    # Windows fallback for tesseract path
    if os.name == 'nt':
        possible_paths = [
            r"C:\Program Files\Tesseract-OCR\tesseract.exe",
            r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
            r"C:\ProgramData\chocolatey\bin\tesseract.exe",
        ]
        # Check if tesseract is in PATH first
        import shutil
        if not shutil.which("tesseract"):
            for path in possible_paths:
                if os.path.exists(path):
                    pytesseract.pytesseract.tesseract_cmd = path
                    print(f"Set tesseract cmd to: {path}")
                    break
except Exception as e:
    print(f"Warning: OCR dependencies missing: {e}")
    pytesseract = None
    Image = None

# Create database tables
models.Base.metadata.create_all(bind=engine)


from sqlalchemy import inspect

def ensure_optional_columns():
    """Add columns that may be missing on older databases safely."""
    inspector = inspect(engine)
    
    # Map of table -> list of (column_name, column_type_def)
    required_columns = {
        "products": [("category", "VARCHAR"), ("organization_id", "INTEGER")],
        "stores": [("dummy_check", "INTEGER")],
        "users": [
            ("email", "VARCHAR"),
            ("phone", "VARCHAR"),
            ("profile_photo", "VARCHAR"),
            ("organization_id", "INTEGER"),
            ("full_name", "VARCHAR"),
            ("user_code", "VARCHAR"),
        ],
        "organizations": [
            ("logo_url", "VARCHAR"),
            ("status", "VARCHAR"),
            ("subscription_id", "INTEGER"),
            ("trial_ends_at", "DATETIME"),
            ("current_period_end", "DATETIME"),
            ("node_limit", "INTEGER"),
        ],
        "subscriptions": [
            ("currency", "VARCHAR"),
            ("monthly_price", "FLOAT"),
            ("annual_price", "FLOAT"),
            ("features", "TEXT"),
            ("limits", "TEXT"),
            ("description", "TEXT"),
            ("badge_text", "VARCHAR"),
            ("is_featured", "BOOLEAN"),
            ("is_active", "BOOLEAN"),
            ("created_at", "DATETIME"),
        ],
        "suppliers": [
            ("contact_name", "VARCHAR"),
            ("status", "VARCHAR"),
            ("logo_url", "VARCHAR"),
            ("category", "VARCHAR"),
            ("supplier_code", "VARCHAR"),
        ],
        "items": [
            ("category", "VARCHAR"),
            ("tags", "TEXT"),
            ("barcode", "VARCHAR"),
            ("reorder_point", "INTEGER"),
            ("min_stock", "INTEGER"),
            ("max_stock", "INTEGER"),
            ("warehouse_aisle", "VARCHAR"),
            ("bin_location", "VARCHAR"),
            ("ai_verified", "BOOLEAN"),
            ("ai_confidence", "FLOAT"),
        ],
        "orders": [
            ("order_number", "VARCHAR"),
            ("supplier_id", "INTEGER"),
            ("customer_name", "VARCHAR"),
            ("customer_email", "VARCHAR"),
            ("customer_phone", "VARCHAR"),
            ("billing_address", "TEXT"),
            ("notes", "TEXT"),
            ("confirmed_at", "DATETIME"),
            ("shipped_at", "DATETIME"),
            ("delivered_at", "DATETIME"),
            ("cancelled_at", "DATETIME"),
            ("expected_delivery_at", "DATETIME"),
        ],
        "order_items": [
            ("sku", "VARCHAR"),
            ("image_url", "VARCHAR"),
            ("ai_verified", "BOOLEAN"),
            ("ai_confidence", "FLOAT"),
        ],
        "invoices": [
            ("source_url", "VARCHAR"),
            ("source_type", "VARCHAR"),
            ("ai_extracted", "BOOLEAN"),
            ("paid_at", "DATETIME"),
        ],
        "invoice_items": [
            ("sku", "VARCHAR"),
            ("image_url", "VARCHAR"),
        ],
        "bills": [
            ("organization_id", "INTEGER"),
        ],
    }

    try:
        existing_tables = inspector.get_table_names()
        with engine.begin() as conn:
            for table, columns in required_columns.items():
                if table in existing_tables:
                    existing_cols = [c["name"] for c in inspector.get_columns(table)]
                    for col_name, col_def in columns:
                        if col_name not in existing_cols:
                            try:
                                conn.execute(text(f"ALTER TABLE {table} ADD COLUMN {col_name} {col_def}"))
                            except Exception as e:
                                print(f"Migration Error on {table}.{col_name}: {e}")
                                # In Postgres, checking existence first should prevent this, but if it fails,
                                # we must ensure we don't break the transaction for others if using a single block.
                                # However, inspector check is the primary safety.
    except Exception as e:
        print(f"Schema migration failed: {e}")

ensure_optional_columns()

DEFAULT_PERMISSIONS = [
    ("users.view", "View users"),
    ("users.manage", "Create and manage users"),
    ("roles.view", "View roles"),
    ("roles.manage", "Create and manage roles"),
    ("permissions.view", "View permissions"),
    ("permissions.assign", "Assign permissions to roles"),
    ("subscriptions.view", "View subscriptions"),
    ("subscriptions.manage", "Manage subscriptions"),
    ("plans.manage", "Manage subscription plans"),
    ("invoices.view", "View invoices"),
    ("invoices.manage", "Create and manage invoices"),
    ("orders.view", "View orders"),
    ("orders.manage", "Create and manage orders"),
    ("inventory.view", "View inventory"),
    ("inventory.manage", "Create and manage inventory items"),
    ("suppliers.view", "View suppliers"),
    ("suppliers.manage", "Create and manage suppliers"),
    ("checkout.manage", "Create checkout bills"),
    ("analytics.view", "View analytics"),
]

DEFAULT_ROLE_TEMPLATES = [
    {
        "name": "Manager",
        "description": "Full operational access",
        "permissions": [
            "users.view",
            "roles.view",
            "permissions.view",
            "subscriptions.view",
            "subscriptions.manage",
            "invoices.view",
            "invoices.manage",
            "orders.view",
            "orders.manage",
            "inventory.view",
            "inventory.manage",
            "suppliers.view",
            "suppliers.manage",
            "checkout.manage",
            "analytics.view",
        ],
    },
    {
        "name": "Billing",
        "description": "Billing and checkout operations",
        "permissions": [
            "invoices.view",
            "invoices.manage",
            "orders.view",
            "checkout.manage",
            "subscriptions.view",
        ],
    },
    {
        "name": "Inventory",
        "description": "Inventory and supplier operations",
        "permissions": [
            "inventory.view",
            "inventory.manage",
            "suppliers.view",
            "suppliers.manage",
        ],
    },
]
DEFAULT_SUBSCRIPTIONS = [
    {
        "name": "Basic",
        "description": "Single admin access to core billing and inventory features.",
        "price": 0.0,
        "currency": "USD",
        "monthly_price": 0.0,
        "annual_price": 0.0,
        "features": [
            "Inventory",
            "Billing",
            "Orders",
            "Suppliers",
            "Checkout",
            "Single admin user",
        ],
        "limits": {"max_users": 1, "analytics_enabled": False},
        "badge_text": "Starter",
        "is_featured": False,
        "is_active": True,
    },
    {
        "name": "Premium",
        "description": "Unlimited users with core features, analytics excluded.",
        "price": 0.0,
        "currency": "USD",
        "monthly_price": 0.0,
        "annual_price": 0.0,
        "features": [
            "Inventory",
            "Billing",
            "Orders",
            "Suppliers",
            "Checkout",
            "Unlimited users",
        ],
        "limits": {"max_users": -1, "analytics_enabled": False},
        "badge_text": "Team",
        "is_featured": False,
        "is_active": True,
    },
    {
        "name": "Enterprise",
        "description": "Unlimited users with analytics access.",
        "price": 0.0,
        "currency": "USD",
        "monthly_price": 0.0,
        "annual_price": 0.0,
        "features": [
            "Inventory",
            "Billing",
            "Orders",
            "Suppliers",
            "Checkout",
            "Unlimited users",
            "Analytics",
        ],
        "limits": {"max_users": -1, "analytics_enabled": True},
        "badge_text": "Analytics",
        "is_featured": True,
        "is_active": True,
    },
]
REFUND_WINDOW_DAYS = 7

def seed_permissions():
    db = database.SessionLocal()
    try:
        existing = {p.name for p in db.query(models.Permission).all()}
        for name, description in DEFAULT_PERMISSIONS:
            if name in existing:
                continue
            db.add(models.Permission(name=name, description=description))
        db.commit()
    finally:
        db.close()

def seed_roles():
    db = database.SessionLocal()
    try:
        permissions_by_name = {
            p.name: p for p in db.query(models.Permission).all()
        }
        existing = {r.name for r in db.query(models.Role).all()}
        for template in DEFAULT_ROLE_TEMPLATES:
            if template["name"] in existing:
                continue
            role = models.Role(
                name=template["name"],
                description=template["description"],
            )
            role.permissions = [
                permissions_by_name[name]
                for name in template["permissions"]
                if name in permissions_by_name
            ]
            db.add(role)
        db.commit()
    finally:
        db.close()

def seed_subscriptions():
    db = database.SessionLocal()
    try:
        existing = {s.name for s in db.query(models.Subscription).all()}
        for template in DEFAULT_SUBSCRIPTIONS:
            if template["name"] in existing:
                continue
            db.add(models.Subscription(**template))
        db.commit()
    finally:
        db.close()

def bootstrap_superadmin():
    username = os.getenv("SUPERADMIN_USERNAME")
    password = os.getenv("SUPERADMIN_PASSWORD")
    if not username or not password:
        return
    db = database.SessionLocal()
    try:
        existing_superadmin = (
            db.query(models.User).filter(models.User.role == auth.ROLE_SUPERADMIN).first()
        )
        if existing_superadmin:
            return
        existing_user = db.query(models.User).filter(models.User.username == username).first()
        if existing_user:
            return
        db_user = models.User(
            username=username,
            hashed_password=auth.get_password_hash(password),
            role=auth.ROLE_SUPERADMIN,
            is_active=True,
        )
        db.add(db_user)
        db.commit()
    finally:
        db.close()

seed_permissions()
seed_roles()
seed_subscriptions()
bootstrap_superadmin()


app = FastAPI(title="dBiller API")
if not os.path.exists("uploads"):
    os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

PUBLIC_BASE_URL = os.getenv("PUBLIC_BASE_URL", "http://localhost:8001").rstrip("/")

logger = logging.getLogger("dbiller")
logging.basicConfig(level=logging.INFO)

# CORS setup: allow localhost on any port for dev; configurable via FRONTEND_ORIGINS (comma-separated)
default_origins = [
    "http://localhost",
    "http://127.0.0.1",
]
origins_env = os.getenv("FRONTEND_ORIGINS")
if origins_env:
    allow_origins = [o.strip() for o in origins_env.split(",") if o.strip()]
    origin_regex = None
else:
    allow_origins = ["*"]
    origin_regex = r"http://(localhost|127\.0\.0\.1)(:\d+)?"

app.add_middleware(
    CORSMiddleware,
    allow_origins=allow_origins,
    allow_origin_regex=origin_regex,
    allow_credentials=False,  # allow "*" with no credentials requirement
    allow_methods=["*"],
    allow_headers=["*"],
)

def normalize_product_url(product: models.Product):
    """Pass-through: Validation moved to client-side to support relative local URLs."""
    return product

def require_org_id(current_user: schemas.User) -> Optional[int]:
    if auth.is_superadmin(current_user):
        return None
    if current_user.organization_id is None:
        raise HTTPException(status_code=400, detail="Organization not set for user")
    return current_user.organization_id

def ensure_org_access(entity_org_id: Optional[int], current_user: schemas.User):
    if auth.is_superadmin(current_user):
        return
    if entity_org_id is None or entity_org_id != current_user.organization_id:
        raise HTTPException(status_code=403, detail="Access denied")

def ensure_admin_present(db: database.SessionLocal, org_id: Optional[int], exclude_user_id: Optional[int] = None):
    if org_id is None:
        return
    query = db.query(models.User).filter(
        models.User.organization_id == org_id,
        models.User.role == auth.ROLE_ADMIN,
        models.User.is_active == True,
    )
    if exclude_user_id is not None:
        query = query.filter(models.User.id != exclude_user_id)
    if query.count() == 0:
        raise HTTPException(status_code=400, detail="At least one admin is required")

def ensure_admin_email_present(db: database.SessionLocal, org_id: Optional[int]):
    if org_id is None:
        return
    admin = (
        db.query(models.User)
        .filter(
            models.User.organization_id == org_id,
            models.User.role.in_([auth.ROLE_ADMIN, auth.ROLE_SUPERADMIN]),
            models.User.is_active == True,
            models.User.email.isnot(None),
            models.User.email != "",
        )
        .first()
    )
    if not admin:
        raise HTTPException(status_code=400, detail="Admin email is required for subscription management")

def require_permission(permission_name: str):
    def dependency(current_user: schemas.User = Depends(auth.get_current_user)):
        if not auth.has_permission(current_user, permission_name):
            raise HTTPException(status_code=403, detail=f"Missing permission: {permission_name}")
        return current_user
    return dependency

def is_refund_eligible(started_at: Optional[datetime.datetime]) -> bool:
    if started_at is None:
        return False
    return datetime.datetime.utcnow() - started_at <= timedelta(days=REFUND_WINDOW_DAYS)

def annotate_refund_status(subscription: models.OrganizationSubscription):
    subscription.refund_eligible = is_refund_eligible(subscription.started_at)
    return subscription

def get_roles_by_ids(db: database.SessionLocal, role_ids: Optional[List[int]]):
    if not role_ids:
        return []
    unique_ids = list({rid for rid in role_ids if rid is not None})
    if not unique_ids:
        return []
    roles = db.query(models.Role).filter(models.Role.id.in_(unique_ids)).all()
    if len(roles) != len(unique_ids):
        raise HTTPException(status_code=404, detail="One or more roles not found")
    return roles

def get_permissions_by_ids(db: database.SessionLocal, permission_ids: Optional[List[int]]):
    if not permission_ids:
        return []
    unique_ids = list({pid for pid in permission_ids if pid is not None})
    if not unique_ids:
        return []
    permissions = db.query(models.Permission).filter(models.Permission.id.in_(unique_ids)).all()
    if len(permissions) != len(unique_ids):
        raise HTTPException(status_code=404, detail="One or more permissions not found")
    return permissions

def get_subscription_by_id(db: database.SessionLocal, subscription_id: Optional[int]):
    if subscription_id is None:
        return None
    subscription = db.query(models.Subscription).filter(models.Subscription.id == subscription_id).first()
    if not subscription:
        raise HTTPException(status_code=404, detail="Subscription not found")
    return subscription

def get_subscription_limits(subscription: Optional[models.Subscription]) -> dict:
    if subscription is None:
        return {}
    limits = subscription.limits or {}
    if isinstance(limits, str):
        try:
            limits = json.loads(limits)
        except json.JSONDecodeError:
            limits = {}
    if not isinstance(limits, dict):
        return {}
    return limits

def get_org_subscription(db: database.SessionLocal, org_id: Optional[int]) -> Optional[models.Subscription]:
    if org_id is None:
        return None
    org = db.query(models.Organization).filter(models.Organization.id == org_id).first()
    if not org or org.subscription_id is None:
        return None
    if org.subscription:
        return org.subscription
    return db.query(models.Subscription).filter(models.Subscription.id == org.subscription_id).first()

def get_plan_max_users(subscription: Optional[models.Subscription]) -> Optional[int]:
    limits = get_subscription_limits(subscription)
    max_users = limits.get("max_users")
    if max_users is None:
        return None
    try:
        max_users = int(max_users)
    except (TypeError, ValueError):
        return None
    if max_users <= 0:
        return None
    return max_users

def ensure_user_limit(db: database.SessionLocal, org_id: Optional[int], exclude_user_id: Optional[int] = None):
    if org_id is None:
        return
    subscription = get_org_subscription(db, org_id)
    max_users = get_plan_max_users(subscription)
    if max_users is None:
        return
    query = db.query(models.User).filter(models.User.organization_id == org_id)
    if exclude_user_id is not None:
        query = query.filter(models.User.id != exclude_user_id)
    if query.count() >= max_users:
        raise HTTPException(status_code=400, detail="User limit reached for the current subscription plan")

def get_razorpay_client():
    if razorpay is None:
        raise HTTPException(status_code=500, detail="Razorpay SDK not available")
    key_id = os.getenv("RAZORPAY_KEY_ID")
    key_secret = os.getenv("RAZORPAY_KEY_SECRET")
    if not key_id or not key_secret:
        raise HTTPException(status_code=500, detail="Razorpay is not configured")
    return razorpay.Client(auth=(key_id, key_secret)), key_id

def get_basic_subscription(db: database.SessionLocal) -> Optional[models.Subscription]:
    return (
        db.query(models.Subscription)
        .filter(models.Subscription.name.ilike("basic"))
        .first()
    )

def assign_default_subscription(
    db: database.SessionLocal,
    org_id: int,
    current_user: models.User,
):
    basic = get_basic_subscription(db)
    if not basic:
        return
    apply_subscription_change(
        db,
        org_id,
        schemas.OrganizationSubscriptionCreate(subscription_id=basic.id),
        current_user,
        allow_price_override=True,
    )

def get_supplier_by_id(db: database.SessionLocal, supplier_id: Optional[int], current_user: schemas.User):
    if supplier_id is None:
        return None
    supplier = db.query(models.Supplier).filter(models.Supplier.id == supplier_id).first()
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    ensure_org_access(supplier.organization_id, current_user)
    return supplier

def build_order_items(db: database.SessionLocal, items: List[schemas.OrderItemCreate], current_user: schemas.User):
    if not items:
        raise HTTPException(status_code=400, detail="Order requires at least one item")
    order_items = []
    subtotal = 0.0
    for item in items:
        if not item.item_id and not item.description:
            raise HTTPException(status_code=400, detail="Order item requires item_id or description")
        unit_price = item.unit_price
        description = item.description
        sku = item.sku
        image_url = item.image_url
        ai_verified = item.ai_verified
        ai_confidence = item.ai_confidence
        if item.item_id:
            db_item = db.query(models.Item).filter(models.Item.id == item.item_id).first()
            if not db_item:
                raise HTTPException(status_code=404, detail=f"Item with id {item.item_id} not found")
            ensure_org_access(db_item.organization_id, current_user)
            if unit_price is None:
                unit_price = db_item.unit_price
            if not description:
                description = db_item.name
            if not sku:
                sku = db_item.sku
            if not image_url:
                image_url = db_item.image_url
            if ai_verified is None:
                ai_verified = db_item.ai_verified
            if ai_confidence is None:
                ai_confidence = db_item.ai_confidence
        if unit_price is None:
            raise HTTPException(status_code=400, detail="unit_price required when item_id is not provided")
        line_total = unit_price * item.quantity
        subtotal += line_total
        order_items.append(
            models.OrderItem(
                item_id=item.item_id,
                description=description,
                sku=sku,
                image_url=image_url,
                quantity=item.quantity,
                unit_price=unit_price,
                line_total=line_total,
                ai_verified=ai_verified or False,
                ai_confidence=ai_confidence,
            )
        )
    return subtotal, order_items

def build_invoice_items(db: database.SessionLocal, items: List[schemas.InvoiceItemCreate], current_user: schemas.User):
    if not items:
        raise HTTPException(status_code=400, detail="Invoice requires at least one item")
    invoice_items = []
    subtotal = 0.0
    for item in items:
        if not item.item_id and not item.description:
            raise HTTPException(status_code=400, detail="Invoice item requires item_id or description")
        unit_price = item.unit_price
        description = item.description
        sku = item.sku
        image_url = item.image_url
        if item.item_id:
            db_item = db.query(models.Item).filter(models.Item.id == item.item_id).first()
            if not db_item:
                raise HTTPException(status_code=404, detail=f"Item with id {item.item_id} not found")
            ensure_org_access(db_item.organization_id, current_user)
            if unit_price is None:
                unit_price = db_item.unit_price
            if not description:
                description = db_item.name
            if not sku:
                sku = db_item.sku
            if not image_url:
                image_url = db_item.image_url
        if unit_price is None:
            raise HTTPException(status_code=400, detail="unit_price required when item_id is not provided")
        line_total = unit_price * item.quantity
        subtotal += line_total
        invoice_items.append(
            models.InvoiceItem(
                item_id=item.item_id,
                description=description,
                sku=sku,
                image_url=image_url,
                quantity=item.quantity,
                unit_price=unit_price,
                line_total=line_total,
            )
        )
    return subtotal, invoice_items

def generate_invoice_number():
    return f"INV-{datetime.datetime.utcnow().strftime('%Y%m%d%H%M%S')}"

def generate_order_number(order_type: Optional[str]):
    prefix = "ORD"
    if order_type:
        lowered = order_type.lower()
        if lowered.startswith("purchase"):
            prefix = "PO"
        elif lowered.startswith("sales"):
            prefix = "SO"
    return f"{prefix}-{datetime.datetime.utcnow().strftime('%Y%m%d%H%M%S')}"

@app.get("/")
def read_root():
    return {"message": "Welcome to dBiller API"}

# Auth Routes
@app.post("/token", response_model=schemas.Token)
def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(), 
    device_id: str = Form(...), # Require device_id
    db: database.SessionLocal = Depends(database.get_db)
):
    user = db.query(models.User).filter(models.User.username == form_data.username).first()
    if not user or not auth.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is deactivated. Contact your administrator.",
        )
    
    # Device Logic
    device = db.query(models.UserDevice).filter(models.UserDevice.user_id == user.id, models.UserDevice.device_id == device_id).first()
    if not device:
        # Check count
        device_limit = int(os.getenv("DEVICE_LIMIT", "2"))
        device_count = db.query(models.UserDevice).filter(models.UserDevice.user_id == user.id).count()
        
        if device_limit != -1 and device_count >= device_limit:
             raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Device limit reached (Max {device_limit} devices). Contact admin.",
            )
        # Register new device
        new_device = models.UserDevice(user_id=user.id, device_id=device_id)
        db.add(new_device)
        db.commit()
    else:
        # Update last login
        device.last_login = datetime.datetime.utcnow()
        db.commit()

    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/me", response_model=schemas.User)
def read_current_user(
    current_user: schemas.User = Depends(auth.get_current_user),
):
    return current_user

@app.post("/register", response_model=schemas.User)
async def register_user(
    username: str = Form(...),
    password: str = Form(...),
    device_id: str = Form(...),
    license_key: str = Form(...),
    email: str = Form(...),
    store_name: str = Form(None),
    store_logo: UploadFile = File(None),
    db: database.SessionLocal = Depends(database.get_db),
):
    # 1. Verify License
    license_obj = db.query(models.License).filter(models.License.key == license_key, models.License.is_used == False).first()
    if not license_obj:
        raise HTTPException(status_code=400, detail="Invalid or used License Key")

    # 2. Verify Username
    db_user = db.query(models.User).filter(models.User.username == username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    
    hashed_password = auth.get_password_hash(password)
    if not email.strip():
        raise HTTPException(status_code=400, detail="Admin email is required")
    db_user = models.User(
        username=username,
        hashed_password=hashed_password,
        role="admin",
        email=email.strip(),
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    # 3. Mark License Used
    license_obj.is_used = True
    license_obj.used_by_user_id = db_user.id
    db.commit()

    # Register the device they signed up with
    db_device = models.UserDevice(user_id=db_user.id, device_id=device_id)
    db.add(db_device)
    db.commit()

    # Optional: upload logo once for organization/store reuse
    store_logo_url = None
    if store_logo:
        store_logo_url = await storage.upload_file_to_r2(store_logo, folder="store-logos")
        if store_logo_url and not store_logo_url.startswith("http"):
            store_logo_url = f"{PUBLIC_BASE_URL}{store_logo_url}"
    # Create organization for the newly registered user
    org_name = store_name or f"{username}'s Organization"
    db_org = models.Organization(name=org_name, logo_url=store_logo_url)
    db.add(db_org)
    db.commit()
    db.refresh(db_org)

    db_user.organization_id = db_org.id
    db.commit()
    db.refresh(db_user)

    # Optional: create store
    if store_name or store_logo_url:
        final_name = store_name or f"{username}'s Store"
        store = models.Store(
            name=final_name,
            logo_url=store_logo_url,
            owner_user_id=db_user.id,
        )
        db.add(store)
        db.commit()

    assign_default_subscription(db, db_org.id, db_user)
    return db_user

@app.post("/users/", response_model=schemas.User)
def create_user(
    user: schemas.UserCreate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("users.manage")),
):
    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    if user.role == auth.ROLE_SUPERADMIN:
        raise HTTPException(status_code=403, detail="Superadmin can only be created by backend")
    if user.role == auth.ROLE_ADMIN and (user.email is None or not user.email.strip()):
        raise HTTPException(status_code=400, detail="Admin email is required")
    organization_id = user.organization_id
    if not auth.is_superadmin(current_user):
        org_id = require_org_id(current_user)
        if organization_id is not None and organization_id != org_id:
            raise HTTPException(status_code=403, detail="Cannot create user for another organization")
        organization_id = org_id
    elif organization_id is not None:
        org = db.query(models.Organization).filter(models.Organization.id == organization_id).first()
        if not org:
            raise HTTPException(status_code=404, detail="Organization not found")
    if organization_id is not None:
        ensure_user_limit(db, organization_id)
    hashed_password = auth.get_password_hash(user.password)
    db_user = models.User(
        username=user.username,
        hashed_password=hashed_password,
        role=user.role,
        full_name=user.full_name,
        user_code=user.user_code,
        email=user.email,
        phone=user.phone,
        profile_photo=user.profile_photo,
        organization_id=organization_id,
    )
    db_user.active_account = user.active_account
    if user.role_ids is not None:
        db_user.roles = get_roles_by_ids(db, user.role_ids)
    if user.permission_ids is not None:
        db_user.permissions = get_permissions_by_ids(db, user.permission_ids)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

# Roles and Permissions
@app.post("/permissions/", response_model=schemas.Permission)
def create_permission(
    permission: schemas.PermissionCreate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("permissions.assign")),
):
    raise HTTPException(status_code=403, detail="Permissions are fixed and cannot be modified")

@app.get("/permissions/", response_model=List[schemas.Permission])
def read_permissions(
    skip: int = 0,
    limit: int = 100,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("permissions.view")),
):
    return db.query(models.Permission).offset(skip).limit(limit).all()

@app.get("/permissions/{permission_id}", response_model=schemas.Permission)
def read_permission(
    permission_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("permissions.view")),
):
    permission = db.query(models.Permission).filter(models.Permission.id == permission_id).first()
    if not permission:
        raise HTTPException(status_code=404, detail="Permission not found")
    return permission

@app.put("/permissions/{permission_id}", response_model=schemas.Permission)
def update_permission(
    permission_id: int,
    permission: schemas.PermissionUpdate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("permissions.assign")),
):
    raise HTTPException(status_code=403, detail="Permissions are fixed and cannot be modified")

@app.delete("/permissions/{permission_id}")
def delete_permission(
    permission_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("permissions.assign")),
):
    raise HTTPException(status_code=403, detail="Permissions are fixed and cannot be modified")

@app.post("/roles/", response_model=schemas.Role)
def create_role(
    role: schemas.RoleCreate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("roles.manage")),
):
    existing = db.query(models.Role).filter(models.Role.name == role.name).first()
    if existing:
        raise HTTPException(status_code=400, detail="Role already exists")
    db_role = models.Role(**role.dict())
    db.add(db_role)
    db.commit()
    db.refresh(db_role)
    return db_role

@app.get("/roles/", response_model=List[schemas.Role])
def read_roles(
    skip: int = 0,
    limit: int = 100,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("roles.view")),
):
    return db.query(models.Role).offset(skip).limit(limit).all()

@app.get("/roles/{role_id}", response_model=schemas.Role)
def read_role(
    role_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("roles.view")),
):
    role = db.query(models.Role).filter(models.Role.id == role_id).first()
    if not role:
        raise HTTPException(status_code=404, detail="Role not found")
    return role

@app.put("/roles/{role_id}", response_model=schemas.Role)
def update_role(
    role_id: int,
    role: schemas.RoleUpdate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("roles.manage")),
):
    db_role = db.query(models.Role).filter(models.Role.id == role_id).first()
    if not db_role:
        raise HTTPException(status_code=404, detail="Role not found")
    if role.name and role.name != db_role.name:
        existing = db.query(models.Role).filter(models.Role.name == role.name).first()
        if existing:
            raise HTTPException(status_code=400, detail="Role already exists")
        db_role.name = role.name
    if role.description is not None:
        db_role.description = role.description
    db.commit()
    db.refresh(db_role)
    return db_role

@app.put("/roles/{role_id}/permissions", response_model=schemas.Role)
def update_role_permissions(
    role_id: int,
    payload: schemas.PermissionAssignment,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("permissions.assign")),
):
    db_role = db.query(models.Role).filter(models.Role.id == role_id).first()
    if not db_role:
        raise HTTPException(status_code=404, detail="Role not found")
    db_role.permissions = get_permissions_by_ids(db, payload.permission_ids)
    db.commit()
    db.refresh(db_role)
    return db_role

@app.delete("/roles/{role_id}")
def delete_role(
    role_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("roles.manage")),
):
    db_role = db.query(models.Role).filter(models.Role.id == role_id).first()
    if not db_role:
        raise HTTPException(status_code=404, detail="Role not found")
    db.delete(db_role)
    db.commit()
    return {"message": "Role deleted successfully"}

# User Management
@app.get("/users/", response_model=List[schemas.User])
def read_users(
    skip: int = 0,
    limit: int = 100,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("users.view")),
):
    if auth.is_superadmin(current_user):
        return db.query(models.User).offset(skip).limit(limit).all()
    org_id = require_org_id(current_user)
    return (
        db.query(models.User)
        .filter(models.User.organization_id == org_id)
        .offset(skip)
        .limit(limit)
        .all()
    )

@app.get("/users/{user_id}", response_model=schemas.User)
def read_user(
    user_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("users.view")),
):
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    ensure_org_access(db_user.organization_id, current_user)
    return db_user

@app.put("/users/{user_id}", response_model=schemas.User)
def update_user(
    user_id: int,
    user: schemas.UserUpdate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("users.manage")),
):
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    ensure_org_access(db_user.organization_id, current_user)
    if user.role == auth.ROLE_SUPERADMIN:
        raise HTTPException(status_code=403, detail="Superadmin can only be created by backend")
    if user.organization_id is not None:
        if not auth.is_superadmin(current_user) and user.organization_id != db_user.organization_id:
            raise HTTPException(status_code=403, detail="Cannot move users across organizations")
        org = db.query(models.Organization).filter(models.Organization.id == user.organization_id).first()
        if not org:
            raise HTTPException(status_code=404, detail="Organization not found")
    current_org_id = db_user.organization_id
    was_admin = db_user.role == auth.ROLE_ADMIN and db_user.is_active
    new_role = user.role if user.role is not None else db_user.role
    new_email = user.email if user.email is not None else db_user.email
    new_active = user.active_account if user.active_account is not None else db_user.is_active
    new_org_id = user.organization_id if user.organization_id is not None else db_user.organization_id
    if db_user.id == current_user.id and auth.is_admin(current_user) and not new_active:
        raise HTTPException(status_code=403, detail="Admins cannot deactivate their own account")
    if new_role == auth.ROLE_ADMIN and (new_email is None or not new_email.strip()):
        raise HTTPException(status_code=400, detail="Admin email is required")
    if was_admin and (new_role != auth.ROLE_ADMIN or not new_active or new_org_id != current_org_id):
        ensure_admin_present(db, current_org_id, exclude_user_id=db_user.id)
    if new_org_id != current_org_id and new_org_id is not None:
        if new_role != auth.ROLE_ADMIN or not new_active:
            ensure_admin_present(db, new_org_id, exclude_user_id=None)
        ensure_user_limit(db, new_org_id, exclude_user_id=db_user.id)
    if user.username and user.username != db_user.username:
        existing = db.query(models.User).filter(models.User.username == user.username).first()
        if existing:
            raise HTTPException(status_code=400, detail="Username already registered")
        db_user.username = user.username
    if user.full_name is not None:
        db_user.full_name = user.full_name
    if user.user_code is not None:
        db_user.user_code = user.user_code
    if user.email is not None:
        db_user.email = user.email
    if user.phone is not None:
        db_user.phone = user.phone
    if user.role is not None:
        db_user.role = user.role
    if user.active_account is not None:
        db_user.active_account = user.active_account
    if user.profile_photo is not None:
        db_user.profile_photo = user.profile_photo
    if user.organization_id is not None:
        db_user.organization_id = user.organization_id
    if user.password:
        db_user.hashed_password = auth.get_password_hash(user.password)
    if user.role_ids is not None:
        db_user.roles = get_roles_by_ids(db, user.role_ids)
    if user.permission_ids is not None:
        db_user.permissions = get_permissions_by_ids(db, user.permission_ids)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.put("/users/{user_id}/roles", response_model=schemas.User)
def set_user_roles(
    user_id: int,
    payload: schemas.RoleAssignment,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("users.manage")),
):
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    ensure_org_access(db_user.organization_id, current_user)
    db_user.roles = get_roles_by_ids(db, payload.role_ids)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.put("/users/{user_id}/permissions", response_model=schemas.User)
def set_user_permissions(
    user_id: int,
    payload: schemas.PermissionAssignment,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("users.manage")),
):
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    ensure_org_access(db_user.organization_id, current_user)
    db_user.permissions = get_permissions_by_ids(db, payload.permission_ids)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.delete("/users/{user_id}")
def delete_user(
    user_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("users.manage")),
):
    if current_user.id == user_id:
        raise HTTPException(status_code=403, detail="Users cannot delete their own account")
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    ensure_org_access(db_user.organization_id, current_user)
    if db_user.role == auth.ROLE_ADMIN and db_user.is_active:
        ensure_admin_present(db, db_user.organization_id, exclude_user_id=db_user.id)
    db.delete(db_user)
    db.commit()
    return {"message": "User deleted successfully"}

# Organization CRUD
@app.post("/organizations/", response_model=schemas.Organization)
def create_organization(
    organization: schemas.OrganizationCreate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(auth.require_superadmin),
):
    if organization.subscription_id is not None:
        subscription = get_subscription_by_id(db, organization.subscription_id)
        if subscription and not subscription.is_active:
            raise HTTPException(status_code=400, detail="Subscription is not active")
    db_org = models.Organization(**organization.dict())
    db.add(db_org)
    db.commit()
    db.refresh(db_org)
    return db_org

@app.get("/organizations/", response_model=List[schemas.Organization])
def read_organizations(
    skip: int = 0,
    limit: int = 100,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(auth.require_superadmin),
):
    return db.query(models.Organization).offset(skip).limit(limit).all()

@app.get("/organizations/{organization_id}", response_model=schemas.Organization)
def read_organization(
    organization_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(auth.require_superadmin),
):
    organization = db.query(models.Organization).filter(models.Organization.id == organization_id).first()
    if not organization:
        raise HTTPException(status_code=404, detail="Organization not found")
    return organization

@app.put("/organizations/{organization_id}", response_model=schemas.Organization)
def update_organization(
    organization_id: int,
    organization: schemas.OrganizationUpdate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(auth.require_superadmin),
):
    db_org = db.query(models.Organization).filter(models.Organization.id == organization_id).first()
    if not db_org:
        raise HTTPException(status_code=404, detail="Organization not found")
    update_data = organization.dict(exclude_unset=True)
    if "subscription_id" in update_data and update_data["subscription_id"] is not None:
        subscription = get_subscription_by_id(db, update_data["subscription_id"])
        if subscription and not subscription.is_active:
            raise HTTPException(status_code=400, detail="Subscription is not active")
    for key, value in update_data.items():
        setattr(db_org, key, value)
    db.commit()
    db.refresh(db_org)
    return db_org

@app.delete("/organizations/{organization_id}")
def delete_organization(
    organization_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(auth.require_superadmin),
):
    db_org = db.query(models.Organization).filter(models.Organization.id == organization_id).first()
    if not db_org:
        raise HTTPException(status_code=404, detail="Organization not found")
    db.delete(db_org)
    db.commit()
    return {"message": "Organization deleted successfully"}

# Subscription CRUD
@app.post("/subscriptions/", response_model=schemas.Subscription)
def create_subscription(
    subscription: schemas.SubscriptionCreate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(auth.require_superadmin),
):
    db_subscription = models.Subscription(**subscription.dict())
    db.add(db_subscription)
    db.commit()
    db.refresh(db_subscription)
    return db_subscription

@app.get("/subscriptions/", response_model=List[schemas.Subscription])
def read_subscriptions(
    skip: int = 0,
    limit: int = 100,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("subscriptions.view")),
):
    query = db.query(models.Subscription)
    if not auth.is_superadmin(current_user):
        query = query.filter(models.Subscription.is_active == True)
    return query.offset(skip).limit(limit).all()

@app.get("/subscriptions/{subscription_id}", response_model=schemas.Subscription)
def read_subscription(
    subscription_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("subscriptions.view")),
):
    subscription = db.query(models.Subscription).filter(models.Subscription.id == subscription_id).first()
    if not subscription:
        raise HTTPException(status_code=404, detail="Subscription not found")
    if not auth.is_superadmin(current_user) and not subscription.is_active:
        raise HTTPException(status_code=404, detail="Subscription not found")
    return subscription

@app.put("/subscriptions/{subscription_id}", response_model=schemas.Subscription)
def update_subscription(
    subscription_id: int,
    subscription: schemas.SubscriptionUpdate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(auth.require_superadmin),
):
    db_subscription = db.query(models.Subscription).filter(models.Subscription.id == subscription_id).first()
    if not db_subscription:
        raise HTTPException(status_code=404, detail="Subscription not found")
    update_data = subscription.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_subscription, key, value)
    db.commit()
    db.refresh(db_subscription)
    return db_subscription

@app.delete("/subscriptions/{subscription_id}")
def delete_subscription(
    subscription_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(auth.require_superadmin),
):
    db_subscription = db.query(models.Subscription).filter(models.Subscription.id == subscription_id).first()
    if not db_subscription:
        raise HTTPException(status_code=404, detail="Subscription not found")
    db.delete(db_subscription)
    db.commit()
    return {"message": "Subscription deleted successfully"}

# Organization Subscription Management
def apply_subscription_change(
    db: database.SessionLocal,
    org_id: int,
    payload: schemas.OrganizationSubscriptionCreate,
    current_user: schemas.User,
    allow_price_override: bool = False,
) -> models.OrganizationSubscription:
    ensure_admin_email_present(db, org_id)
    subscription = get_subscription_by_id(db, payload.subscription_id)
    if subscription and not subscription.is_active and not auth.is_superadmin(current_user):
        raise HTTPException(status_code=400, detail="Subscription is not active")
    now = datetime.datetime.utcnow()
    active_subs = (
        db.query(models.OrganizationSubscription)
        .filter(
            models.OrganizationSubscription.organization_id == org_id,
            models.OrganizationSubscription.status == "active",
        )
        .all()
    )
    for existing in active_subs:
        existing.status = "replaced"
        existing.ended_at = now
    amount = None
    currency = None
    if allow_price_override and payload.amount is not None:
        amount = payload.amount
    else:
        amount = subscription.monthly_price or subscription.price or 0
    if allow_price_override and payload.currency:
        currency = payload.currency
    else:
        currency = subscription.currency
    started_at = payload.started_at or now
    org_sub = models.OrganizationSubscription(
        organization_id=org_id,
        subscription_id=payload.subscription_id,
        status="active",
        started_at=started_at,
        amount=amount,
        currency=currency,
        notes=payload.notes,
        payment_reference=payload.payment_reference,
    )
    db.add(org_sub)
    org = db.query(models.Organization).filter(models.Organization.id == org_id).first()
    if org:
        org.subscription_id = payload.subscription_id
        org.current_period_end = started_at + timedelta(days=30)
        org.status = "active"
    db.commit()
    db.refresh(org_sub)
    return annotate_refund_status(org_sub)

@app.get("/organization/subscriptions", response_model=List[schemas.OrganizationSubscription])
def read_organization_subscriptions(
    org_id: Optional[int] = None,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("subscriptions.view")),
):
    if auth.is_superadmin(current_user):
        if org_id is None:
            raise HTTPException(status_code=400, detail="org_id is required for superadmin")
        target_org_id = org_id
    else:
        target_org_id = require_org_id(current_user)
    subs = (
        db.query(models.OrganizationSubscription)
        .filter(models.OrganizationSubscription.organization_id == target_org_id)
        .order_by(models.OrganizationSubscription.started_at.desc())
        .all()
    )
    return [annotate_refund_status(sub) for sub in subs]

@app.post("/organization/subscriptions", response_model=schemas.OrganizationSubscription)
def create_organization_subscription(
    payload: schemas.OrganizationSubscriptionCreate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("subscriptions.manage")),
):
    org_id = require_org_id(current_user)
    return apply_subscription_change(db, org_id, payload, current_user, allow_price_override=False)

@app.post("/organization/subscriptions/{org_subscription_id}/cancel", response_model=schemas.OrganizationSubscription)
def cancel_organization_subscription(
    org_subscription_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("subscriptions.manage")),
):
    org_sub = (
        db.query(models.OrganizationSubscription)
        .filter(models.OrganizationSubscription.id == org_subscription_id)
        .first()
    )
    if not org_sub:
        raise HTTPException(status_code=404, detail="Organization subscription not found")
    ensure_org_access(org_sub.organization_id, current_user)
    now = datetime.datetime.utcnow()
    refund_eligible = is_refund_eligible(org_sub.started_at)
    org_sub.cancelled_at = now
    org_sub.ended_at = now
    org_sub.status = "refunded" if refund_eligible else "cancelled"
    org = db.query(models.Organization).filter(models.Organization.id == org_sub.organization_id).first()
    if org and org.subscription_id == org_sub.subscription_id:
        org.subscription_id = None
        org.current_period_end = now
    db.commit()
    db.refresh(org_sub)
    org_sub.refund_eligible = refund_eligible
    return org_sub

@app.get("/superadmin/organizations/{org_id}/subscriptions", response_model=List[schemas.OrganizationSubscription])
def read_org_subscriptions_superadmin(
    org_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(auth.require_superadmin),
):
    subs = (
        db.query(models.OrganizationSubscription)
        .filter(models.OrganizationSubscription.organization_id == org_id)
        .order_by(models.OrganizationSubscription.started_at.desc())
        .all()
    )
    return [annotate_refund_status(sub) for sub in subs]

@app.post("/superadmin/organizations/{org_id}/subscriptions", response_model=schemas.OrganizationSubscription)
def set_org_subscription_superadmin(
    org_id: int,
    payload: schemas.OrganizationSubscriptionCreate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(auth.require_superadmin),
):
    return apply_subscription_change(db, org_id, payload, current_user, allow_price_override=True)

@app.post("/superadmin/organizations/{org_id}/subscriptions/{org_subscription_id}/cancel", response_model=schemas.OrganizationSubscription)
def cancel_org_subscription_superadmin(
    org_id: int,
    org_subscription_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(auth.require_superadmin),
):
    org_sub = (
        db.query(models.OrganizationSubscription)
        .filter(
            models.OrganizationSubscription.id == org_subscription_id,
            models.OrganizationSubscription.organization_id == org_id,
        )
        .first()
    )
    if not org_sub:
        raise HTTPException(status_code=404, detail="Organization subscription not found")
    now = datetime.datetime.utcnow()
    refund_eligible = is_refund_eligible(org_sub.started_at)
    org_sub.cancelled_at = now
    org_sub.ended_at = now
    org_sub.status = "refunded" if refund_eligible else "cancelled"
    org = db.query(models.Organization).filter(models.Organization.id == org_id).first()
    if org and org.subscription_id == org_sub.subscription_id:
        org.subscription_id = None
        org.current_period_end = now
    db.commit()
    db.refresh(org_sub)
    org_sub.refund_eligible = refund_eligible
    return org_sub

@app.post("/payments/razorpay/order", response_model=schemas.RazorpayOrderResponse)
def create_razorpay_order(
    payload: schemas.RazorpayOrderCreate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("subscriptions.manage")),
):
    if auth.is_superadmin(current_user) and payload.organization_id is not None:
        org_id = payload.organization_id
    else:
        org_id = require_org_id(current_user)
    if org_id is None:
        raise HTTPException(status_code=400, detail="Organization is required for payments")
    ensure_admin_email_present(db, org_id)
    subscription = get_subscription_by_id(db, payload.subscription_id)
    if subscription and not subscription.is_active and not auth.is_superadmin(current_user):
        raise HTTPException(status_code=400, detail="Subscription is not active")
    if auth.is_superadmin(current_user) and payload.amount is not None:
        amount = payload.amount
    else:
        amount = subscription.monthly_price or subscription.price or 0
    if amount is None or amount <= 0:
        raise HTTPException(status_code=400, detail="Plan price is not configured")
    if auth.is_superadmin(current_user) and payload.currency:
        currency = payload.currency
    else:
        currency = subscription.currency or "INR"
    amount_paise = int((Decimal(str(amount)) * Decimal("100")).to_integral_value())
    notes = {
        "organization_id": str(org_id),
        "subscription_id": str(subscription.id),
        "created_by": str(current_user.id),
    }
    if payload.notes:
        notes["notes"] = payload.notes
    client, key_id = get_razorpay_client()
    receipt = f"org-{org_id}-plan-{subscription.id}-{int(datetime.datetime.utcnow().timestamp())}"
    order = client.order.create(
        {
            "amount": amount_paise,
            "currency": currency,
            "receipt": receipt,
            "notes": notes,
        }
    )
    return schemas.RazorpayOrderResponse(
        order_id=order["id"],
        amount=amount_paise,
        currency=currency,
        key_id=key_id,
        subscription_id=subscription.id,
        organization_id=org_id,
    )

@app.post("/payments/razorpay/verify", response_model=schemas.OrganizationSubscription)
def verify_razorpay_payment(
    payload: schemas.RazorpayPaymentVerify,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("subscriptions.manage")),
):
    if auth.is_superadmin(current_user) and payload.organization_id is not None:
        org_id = payload.organization_id
    else:
        org_id = require_org_id(current_user)
    if org_id is None:
        raise HTTPException(status_code=400, detail="Organization is required for payments")
    client, _ = get_razorpay_client()
    try:
        client.utility.verify_payment_signature(
            {
                "razorpay_order_id": payload.razorpay_order_id,
                "razorpay_payment_id": payload.razorpay_payment_id,
                "razorpay_signature": payload.razorpay_signature,
            }
        )
    except Exception:
        raise HTTPException(status_code=400, detail="Payment verification failed")
    order = client.order.fetch(payload.razorpay_order_id)
    order_notes = order.get("notes") or {}
    if str(order_notes.get("organization_id")) != str(org_id) or str(order_notes.get("subscription_id")) != str(payload.subscription_id):
        raise HTTPException(status_code=400, detail="Payment does not match the subscription request")
    amount = Decimal(order.get("amount", 0)) / Decimal("100")
    currency = order.get("currency") or "INR"
    notes = payload.notes
    order_note = f"razorpay_order_id={payload.razorpay_order_id}"
    if notes:
        notes = f"{notes} | {order_note}"
    else:
        notes = order_note
    return apply_subscription_change(
        db,
        org_id,
        schemas.OrganizationSubscriptionCreate(
            subscription_id=payload.subscription_id,
            amount=float(amount),
            currency=currency,
            notes=notes,
            payment_reference=payload.razorpay_payment_id,
        ),
        current_user,
        allow_price_override=True,
    )

@app.post("/superadmin/organizations/onboard", response_model=schemas.Organization)
def onboard_organization(
    payload: schemas.SuperadminOnboardOrganization,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(auth.require_superadmin),
):
    existing_user = db.query(models.User).filter(models.User.username == payload.admin_username).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Admin username already registered")
    if not payload.admin_email.strip():
        raise HTTPException(status_code=400, detail="Admin email is required")
    org = models.Organization(name=payload.organization_name)
    db.add(org)
    db.commit()
    db.refresh(org)

    admin_user = models.User(
        username=payload.admin_username,
        hashed_password=auth.get_password_hash(payload.admin_password),
        role=auth.ROLE_ADMIN,
        email=payload.admin_email.strip(),
        organization_id=org.id,
        is_active=True,
    )
    db.add(admin_user)
    db.commit()
    db.refresh(admin_user)

    if payload.subscription_id is not None:
        apply_subscription_change(
            db,
            org.id,
            schemas.OrganizationSubscriptionCreate(
                subscription_id=payload.subscription_id,
                amount=payload.amount,
                currency=payload.currency,
                notes=payload.notes,
                payment_reference=payload.payment_reference,
            ),
            current_user,
            allow_price_override=True,
        )
    else:
        assign_default_subscription(db, org.id, admin_user)
    return org

# Supplier CRUD
@app.post("/suppliers/", response_model=schemas.Supplier)
def create_supplier(
    supplier: schemas.SupplierCreate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("suppliers.manage")),
):
    organization_id = supplier.organization_id
    if not auth.is_superadmin(current_user):
        org_id = require_org_id(current_user)
        if organization_id is not None and organization_id != org_id:
            raise HTTPException(status_code=403, detail="Cannot create supplier for another organization")
        organization_id = org_id
    elif organization_id is not None:
        org = db.query(models.Organization).filter(models.Organization.id == organization_id).first()
        if not org:
            raise HTTPException(status_code=404, detail="Organization not found")
    supplier_data = supplier.dict()
    supplier_data["organization_id"] = organization_id
    db_supplier = models.Supplier(**supplier_data)
    db.add(db_supplier)
    db.commit()
    db.refresh(db_supplier)
    return db_supplier

@app.get("/suppliers/", response_model=List[schemas.Supplier])
def read_suppliers(
    skip: int = 0,
    limit: int = 100,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("suppliers.view")),
):
    query = db.query(models.Supplier)
    if not auth.is_superadmin(current_user):
        org_id = require_org_id(current_user)
        query = query.filter(models.Supplier.organization_id == org_id)
    return query.offset(skip).limit(limit).all()

@app.get("/suppliers/{supplier_id}", response_model=schemas.Supplier)
def read_supplier(
    supplier_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("suppliers.view")),
):
    supplier = db.query(models.Supplier).filter(models.Supplier.id == supplier_id).first()
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    ensure_org_access(supplier.organization_id, current_user)
    return supplier

@app.put("/suppliers/{supplier_id}", response_model=schemas.Supplier)
def update_supplier(
    supplier_id: int,
    supplier: schemas.SupplierUpdate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("suppliers.manage")),
):
    db_supplier = db.query(models.Supplier).filter(models.Supplier.id == supplier_id).first()
    if not db_supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    ensure_org_access(db_supplier.organization_id, current_user)
    if supplier.organization_id is not None:
        if not auth.is_superadmin(current_user) and supplier.organization_id != db_supplier.organization_id:
            raise HTTPException(status_code=403, detail="Cannot move supplier across organizations")
        org = db.query(models.Organization).filter(models.Organization.id == supplier.organization_id).first()
        if not org:
            raise HTTPException(status_code=404, detail="Organization not found")
    update_data = supplier.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_supplier, key, value)
    db.commit()
    db.refresh(db_supplier)
    return db_supplier

@app.delete("/suppliers/{supplier_id}")
def delete_supplier(
    supplier_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("suppliers.manage")),
):
    db_supplier = db.query(models.Supplier).filter(models.Supplier.id == supplier_id).first()
    if not db_supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    ensure_org_access(db_supplier.organization_id, current_user)
    db.delete(db_supplier)
    db.commit()
    return {"message": "Supplier deleted successfully"}

# Item CRUD
@app.post("/items/", response_model=schemas.Item)
def create_item(
    item: schemas.ItemCreate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("inventory.manage")),
):
    if item.supplier_id is not None:
        get_supplier_by_id(db, item.supplier_id, current_user)
    organization_id = item.organization_id
    if not auth.is_superadmin(current_user):
        org_id = require_org_id(current_user)
        if organization_id is not None and organization_id != org_id:
            raise HTTPException(status_code=403, detail="Cannot create item for another organization")
        organization_id = org_id
    elif organization_id is not None:
        org = db.query(models.Organization).filter(models.Organization.id == organization_id).first()
        if not org:
            raise HTTPException(status_code=404, detail="Organization not found")
    item_data = item.dict()
    item_data["organization_id"] = organization_id
    db_item = models.Item(**item_data)
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item

@app.get("/items/", response_model=List[schemas.Item])
def read_items(
    skip: int = 0,
    limit: int = 100,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("inventory.view")),
):
    query = db.query(models.Item)
    if not auth.is_superadmin(current_user):
        org_id = require_org_id(current_user)
        query = query.filter(models.Item.organization_id == org_id)
    return query.offset(skip).limit(limit).all()

@app.get("/items/{item_id}", response_model=schemas.Item)
def read_item(
    item_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("inventory.view")),
):
    item = db.query(models.Item).filter(models.Item.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    ensure_org_access(item.organization_id, current_user)
    return item

@app.put("/items/{item_id}", response_model=schemas.Item)
def update_item(
    item_id: int,
    item: schemas.ItemUpdate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("inventory.manage")),
):
    db_item = db.query(models.Item).filter(models.Item.id == item_id).first()
    if not db_item:
        raise HTTPException(status_code=404, detail="Item not found")
    ensure_org_access(db_item.organization_id, current_user)
    if item.supplier_id is not None:
        get_supplier_by_id(db, item.supplier_id, current_user)
    if item.organization_id is not None:
        if not auth.is_superadmin(current_user) and item.organization_id != db_item.organization_id:
            raise HTTPException(status_code=403, detail="Cannot move items across organizations")
        org = db.query(models.Organization).filter(models.Organization.id == item.organization_id).first()
        if not org:
            raise HTTPException(status_code=404, detail="Organization not found")
    update_data = item.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_item, key, value)
    db.commit()
    db.refresh(db_item)
    return db_item

@app.delete("/items/{item_id}")
def delete_item(
    item_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("inventory.manage")),
):
    db_item = db.query(models.Item).filter(models.Item.id == item_id).first()
    if not db_item:
        raise HTTPException(status_code=404, detail="Item not found")
    ensure_org_access(db_item.organization_id, current_user)
    db.delete(db_item)
    db.commit()
    return {"message": "Item deleted successfully"}

# Stock Movement CRUD
@app.post("/stock_movements/", response_model=schemas.StockMovement)
def create_stock_movement(
    movement: schemas.StockMovementCreate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("inventory.manage")),
):
    db_item = db.query(models.Item).filter(models.Item.id == movement.item_id).first()
    if not db_item:
        raise HTTPException(status_code=404, detail="Item not found")
    ensure_org_access(db_item.organization_id, current_user)
    if movement.user_id is not None:
        user = db.query(models.User).filter(models.User.id == movement.user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        ensure_org_access(user.organization_id, current_user)
    db_movement = models.StockMovement(
        item_id=movement.item_id,
        movement_type=movement.movement_type,
        quantity_change=movement.quantity_change,
        status=movement.status,
        reference=movement.reference,
        notes=movement.notes,
        user_id=movement.user_id or current_user.id,
    )
    db_item.stock = (db_item.stock or 0) + movement.quantity_change
    db.add(db_movement)
    db.commit()
    db.refresh(db_movement)
    return db_movement

@app.get("/stock_movements/", response_model=List[schemas.StockMovement])
def read_stock_movements(
    item_id: Optional[int] = None,
    skip: int = 0,
    limit: int = 100,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("inventory.view")),
):
    query = db.query(models.StockMovement).join(models.Item)
    if not auth.is_superadmin(current_user):
        org_id = require_org_id(current_user)
        query = query.filter(models.Item.organization_id == org_id)
    if item_id is not None:
        query = query.filter(models.StockMovement.item_id == item_id)
    return query.order_by(models.StockMovement.created_at.desc()).offset(skip).limit(limit).all()

@app.get("/stock_movements/{movement_id}", response_model=schemas.StockMovement)
def read_stock_movement(
    movement_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("inventory.view")),
):
    movement = db.query(models.StockMovement).filter(models.StockMovement.id == movement_id).first()
    if not movement:
        raise HTTPException(status_code=404, detail="Stock movement not found")
    db_item = db.query(models.Item).filter(models.Item.id == movement.item_id).first()
    if db_item:
        ensure_org_access(db_item.organization_id, current_user)
    return movement

@app.put("/stock_movements/{movement_id}", response_model=schemas.StockMovement)
def update_stock_movement(
    movement_id: int,
    movement: schemas.StockMovementUpdate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("inventory.manage")),
):
    db_movement = db.query(models.StockMovement).filter(models.StockMovement.id == movement_id).first()
    if not db_movement:
        raise HTTPException(status_code=404, detail="Stock movement not found")
    db_item = db.query(models.Item).filter(models.Item.id == db_movement.item_id).first()
    if db_item:
        ensure_org_access(db_item.organization_id, current_user)
    if movement.user_id is not None:
        user = db.query(models.User).filter(models.User.id == movement.user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        ensure_org_access(user.organization_id, current_user)
        db_movement.user_id = movement.user_id
    if movement.movement_type is not None:
        db_movement.movement_type = movement.movement_type
    if movement.status is not None:
        db_movement.status = movement.status
    if movement.reference is not None:
        db_movement.reference = movement.reference
    if movement.notes is not None:
        db_movement.notes = movement.notes
    if movement.quantity_change is not None:
        delta = movement.quantity_change - db_movement.quantity_change
        db_item = db.query(models.Item).filter(models.Item.id == db_movement.item_id).first()
        if db_item:
            db_item.stock = (db_item.stock or 0) + delta
        db_movement.quantity_change = movement.quantity_change
    db.commit()
    db.refresh(db_movement)
    return db_movement

@app.delete("/stock_movements/{movement_id}")
def delete_stock_movement(
    movement_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("inventory.manage")),
):
    db_movement = db.query(models.StockMovement).filter(models.StockMovement.id == movement_id).first()
    if not db_movement:
        raise HTTPException(status_code=404, detail="Stock movement not found")
    db_item = db.query(models.Item).filter(models.Item.id == db_movement.item_id).first()
    if db_item:
        ensure_org_access(db_item.organization_id, current_user)
    if db_item:
        db_item.stock = (db_item.stock or 0) - db_movement.quantity_change
    db.delete(db_movement)
    db.commit()
    return {"message": "Stock movement deleted successfully"}

# Order CRUD
@app.post("/orders/", response_model=schemas.Order)
def create_order(
    order: schemas.OrderCreate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("orders.manage")),
):
    organization_id = order.organization_id
    if not auth.is_superadmin(current_user):
        org_id = require_org_id(current_user)
        if organization_id is not None and organization_id != org_id:
            raise HTTPException(status_code=403, detail="Cannot create order for another organization")
        organization_id = org_id
    elif organization_id is not None:
        org = db.query(models.Organization).filter(models.Organization.id == organization_id).first()
        if not org:
            raise HTTPException(status_code=404, detail="Organization not found")
    if order.supplier_id is not None:
        get_supplier_by_id(db, order.supplier_id, current_user)
    user_id = order.user_id or current_user.id
    if order.user_id is not None:
        user = db.query(models.User).filter(models.User.id == order.user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        ensure_org_access(user.organization_id, current_user)
    subtotal, order_items = build_order_items(db, order.items, current_user)
    shipping_fee = order.shipping_fee or 0
    tax = order.tax or 0
    total_amount = subtotal + shipping_fee + tax
    order_number = order.order_number or generate_order_number(order.order_type)
    db_order = models.Order(
        order_number=order_number,
        status=order.status,
        order_type=order.order_type,
        supplier_id=order.supplier_id,
        customer_name=order.customer_name,
        customer_email=order.customer_email,
        customer_phone=order.customer_phone,
        billing_address=order.billing_address,
        shipping_address=order.shipping_address,
        notes=order.notes,
        subtotal=subtotal,
        shipping_fee=shipping_fee,
        tax=tax,
        total_amount=total_amount,
        currency=order.currency,
        user_id=user_id,
        organization_id=organization_id,
        confirmed_at=order.confirmed_at,
        shipped_at=order.shipped_at,
        delivered_at=order.delivered_at,
        cancelled_at=order.cancelled_at,
        expected_delivery_at=order.expected_delivery_at,
        items=order_items,
    )
    db.add(db_order)
    db.commit()
    db.refresh(db_order)
    return db_order

@app.get("/orders/", response_model=List[schemas.Order])
def read_orders(
    skip: int = 0,
    limit: int = 100,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("orders.view")),
):
    query = db.query(models.Order)
    if not auth.is_superadmin(current_user):
        org_id = require_org_id(current_user)
        query = query.filter(models.Order.organization_id == org_id)
    return query.offset(skip).limit(limit).all()

@app.get("/orders/{order_id}", response_model=schemas.Order)
def read_order(
    order_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("orders.view")),
):
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    ensure_org_access(order.organization_id, current_user)
    return order

@app.put("/orders/{order_id}", response_model=schemas.Order)
def update_order(
    order_id: int,
    order: schemas.OrderUpdate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("orders.manage")),
):
    db_order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not db_order:
        raise HTTPException(status_code=404, detail="Order not found")
    ensure_org_access(db_order.organization_id, current_user)
    if order.organization_id is not None:
        if not auth.is_superadmin(current_user) and order.organization_id != db_order.organization_id:
            raise HTTPException(status_code=403, detail="Cannot move orders across organizations")
        org = db.query(models.Organization).filter(models.Organization.id == order.organization_id).first()
        if not org:
            raise HTTPException(status_code=404, detail="Organization not found")
    if order.supplier_id is not None:
        get_supplier_by_id(db, order.supplier_id, current_user)
    if order.user_id is not None:
        user = db.query(models.User).filter(models.User.id == order.user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        ensure_org_access(user.organization_id, current_user)
        db_order.user_id = order.user_id
    if order.order_number is not None:
        db_order.order_number = order.order_number
    if order.status is not None:
        db_order.status = order.status
    if order.order_type is not None:
        db_order.order_type = order.order_type
    if order.supplier_id is not None:
        db_order.supplier_id = order.supplier_id
    if order.customer_name is not None:
        db_order.customer_name = order.customer_name
    if order.customer_email is not None:
        db_order.customer_email = order.customer_email
    if order.customer_phone is not None:
        db_order.customer_phone = order.customer_phone
    if order.billing_address is not None:
        db_order.billing_address = order.billing_address
    if order.shipping_address is not None:
        db_order.shipping_address = order.shipping_address
    if order.notes is not None:
        db_order.notes = order.notes
    if order.currency is not None:
        db_order.currency = order.currency
    if order.organization_id is not None:
        db_order.organization_id = order.organization_id
    if order.confirmed_at is not None:
        db_order.confirmed_at = order.confirmed_at
    if order.shipped_at is not None:
        db_order.shipped_at = order.shipped_at
    if order.delivered_at is not None:
        db_order.delivered_at = order.delivered_at
    if order.cancelled_at is not None:
        db_order.cancelled_at = order.cancelled_at
    if order.expected_delivery_at is not None:
        db_order.expected_delivery_at = order.expected_delivery_at

    if order.items is not None:
        subtotal, order_items = build_order_items(db, order.items, current_user)
        db_order.items = order_items
        db_order.subtotal = subtotal
    if order.shipping_fee is not None:
        db_order.shipping_fee = order.shipping_fee
    if order.tax is not None:
        db_order.tax = order.tax
    db_order.total_amount = db_order.subtotal + db_order.shipping_fee + db_order.tax
    db.commit()
    db.refresh(db_order)
    return db_order

@app.delete("/orders/{order_id}")
def delete_order(
    order_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("orders.manage")),
):
    db_order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not db_order:
        raise HTTPException(status_code=404, detail="Order not found")
    ensure_org_access(db_order.organization_id, current_user)
    db.delete(db_order)
    db.commit()
    return {"message": "Order deleted successfully"}

# Invoice CRUD
@app.post("/invoices/", response_model=schemas.Invoice)
def create_invoice(
    invoice: schemas.InvoiceCreate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("invoices.manage")),
):
    organization_id = invoice.organization_id
    if not auth.is_superadmin(current_user):
        org_id = require_org_id(current_user)
        if organization_id is not None and organization_id != org_id:
            raise HTTPException(status_code=403, detail="Cannot create invoice for another organization")
        organization_id = org_id
    elif organization_id is not None:
        org = db.query(models.Organization).filter(models.Organization.id == organization_id).first()
        if not org:
            raise HTTPException(status_code=404, detail="Organization not found")
    if invoice.order_id is not None:
        order = db.query(models.Order).filter(models.Order.id == invoice.order_id).first()
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")
        ensure_org_access(order.organization_id, current_user)
    subtotal, invoice_items = build_invoice_items(db, invoice.items, current_user)
    tax = invoice.tax or 0
    discount = invoice.discount or 0
    total_amount = subtotal + tax - discount
    invoice_number = invoice.invoice_number or generate_invoice_number()
    issue_date = invoice.issue_date or datetime.datetime.utcnow()
    db_invoice = models.Invoice(
        invoice_number=invoice_number,
        status=invoice.status,
        issue_date=issue_date,
        due_date=invoice.due_date,
        source_url=invoice.source_url,
        source_type=invoice.source_type,
        ai_extracted=invoice.ai_extracted,
        paid_at=invoice.paid_at,
        customer_name=invoice.customer_name,
        customer_email=invoice.customer_email,
        billing_address=invoice.billing_address,
        shipping_address=invoice.shipping_address,
        subtotal=subtotal,
        tax=tax,
        discount=discount,
        total_amount=total_amount,
        currency=invoice.currency,
        order_id=invoice.order_id,
        organization_id=organization_id,
        items=invoice_items,
    )
    db.add(db_invoice)
    db.commit()
    db.refresh(db_invoice)
    return db_invoice

@app.get("/invoices/", response_model=List[schemas.Invoice])
def read_invoices(
    skip: int = 0,
    limit: int = 100,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("invoices.view")),
):
    query = db.query(models.Invoice)
    if not auth.is_superadmin(current_user):
        org_id = require_org_id(current_user)
        query = query.filter(models.Invoice.organization_id == org_id)
    return query.offset(skip).limit(limit).all()

@app.get("/invoices/{invoice_id}", response_model=schemas.Invoice)
def read_invoice(
    invoice_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("invoices.view")),
):
    invoice = db.query(models.Invoice).filter(models.Invoice.id == invoice_id).first()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")
    ensure_org_access(invoice.organization_id, current_user)
    return invoice

@app.put("/invoices/{invoice_id}", response_model=schemas.Invoice)
def update_invoice(
    invoice_id: int,
    invoice: schemas.InvoiceUpdate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("invoices.manage")),
):
    db_invoice = db.query(models.Invoice).filter(models.Invoice.id == invoice_id).first()
    if not db_invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")
    ensure_org_access(db_invoice.organization_id, current_user)
    if invoice.organization_id is not None:
        if not auth.is_superadmin(current_user) and invoice.organization_id != db_invoice.organization_id:
            raise HTTPException(status_code=403, detail="Cannot move invoices across organizations")
        org = db.query(models.Organization).filter(models.Organization.id == invoice.organization_id).first()
        if not org:
            raise HTTPException(status_code=404, detail="Organization not found")
    if invoice.order_id is not None:
        order = db.query(models.Order).filter(models.Order.id == invoice.order_id).first()
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")
        ensure_org_access(order.organization_id, current_user)
        db_invoice.order_id = invoice.order_id
    if invoice.invoice_number is not None:
        db_invoice.invoice_number = invoice.invoice_number
    if invoice.status is not None:
        db_invoice.status = invoice.status
    if invoice.issue_date is not None:
        db_invoice.issue_date = invoice.issue_date
    if invoice.due_date is not None:
        db_invoice.due_date = invoice.due_date
    if invoice.source_url is not None:
        db_invoice.source_url = invoice.source_url
    if invoice.source_type is not None:
        db_invoice.source_type = invoice.source_type
    if invoice.ai_extracted is not None:
        db_invoice.ai_extracted = invoice.ai_extracted
    if invoice.paid_at is not None:
        db_invoice.paid_at = invoice.paid_at
    if invoice.customer_name is not None:
        db_invoice.customer_name = invoice.customer_name
    if invoice.customer_email is not None:
        db_invoice.customer_email = invoice.customer_email
    if invoice.billing_address is not None:
        db_invoice.billing_address = invoice.billing_address
    if invoice.shipping_address is not None:
        db_invoice.shipping_address = invoice.shipping_address
    if invoice.currency is not None:
        db_invoice.currency = invoice.currency
    if invoice.organization_id is not None:
        db_invoice.organization_id = invoice.organization_id

    if invoice.items is not None:
        subtotal, invoice_items = build_invoice_items(db, invoice.items, current_user)
        db_invoice.items = invoice_items
        db_invoice.subtotal = subtotal
    if invoice.tax is not None:
        db_invoice.tax = invoice.tax
    if invoice.discount is not None:
        db_invoice.discount = invoice.discount
    db_invoice.total_amount = db_invoice.subtotal + db_invoice.tax - db_invoice.discount
    db.commit()
    db.refresh(db_invoice)
    return db_invoice

@app.delete("/invoices/{invoice_id}")
def delete_invoice(
    invoice_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("invoices.manage")),
):
    db_invoice = db.query(models.Invoice).filter(models.Invoice.id == invoice_id).first()
    if not db_invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")
    ensure_org_access(db_invoice.organization_id, current_user)
    db.delete(db_invoice)
    db.commit()
    return {"message": "Invoice deleted successfully"}

import storage

# Product Routes
@app.post("/products/", response_model=schemas.Product)
async def create_product(
    name: str = Form(...),
    price: float = Form(...),
    stock: int = Form(0),
    category: str = Form(None),
    image: UploadFile = File(None),
    image_url: str = Form(None),
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("inventory.manage"))
):
    organization_id = None
    if not auth.is_superadmin(current_user):
        organization_id = require_org_id(current_user)
    else:
        organization_id = current_user.organization_id
    final_image_url = None
    if image:
        final_image_url = await storage.upload_file_to_r2(image)
    elif image_url:
        final_image_url = image_url
    if category:
        category = category.strip()
    
    product_data = schemas.ProductCreate(
        name=name,
        price=price,
        stock=stock,
        image_url=final_image_url,
        category=category,
        organization_id=organization_id,
    )
    db_product = models.Product(**product_data.dict())
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return normalize_product_url(db_product)

@app.get("/products/", response_model=List[schemas.Product])
def read_products(
    skip: int = 0,
    limit: int = 100,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("inventory.view")),
):
    query = db.query(models.Product)
    if not auth.is_superadmin(current_user):
        org_id = require_org_id(current_user)
        query = query.filter(models.Product.organization_id == org_id)
    products = query.offset(skip).limit(limit).all()
    normalized = [normalize_product_url(p) for p in products]
    logger.info("read_products", extra={"count": len(normalized)})
    return normalized

@app.get("/products/{product_id}", response_model=schemas.Product)
def read_product(
    product_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("inventory.view")),
):
    db_product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if db_product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    ensure_org_access(db_product.organization_id, current_user)
    return normalize_product_url(db_product)

@app.put("/products/{product_id}", response_model=schemas.Product)
async def update_product(
    product_id: int,
    name: str = Form(...),
    price: float = Form(...),
    stock: int = Form(0),
    category: str = Form(None),
    image: UploadFile = File(None),
    image_url: str = Form(None),
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("inventory.manage"))
):
    db_product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if db_product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    ensure_org_access(db_product.organization_id, current_user)

    # Preserve existing image unless a new one is uploaded
    final_image_url = db_product.image_url
    if image:
        uploaded_url = await storage.upload_file_to_r2(image)
        if uploaded_url:
            final_image_url = uploaded_url if uploaded_url.startswith("http") else f"{PUBLIC_BASE_URL}{uploaded_url}"
        else:
            logger.warning("Image upload failed; keeping existing image for product_id=%s", product_id)
    elif image_url is not None:
         # Only update if explicitly provided (even empty string to clear?) 
         # Assuming user wants to set it if provided.
         final_image_url = image_url

    if category:
        category = category.strip()

    db_product.name = name
    db_product.price = price
    db_product.stock = stock
    db_product.category = category
    db_product.image_url = final_image_url

    db.commit()
    db.refresh(db_product)
    return normalize_product_url(db_product)

@app.delete("/products/{product_id}")
def delete_product(
    product_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("inventory.manage")),
):
    db_product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if db_product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    ensure_org_access(db_product.organization_id, current_user)
    db.delete(db_product)
    db.commit()
    return {"message": "Product deleted successfully"}


@app.delete("/categories/{category_name}")
def delete_category(
    category_name: str,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("inventory.manage")),
):
    query = db.query(models.Product).filter(models.Product.category == category_name)
    if not auth.is_superadmin(current_user):
        org_id = require_org_id(current_user)
        query = query.filter(models.Product.organization_id == org_id)
    updated = query.update({"category": None})
    db.commit()
    logger.info("category_cleared", extra={"category": category_name, "count": updated})
    return {"cleared": updated}


@app.get("/store", response_model=Optional[schemas.Store])
def get_store(db: database.SessionLocal = Depends(database.get_db), current_user: schemas.User = Depends(auth.get_current_user)):
    store = db.query(models.Store).filter(models.Store.owner_user_id == current_user.id).first()
    if not store:
        return None
    if store.logo_url and not store.logo_url.startswith("http"):
        store.logo_url = f"{PUBLIC_BASE_URL}{store.logo_url}"
    return store


@app.put("/store", response_model=schemas.Store)
async def update_store(
    name: str = Form(None),
    logo: UploadFile = File(None),
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(auth.get_current_user)
):
    store = db.query(models.Store).filter(models.Store.owner_user_id == current_user.id).first()
    if not store:
        store = models.Store(name=name or f"{current_user.username}'s Store", owner_user_id=current_user.id)
        db.add(store)
        db.commit()
        db.refresh(store)
    if name:
        store.name = name
    if logo:
        logo_url = await storage.upload_file_to_r2(logo, folder="store-logos")
        if logo_url and not logo_url.startswith("http"):
            logo_url = f"{PUBLIC_BASE_URL}{logo_url}"
        store.logo_url = logo_url
    db.commit()
    db.refresh(store)
    if store.logo_url and not store.logo_url.startswith("http"):
        store.logo_url = f"{PUBLIC_BASE_URL}{store.logo_url}"
    return store


@app.post("/users/change_password")
def change_password(
    old_password: str = Form(...),
    new_password: str = Form(...),
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(auth.get_current_user)
):
    user = db.query(models.User).filter(models.User.id == current_user.id).first()
    if not auth.verify_password(old_password, user.hashed_password):
        raise HTTPException(status_code=400, detail="Old password incorrect")
    user.hashed_password = auth.get_password_hash(new_password)
    db.commit()
    return {"message": "Password updated"}


@app.post("/subscriptions/cancel")
def cancel_subscription(db: database.SessionLocal = Depends(database.get_db), current_user: schemas.User = Depends(auth.get_current_user)):
    # Placeholder: mark subscription canceled
    return {"message": "Subscription cancellation requested"}


@app.post("/products/bulk_upload")
async def bulk_upload_products(
    file: UploadFile = File(...),
    category: str = Form(None),
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("inventory.manage"))
):
    organization_id = None
    if not auth.is_superadmin(current_user):
        organization_id = require_org_id(current_user)
    else:
        organization_id = current_user.organization_id
    if not file.filename.lower().endswith(".csv"):
        raise HTTPException(status_code=400, detail="Please upload a .csv file.")

    raw = await file.read()
    try:
        decoded = raw.decode("utf-8-sig")
    except Exception:
        raise HTTPException(status_code=400, detail="Unable to decode CSV. Use UTF-8 encoding.")

    reader = csv.DictReader(io.StringIO(decoded))
    if reader.fieldnames is None:
        raise HTTPException(status_code=400, detail="CSV needs a header row with at least name,price,stock.")
    created = 0
    skipped = 0
    errors = []

    for idx, row in enumerate(reader, start=1):
        name = (row.get("name") or row.get("Name") or "").strip()
        if not name:
            skipped += 1
            errors.append(f"Row {idx}: missing name")
            continue
        try:
            price_value = row.get("price") or row.get("Price") or 0
            stock_value = row.get("stock") or row.get("Stock") or 0
            price = float(price_value)
            stock = int(float(stock_value))
        except Exception:
            skipped += 1
            errors.append(f"Row {idx}: invalid price/stock")
            continue

        row_category = (row.get("category") or row.get("Category") or category or "").strip() or None
        image_url = (row.get("image_url") or row.get("Image_URL") or row.get("image") or "").strip() or None

        product = models.Product(
            name=name,
            price=price,
            stock=stock,
            category=row_category,
            image_url=image_url,
            organization_id=organization_id,
        )
        db.add(product)
        created += 1

    db.commit()
    return {
        "created": created,
        "skipped": skipped,
        "errors": errors[:10],  # cap errors to avoid huge payloads
    }

# Billing Routes
@app.post("/bills/", response_model=schemas.Bill)
def create_bill(
    bill: schemas.BillCreate,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("checkout.manage")),
):
    organization_id = None
    if not auth.is_superadmin(current_user):
        organization_id = require_org_id(current_user)
    else:
        organization_id = current_user.organization_id
    total_amount = 0.0
    bill_items = []
    
    # Calculate total and verify items
    for item in bill.items:
        product = db.query(models.Product).filter(models.Product.id == item.product_id).first()
        if not product:
            raise HTTPException(status_code=404, detail=f"Product with id {item.product_id} not found")
        ensure_org_access(product.organization_id, current_user)

        item_total = product.price * item.quantity
        total_amount += item_total
        
        bill_items.append(models.BillItem(product_id=product.id, quantity=item.quantity, price=product.price))
        
        # Update stock
        product.stock -= item.quantity
    
    db_bill = models.Bill(
        total_amount=total_amount,
        payment_method=bill.payment_method,
        organization_id=organization_id,
    )
    db.add(db_bill)
    db.commit()
    db.refresh(db_bill)
    
    for bill_item in bill_items:
        bill_item.bill_id = db_bill.id
        db.add(bill_item)
    
    db.commit()
    db.refresh(db_bill)
    return db_bill

@app.get("/bills/", response_model=List[schemas.Bill])
def read_bills(
    skip: int = 0,
    limit: int = 100,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("checkout.manage")),
):
    query = db.query(models.Bill)
    if not auth.is_superadmin(current_user):
        org_id = require_org_id(current_user)
        query = query.filter(models.Bill.organization_id == org_id)
    bills = query.offset(skip).limit(limit).all()
    return bills

@app.get("/bills/{bill_id}", response_model=schemas.Bill)
def read_bill(
    bill_id: int,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(require_permission("checkout.manage")),
):
    bill = db.query(models.Bill).filter(models.Bill.id == bill_id).first()
    if bill is None:
        raise HTTPException(status_code=404, detail="Bill not found")
    ensure_org_access(bill.organization_id, current_user)
    return bill

# Image Recognition via OCR -> Search Products by extracted text
@app.post("/recognize/")
async def recognize_product(
    file: UploadFile = File(...),
    debug: bool = False,
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(auth.get_current_user)
):
    debug_info = {}

    # Configure Tesseract path if specified in environment
    tess_cmd = os.getenv("TESSERACT_CMD")
    if tess_cmd and os.path.exists(tess_cmd):
        pytesseract.pytesseract.tesseract_cmd = tess_cmd

    if pytesseract is None or Image is None:
        raise HTTPException(
            status_code=503,
            detail="OCR not available. Install pillow+pytesseract and the Tesseract binary on the server.",
        )

    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Empty image payload")

    debug_info["bytes"] = len(contents)

    try:
        base_image = Image.open(io.BytesIO(contents))
        base_image = ImageOps.exif_transpose(base_image)  # correct orientation from camera metadata
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid image file: {e}")

    resample_lanczos = getattr(Image, "Resampling", Image).LANCZOS

    def preprocess(img: "Image.Image", threshold: int | None = None, enlarge: float = 1.0) -> "Image.Image":
        """Grayscale + autocontrast + optional binarize + optional upscale to help Tesseract."""
        img = img.convert("L")
        img = ImageOps.autocontrast(img)
        if enlarge != 1.0:
            new_w = min(int(img.width * enlarge), 2000)
            new_h = min(int(img.height * enlarge), 2000)
            img = img.resize((new_w, new_h), resample=resample_lanczos)
        img = img.filter(ImageFilter.SHARPEN)
        if threshold is not None:
            img = img.point(lambda p: 255 if p > threshold else 0)
        return img

    def run_ocr(img: "Image.Image", cfg: str, min_conf: float) -> tuple[str, int, float | None]:
        """Run Tesseract and return text, word count, avg conf."""
        data = pytesseract.image_to_data(img, lang=lang, config=cfg, output_type=Output.DICT)
        words: List[str] = []
        confs: List[float] = []
        for w_text, conf in zip(data.get("text", []), data.get("conf", [])):
            try:
                conf_val = float(conf)
            except Exception:
                conf_val = -1.0
            if conf_val >= min_conf and w_text.strip():
                words.append(w_text.strip())
                confs.append(conf_val)
        avg_conf = sum(confs) / len(confs) if confs else None
        word_count = len(words)
        # Always fall back to string extraction so we can still match something
        text_out = " ".join(words) if words else pytesseract.image_to_string(img, lang=lang, config=cfg)
        return text_out, word_count, avg_conf

    # Preprocess (limit size first)
    max_dim = 1800
    bw, bh = base_image.size
    debug_info["image_size_before"] = {"w": bw, "h": bh}
    if max(bw, bh) > max_dim:
        base_image.thumbnail((max_dim, max_dim))
    debug_info["image_size_after"] = {"w": base_image.width, "h": base_image.height}

    lang = os.getenv("TESSERACT_LANG", "eng")
    primary_config = os.getenv("TESSERACT_CONFIG", "--psm 6 --oem 3")
    fallback_config = os.getenv("TESSERACT_CONFIG_FALLBACK", "--psm 11 --oem 3")
    min_conf = float(os.getenv("OCR_MIN_CONF", "40"))
    thresh = int(os.getenv("OCR_THRESHOLD", "160"))
    debug_info["lang"] = lang
    debug_info["config"] = primary_config
    debug_info["fallback_config"] = fallback_config
    debug_info["tesseract_cmd"] = getattr(pytesseract.pytesseract, "tesseract_cmd", "auto")

    # Pass 1: sharpen + binarize
    primary_image = preprocess(base_image, threshold=thresh)
    text, word_count, avg_conf = run_ocr(primary_image, primary_config, min_conf)

    # Pass 2: softer processing + upscale if first pass weak
    if word_count == 0 or len(text.strip()) < 3:
        fallback_image = preprocess(base_image, threshold=None, enlarge=1.3)
        text_fb, wc_fb, conf_fb = run_ocr(fallback_image, fallback_config, min_conf=30)
        if wc_fb > word_count or (len(text_fb.strip()) > len(text.strip())):
            text, word_count, avg_conf = text_fb, wc_fb, conf_fb
            debug_info["used_fallback"] = True
        else:
            debug_info["used_fallback"] = False
    else:
        debug_info["used_fallback"] = False

    debug_info["ocr_conf_avg"] = avg_conf
    debug_info["ocr_word_count"] = word_count
    debug_info["raw_text_preview"] = text[:400]

    # Extract alphanumeric word-like tokens (filter noise)
    word_tokens = re.findall(r"[A-Za-z0-9]{2,}", text)
    split_tokens = [t for t in re.split(r"[\s,;\n]+", text) if t and t.strip()]
    tokens = {
        t.lower()
        for t in word_tokens + split_tokens
        if t and len(t) >= 2 and re.search(r"[A-Za-z0-9]", t)
    }

    debug_info["tokens"] = list(tokens)

    products_q = db.query(models.Product)
    if not auth.is_superadmin(current_user):
        org_id = require_org_id(current_user)
        products_q = products_q.filter(models.Product.organization_id == org_id)

    products: List[models.Product] = []
    if tokens:
        filters = []
        for token in tokens:
            filters.append(models.Product.name.ilike(f"%{token}%"))
            filters.append(models.Product.category.ilike(f"%{token}%"))
        products = products_q.filter(or_(*filters)).limit(10).all()

    # Fuzzy fallback if no matches
    if not products:
        all_products = products_q.all()
        full_text = (text or "").lower()
        scored: List[tuple[float, models.Product]] = []
        for p in all_products:
            hay = f"{p.name} {p.category or ''}".lower()
            score = difflib.SequenceMatcher(None, full_text, hay).ratio() if full_text else 0
            if score >= 0.1:
                scored.append((score, p))
        scored.sort(key=lambda x: x[0], reverse=True)
        products = [s[1] for s in scored[:5]]
        debug_info["fuzzy_scores"] = scored[:5]

    unique_products = {p.id: normalize_product_url(p) for p in products}.values()

    debug_info["matched_ids"] = [p.id for p in unique_products]
    logger.info("OCR match", extra={"debug": debug_info})

    if debug:
        return {
            "products": list(unique_products),
            "debug": debug_info,
        }

    return list(unique_products)
