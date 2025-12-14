import os
import io
import csv
import re
import datetime
import logging
import difflib
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


def ensure_optional_columns():
    """Add columns that may be missing on older databases without requiring a full migration tool."""
    with engine.begin() as conn:
        try:
            conn.execute(text("ALTER TABLE products ADD COLUMN category VARCHAR"))
        except Exception:
            pass  # Column already exists or table missing; safe to ignore for idempotency
        try:
            conn.execute(text("ALTER TABLE stores ADD COLUMN dummy_check INTEGER"))
        except Exception:
            pass  # table likely exists if this fails; create_all will create if missing


ensure_optional_columns()

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

@app.post("/register", response_model=schemas.User)
async def register_user(
    username: str = Form(...),
    password: str = Form(...),
    device_id: str = Form(...),
    license_key: str = Form(...),
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
    db_user = models.User(username=username, hashed_password=hashed_password, role="admin") 
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

    # Optional: create store
    store_logo_url = None
    if store_logo:
        store_logo_url = await storage.upload_file_to_r2(store_logo, folder="store-logos")
        if store_logo_url and not store_logo_url.startswith("http"):
            store_logo_url = f"{PUBLIC_BASE_URL}{store_logo_url}"
    if store_name or store_logo_url:
        final_name = store_name or f"{username}'s Store"
        store = models.Store(
            name=final_name,
            logo_url=store_logo_url,
            owner_user_id=db_user.id,
        )
        db.add(store)
        db.commit()

    return db_user

@app.post("/users/", response_model=schemas.User)
def create_user(user: schemas.UserCreate, db: database.SessionLocal = Depends(database.get_db)):
    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    hashed_password = auth.get_password_hash(user.password)
    db_user = models.User(username=user.username, hashed_password=hashed_password, role=user.role)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

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
    current_user: schemas.User = Depends(auth.get_current_user)
):
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
    )
    db_product = models.Product(**product_data.dict())
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return normalize_product_url(db_product)

@app.get("/products/", response_model=List[schemas.Product])
def read_products(skip: int = 0, limit: int = 100, db: database.SessionLocal = Depends(database.get_db)):
    products = db.query(models.Product).offset(skip).limit(limit).all()
    normalized = [normalize_product_url(p) for p in products]
    logger.info("read_products", extra={"count": len(normalized)})
    return normalized

@app.get("/products/{product_id}", response_model=schemas.Product)
def read_product(product_id: int, db: database.SessionLocal = Depends(database.get_db)):
    db_product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if db_product is None:
        raise HTTPException(status_code=404, detail="Product not found")
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
    current_user: schemas.User = Depends(auth.get_current_user)
):
    db_product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if db_product is None:
        raise HTTPException(status_code=404, detail="Product not found")

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
def delete_product(product_id: int, db: database.SessionLocal = Depends(database.get_db), current_user: schemas.User = Depends(auth.get_current_user)):
    db_product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if db_product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    db.delete(db_product)
    db.commit()
    return {"message": "Product deleted successfully"}


@app.delete("/categories/{category_name}")
def delete_category(category_name: str, db: database.SessionLocal = Depends(database.get_db), current_user: schemas.User = Depends(auth.get_current_user)):
    updated = db.query(models.Product).filter(models.Product.category == category_name).update({"category": None})
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
    current_user: schemas.User = Depends(auth.get_current_user)
):
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
def create_bill(bill: schemas.BillCreate, db: database.SessionLocal = Depends(database.get_db), current_user: schemas.User = Depends(auth.get_current_user)):
    total_amount = 0.0
    bill_items = []
    
    # Calculate total and verify items
    for item in bill.items:
        product = db.query(models.Product).filter(models.Product.id == item.product_id).first()
        if not product:
            raise HTTPException(status_code=404, detail=f"Product with id {item.product_id} not found")

        item_total = product.price * item.quantity
        total_amount += item_total
        
        bill_items.append(models.BillItem(product_id=product.id, quantity=item.quantity, price=product.price))
        
        # Update stock
        product.stock -= item.quantity
    
    db_bill = models.Bill(total_amount=total_amount, payment_method=bill.payment_method)
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
def read_bills(skip: int = 0, limit: int = 100, db: database.SessionLocal = Depends(database.get_db), current_user: schemas.User = Depends(auth.get_current_user)):
    bills = db.query(models.Bill).offset(skip).limit(limit).all()
    return bills

@app.get("/bills/{bill_id}", response_model=schemas.Bill)
def read_bill(bill_id: int, db: database.SessionLocal = Depends(database.get_db), current_user: schemas.User = Depends(auth.get_current_user)):
    bill = db.query(models.Bill).filter(models.Bill.id == bill_id).first()
    if bill is None:
        raise HTTPException(status_code=404, detail="Bill not found")
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
