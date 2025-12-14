from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime
from sqlalchemy.orm import relationship
import datetime
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    role = Column(String, default="staff")  # admin, staff
    is_active = Column(Boolean, default=True)

    devices = relationship("UserDevice", back_populates="user")

class UserDevice(Base):
    __tablename__ = "user_devices"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    device_id = Column(String, index=True) # Unique ID from frontend
    last_login = Column(DateTime, default=datetime.datetime.utcnow)

    user = relationship("User", back_populates="devices")

class License(Base):
    __tablename__ = "licenses"

    id = Column(Integer, primary_key=True, index=True)
    key = Column(String, unique=True, index=True)
    is_used = Column(Boolean, default=False)
    used_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)


class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    price = Column(Float)
    image_url = Column(String, nullable=True)
    stock = Column(Integer, default=0)

class Bill(Base):
    __tablename__ = "bills"

    id = Column(Integer, primary_key=True, index=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    total_amount = Column(Float)
    payment_method = Column(String, default="cash")
    
    items = relationship("BillItem", back_populates="bill")

class BillItem(Base):
    __tablename__ = "bill_items"

    id = Column(Integer, primary_key=True, index=True)
    bill_id = Column(Integer, ForeignKey("bills.id"))
    product_id = Column(Integer, ForeignKey("products.id"))
    quantity = Column(Integer)
    price = Column(Float) # Store snapshot of price at time of billing

    bill = relationship("Bill", back_populates="items")
    product = relationship("Product")

class Subscription(Base):
    __tablename__ = "subscriptions"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    price = Column(Float)
    duration_days = Column(Integer)
    description = Column(String, nullable=True)
