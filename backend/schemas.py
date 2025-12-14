from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime

# User Schemas
class UserBase(BaseModel):
    username: str
    role: str = "staff"

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    is_active: bool

    class Config:
        orm_mode = True

# Product Schemas
class ProductBase(BaseModel):
    name: str
    price: float
    stock: int = 0
    image_url: Optional[str] = None
    category: Optional[str] = None

class ProductCreate(ProductBase):
    pass

class Product(ProductBase):
    id: int

    class Config:
        orm_mode = True


class Store(BaseModel):
    id: int
    name: str
    logo_url: Optional[str] = None

    class Config:
        orm_mode = True

# Billing Schemas
class BillItemBase(BaseModel):
    product_id: int
    quantity: int

class BillCreate(BaseModel):
    items: List[BillItemBase]
    payment_method: str = "cash"

class BillItem(BillItemBase):
    id: int
    price: float
    product: Product

    class Config:
        orm_mode = True

class Bill(BaseModel):
    id: int
    created_at: datetime
    total_amount: float
    payment_method: str
    items: List[BillItem]

    class Config:
        orm_mode = True

# Token Schema
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None

class UserRegister(BaseModel):
    username: str
    password: str
    business_name: Optional[str] = None
    device_id: str
    license_key: str
    store_name: Optional[str] = None
