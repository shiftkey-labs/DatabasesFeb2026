# models.py
from sqlalchemy import Column, BigInteger, String, DateTime, DECIMAL, Integer, Enum, ForeignKey, Boolean, SmallInteger
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime
from pydantic import BaseModel, Field


Base = declarative_base()

class Customer(Base):
    __tablename__ = 'customers'
    
    customer_id = Column(BigInteger, primary_key=True)
    email = Column(String(255), nullable=False, unique=True)
    full_name = Column(String(255), nullable=False)
    country_code = Column(String(2), nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    
    # Relationship
    orders = relationship("Order", back_populates="customer")

class Product(Base):
    __tablename__ = 'products'
    
    product_id = Column(BigInteger, primary_key=True)
    sku = Column(String(50), nullable=False, unique=True)
    name = Column(String(255), nullable=False)
    category = Column(String(80), nullable=False)
    price = Column(DECIMAL(10,2), nullable=False)
    is_active = Column(Boolean, nullable=False, default=True)  # TINYINT(1) in MySQL maps to Boolean in SQLAlchemy
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    stock = Column(Integer, nullable=False, default=0)

    # Relationships
    order_items = relationship("OrderItem", back_populates="product")

class Order(Base):
    __tablename__ = 'orders'
    
    order_id = Column(BigInteger, primary_key=True)
    customer_id = Column(BigInteger, ForeignKey('customers.customer_id'), nullable=False)
    order_status = Column(Enum('NEW','PAID','SHIPPED','CANCELLED','REFUNDED'), nullable=False)
    order_total = Column(DECIMAL(10,2), nullable=False, default=0)
    placed_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    
    # Relationships
    customer = relationship("Customer", back_populates="orders")
    items = relationship("OrderItem", back_populates="order")

class OrderItem(Base):
    __tablename__ = 'order_items'
    
    order_item_id = Column(BigInteger, primary_key=True)
    order_id = Column(BigInteger, ForeignKey('orders.order_id'), nullable=False)
    product_id = Column(BigInteger, ForeignKey('products.product_id'), nullable=False)
    quantity = Column(Integer, nullable=False)
    unit_price = Column(DECIMAL(10,2), nullable=False)
    
    # Relationships
    order = relationship("Order", back_populates="items")
    product = relationship("Product", back_populates="order_items")

class PageView(Base):
    __tablename__ = 'page_views'
    
    view_id = Column(BigInteger, primary_key=True)
    customer_id = Column(BigInteger, ForeignKey('customers.customer_id'), nullable=True)
    product_id = Column(BigInteger, ForeignKey('products.product_id'), nullable=True)
    path = Column(String(255), nullable=False)
    viewed_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class PurchaseRequest(BaseModel):
    qty: int = Field(..., ge=1, description="Quantity to purchase (>= 1)")

class StockResetRequest(BaseModel):
    stock: int = Field(..., ge=0, description="New stock value (>= 0)")