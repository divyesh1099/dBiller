from typing import List, Optional, Dict, Any
from pydantic import BaseModel
from datetime import datetime

# Permission and Role Schemas
class PermissionBase(BaseModel):
    name: str
    description: Optional[str] = None

class PermissionCreate(PermissionBase):
    pass

class PermissionUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None

class Permission(PermissionBase):
    id: int

    class Config:
        orm_mode = True

class RoleBase(BaseModel):
    name: str
    description: Optional[str] = None

class RoleCreate(RoleBase):
    pass

class RoleUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None

class Role(RoleBase):
    id: int
    permissions: List[Permission] = []

    class Config:
        orm_mode = True

class RoleAssignment(BaseModel):
    role_ids: List[int] = []

class PermissionAssignment(BaseModel):
    permission_ids: List[int] = []

# User Schemas
class UserBase(BaseModel):
    username: str
    full_name: Optional[str] = None
    user_code: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    role: str = "staff"
    active_account: bool = True
    profile_photo: Optional[str] = None
    organization_id: Optional[int] = None

class UserCreate(UserBase):
    password: str
    role_ids: Optional[List[int]] = None
    permission_ids: Optional[List[int]] = None

class UserUpdate(BaseModel):
    username: Optional[str] = None
    full_name: Optional[str] = None
    user_code: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    role: Optional[str] = None
    active_account: Optional[bool] = None
    profile_photo: Optional[str] = None
    organization_id: Optional[int] = None
    password: Optional[str] = None
    role_ids: Optional[List[int]] = None
    permission_ids: Optional[List[int]] = None

class User(UserBase):
    id: int
    roles: List[Role] = []
    permissions: List[Permission] = []

    class Config:
        orm_mode = True

# Organization Schemas
class OrganizationBase(BaseModel):
    name: str
    logo_url: Optional[str] = None
    company_name: Optional[str] = None
    business_type: Optional[str] = None
    tax_id: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    status: str = "active"
    subscription_id: Optional[int] = None
    trial_ends_at: Optional[datetime] = None
    current_period_end: Optional[datetime] = None
    node_limit: Optional[int] = None

class OrganizationCreate(OrganizationBase):
    pass

class OrganizationUpdate(BaseModel):
    name: Optional[str] = None
    logo_url: Optional[str] = None
    company_name: Optional[str] = None
    business_type: Optional[str] = None
    tax_id: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    status: Optional[str] = None
    subscription_id: Optional[int] = None
    trial_ends_at: Optional[datetime] = None
    current_period_end: Optional[datetime] = None
    node_limit: Optional[int] = None

class Organization(OrganizationBase):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True

# Subscription Schemas
class SubscriptionBase(BaseModel):
    name: str
    price: Optional[float] = None
    currency: str = "USD"
    monthly_price: Optional[float] = None
    annual_price: Optional[float] = None
    features: Optional[List[str]] = None
    limits: Optional[Dict[str, Any]] = None
    description: Optional[str] = None
    badge_text: Optional[str] = None
    is_featured: bool = False
    is_active: bool = True

class SubscriptionCreate(SubscriptionBase):
    pass

class SubscriptionUpdate(BaseModel):
    name: Optional[str] = None
    price: Optional[float] = None
    currency: Optional[str] = None
    monthly_price: Optional[float] = None
    annual_price: Optional[float] = None
    features: Optional[List[str]] = None
    limits: Optional[Dict[str, Any]] = None
    description: Optional[str] = None
    badge_text: Optional[str] = None
    is_featured: Optional[bool] = None
    is_active: Optional[bool] = None

class Subscription(SubscriptionBase):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True

# Supplier Schemas
class SupplierBase(BaseModel):
    name: str
    company_name: Optional[str] = None
    contact_name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    tax_id: Optional[str] = None
    status: str = "active"
    logo_url: Optional[str] = None
    category: Optional[str] = None
    supplier_code: Optional[str] = None
    is_active: bool = True
    organization_id: Optional[int] = None

class SupplierCreate(SupplierBase):
    pass

class SupplierUpdate(BaseModel):
    name: Optional[str] = None
    company_name: Optional[str] = None
    contact_name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    tax_id: Optional[str] = None
    status: Optional[str] = None
    logo_url: Optional[str] = None
    category: Optional[str] = None
    supplier_code: Optional[str] = None
    is_active: Optional[bool] = None
    organization_id: Optional[int] = None

class Supplier(SupplierBase):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True

# Item Schemas
class ItemBase(BaseModel):
    name: str
    description: Optional[str] = None
    sku: Optional[str] = None
    category: Optional[str] = None
    tags: Optional[List[str]] = None
    barcode: Optional[str] = None
    unit_price: float
    currency: str = "USD"
    stock: int = 0
    reorder_point: Optional[int] = None
    min_stock: Optional[int] = None
    max_stock: Optional[int] = None
    warehouse_aisle: Optional[str] = None
    bin_location: Optional[str] = None
    image_url: Optional[str] = None
    is_active: bool = True
    ai_verified: bool = False
    ai_confidence: Optional[float] = None
    supplier_id: Optional[int] = None
    organization_id: Optional[int] = None

class ItemCreate(ItemBase):
    pass

class ItemUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    sku: Optional[str] = None
    category: Optional[str] = None
    tags: Optional[List[str]] = None
    barcode: Optional[str] = None
    unit_price: Optional[float] = None
    currency: Optional[str] = None
    stock: Optional[int] = None
    reorder_point: Optional[int] = None
    min_stock: Optional[int] = None
    max_stock: Optional[int] = None
    warehouse_aisle: Optional[str] = None
    bin_location: Optional[str] = None
    image_url: Optional[str] = None
    is_active: Optional[bool] = None
    ai_verified: Optional[bool] = None
    ai_confidence: Optional[float] = None
    supplier_id: Optional[int] = None
    organization_id: Optional[int] = None

