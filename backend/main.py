from fastapi import FastAPI, Depends, HTTPException, status, Form
from fastapi.middleware.cors import CORSMiddleware
from datetime import timedelta
from typing import List
from database import engine, Base
import models, schemas, database
import datetime
from fastapi.security import OAuth2PasswordRequestForm
import auth

# Create database tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="dBiller API")

# CORS setup
origins = [
    "http://localhost",
    "http://localhost:8000",
    "http://localhost:3000", # Common for flutter web
    "*" # For development
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
        device_count = db.query(models.UserDevice).filter(models.UserDevice.user_id == user.id).count()
        if device_count >= 2:
             raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Device limit reached (Max 2 devices). Contact admin.",
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
def register_user(user: schemas.UserRegister, db: database.SessionLocal = Depends(database.get_db)):
    # 1. Verify License
    license_obj = db.query(models.License).filter(models.License.key == user.license_key, models.License.is_used == False).first()
    if not license_obj:
        raise HTTPException(status_code=400, detail="Invalid or used License Key")

    # 2. Verify Username
    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    
    hashed_password = auth.get_password_hash(user.password)
    db_user = models.User(username=user.username, hashed_password=hashed_password, role="admin") 
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    # 3. Mark License Used
    license_obj.is_used = True
    license_obj.used_by_user_id = db_user.id
    db.commit()

    # Register the device they signed up with
    db_device = models.UserDevice(user_id=db_user.id, device_id=user.device_id)
    db.add(db_device)
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
from fastapi import File, UploadFile, Form

# Product Routes
@app.post("/products/", response_model=schemas.Product)
async def create_product(
    name: str = Form(...),
    price: float = Form(...),
    stock: int = Form(0),
    image: UploadFile = File(None),
    db: database.SessionLocal = Depends(database.get_db),
    current_user: schemas.User = Depends(auth.get_current_user)
):
    image_url = None
    if image:
        image_url = await storage.upload_file_to_r2(image)
    
    product_data = schemas.ProductCreate(name=name, price=price, stock=stock, image_url=image_url)
    db_product = models.Product(**product_data.dict())
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return db_product

@app.get("/products/", response_model=List[schemas.Product])
def read_products(skip: int = 0, limit: int = 100, db: database.SessionLocal = Depends(database.get_db)):
    products = db.query(models.Product).offset(skip).limit(limit).all()
    return products

@app.get("/products/{product_id}", response_model=schemas.Product)
def read_product(product_id: int, db: database.SessionLocal = Depends(database.get_db)):
    db_product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if db_product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return db_product

@app.put("/products/{product_id}", response_model=schemas.Product)
def update_product(product_id: int, product: schemas.ProductCreate, db: database.SessionLocal = Depends(database.get_db), current_user: schemas.User = Depends(auth.get_current_user)):
    db_product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if db_product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    for key, value in product.dict().items():
        setattr(db_product, key, value)
    db.commit()
    db.refresh(db_product)
    return db_product

@app.delete("/products/{product_id}")
def delete_product(product_id: int, db: database.SessionLocal = Depends(database.get_db), current_user: schemas.User = Depends(auth.get_current_user)):
    db_product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if db_product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    db.delete(db_product)
    db.commit()
    return {"message": "Product deleted successfully"}

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

# Image Recognition Stub
from fastapi import File, UploadFile
import random

@app.post("/recognize/", response_model=List[schemas.Product])
def recognize_product(file: UploadFile = File(...), db: database.SessionLocal = Depends(database.get_db), current_user: schemas.User = Depends(auth.get_current_user)):
    # In a real app, this would use an ML model to process the image 'file'
    # For now, return random products from the database to simulate recognition
    all_products = db.query(models.Product).all()
    if not all_products:
        return []
    
    # Simulate finding 1-3 matching products
    return random.sample(all_products, min(len(all_products), 3))