class Item(ItemBase):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True

# Stock Movement Schemas
class StockMovementBase(BaseModel):
    item_id: int
    movement_type: str
    quantity_change: int
    status: str = "success"
    reference: Optional[str] = None
    notes: Optional[str] = None
    user_id: Optional[int] = None

class StockMovementCreate(StockMovementBase):
    pass

class StockMovementUpdate(BaseModel):
    movement_type: Optional[str] = None
    quantity_change: Optional[int] = None
    status: Optional[str] = None
    reference: Optional[str] = None
    notes: Optional[str] = None
    user_id: Optional[int] = None

class StockMovement(StockMovementBase):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True

# Product Schemas
class ProductBase(BaseModel):
    name: str
    price: float
    stock: int = 0
    image_url: Optional[str] = None
    category: Optional[str] = None
    organization_id: Optional[int] = None

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

# Order Schemas
class OrderItemBase(BaseModel):
    item_id: Optional[int] = None
    description: Optional[str] = None
    sku: Optional[str] = None
    image_url: Optional[str] = None
    quantity: int
    unit_price: Optional[float] = None
    ai_verified: Optional[bool] = None
    ai_confidence: Optional[float] = None

class OrderItemCreate(OrderItemBase):
    pass

class OrderItem(OrderItemBase):
    id: int
    line_total: float
    item: Optional[Item] = None

    class Config:
        orm_mode = True

class OrderBase(BaseModel):
    order_number: Optional[str] = None
    status: str = "pending"
    order_type: Optional[str] = None
    supplier_id: Optional[int] = None
    customer_name: Optional[str] = None
    customer_email: Optional[str] = None
    customer_phone: Optional[str] = None
    billing_address: Optional[str] = None
    shipping_address: Optional[str] = None
    notes: Optional[str] = None
    shipping_fee: float = 0
    tax: float = 0
    currency: str = "USD"
    organization_id: Optional[int] = None
    user_id: Optional[int] = None
    confirmed_at: Optional[datetime] = None
    shipped_at: Optional[datetime] = None
    delivered_at: Optional[datetime] = None
    cancelled_at: Optional[datetime] = None
    expected_delivery_at: Optional[datetime] = None

class OrderCreate(OrderBase):
    items: List[OrderItemCreate]

class OrderUpdate(BaseModel):
    order_number: Optional[str] = None
    status: Optional[str] = None
    order_type: Optional[str] = None
    supplier_id: Optional[int] = None
    customer_name: Optional[str] = None
    customer_email: Optional[str] = None
    customer_phone: Optional[str] = None
    billing_address: Optional[str] = None
    shipping_address: Optional[str] = None
    notes: Optional[str] = None
    shipping_fee: Optional[float] = None
    tax: Optional[float] = None
    currency: Optional[str] = None
    organization_id: Optional[int] = None
    user_id: Optional[int] = None
    confirmed_at: Optional[datetime] = None
    shipped_at: Optional[datetime] = None
    delivered_at: Optional[datetime] = None
    cancelled_at: Optional[datetime] = None
    expected_delivery_at: Optional[datetime] = None
    items: Optional[List[OrderItemCreate]] = None

class Order(OrderBase):
    id: int
    subtotal: float
    total_amount: float
    created_at: datetime
    updated_at: datetime
    items: List[OrderItem]

    class Config:
        orm_mode = True

# Invoice Schemas
class InvoiceItemBase(BaseModel):
    item_id: Optional[int] = None
    description: Optional[str] = None
    sku: Optional[str] = None
    image_url: Optional[str] = None
    quantity: int
    unit_price: Optional[float] = None

class InvoiceItemCreate(InvoiceItemBase):
    pass

class InvoiceItem(InvoiceItemBase):
    id: int
    line_total: float
    item: Optional[Item] = None

    class Config:
        orm_mode = True

class InvoiceBase(BaseModel):
    invoice_number: Optional[str] = None
    status: str = "draft"
    issue_date: Optional[datetime] = None
    due_date: Optional[datetime] = None
    source_url: Optional[str] = None
    source_type: Optional[str] = None
    ai_extracted: bool = False
    paid_at: Optional[datetime] = None
    customer_name: Optional[str] = None
    customer_email: Optional[str] = None
    billing_address: Optional[str] = None
    shipping_address: Optional[str] = None
    tax: float = 0
    discount: float = 0
    currency: str = "USD"
    order_id: Optional[int] = None
    organization_id: Optional[int] = None

class InvoiceCreate(InvoiceBase):
    items: List[InvoiceItemCreate]

class InvoiceUpdate(BaseModel):
    invoice_number: Optional[str] = None
    status: Optional[str] = None
    issue_date: Optional[datetime] = None
    due_date: Optional[datetime] = None
    source_url: Optional[str] = None
    source_type: Optional[str] = None
    ai_extracted: Optional[bool] = None
    paid_at: Optional[datetime] = None
    customer_name: Optional[str] = None
    customer_email: Optional[str] = None
    billing_address: Optional[str] = None
    shipping_address: Optional[str] = None
    tax: Optional[float] = None
    discount: Optional[float] = None
    currency: Optional[str] = None
    order_id: Optional[int] = None
    organization_id: Optional[int] = None
    items: Optional[List[InvoiceItemCreate]] = None

class Invoice(InvoiceBase):
    id: int
    subtotal: float
    total_amount: float
    created_at: datetime
    updated_at: datetime
    items: List[InvoiceItem]

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
    organization_id: Optional[int] = None

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
