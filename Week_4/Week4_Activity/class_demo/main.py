from fastapi import FastAPI, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import text
from db import get_db
from typing import Optional  # ← Add this import
from sqlalchemy.exc import OperationalError
import time, random
from models import Product
from pydantic import BaseModel, Field
from models import Product


class PurchaseRequest(BaseModel):
    qty: int = Field(..., ge=1)

class StockResetRequest(BaseModel):
    stock: int = Field(..., ge=0)
    
app = FastAPI(title="Week 3: Databases Behind APIs")

@app.get("/health")
def health(db: Session = Depends(get_db)):
    r = db.execute(text("SELECT 1 as ok")).mappings().one()
    return {"status": "ok", "db": r["ok"]}

# -----------------------
# Endpoint 1: ORM example
# -----------------------
@app.get("/products")
def list_products(
    # Fixed: Use Optional instead of | for Python 3.9
    category: Optional[str] = Query(None, description="Filter by category"),
    active_only: bool = True,
    min_price: Optional[float] = Query(None, description="Minimum price"),
    max_price: Optional[float] = Query(None, description="Maximum price"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    q = db.query(Product)

    if category:
        q = q.filter(Product.category == category)
    if active_only:
        q = q.filter(Product.is_active == True)  # Fixed: Use True instead of 1
    if min_price is not None:
        q = q.filter(Product.price >= min_price)
    if max_price is not None:
        q = q.filter(Product.price <= max_price)

    total = q.count()
    rows = q.order_by(Product.product_id).offset(offset).limit(limit).all()

    return {
        "meta": {"total": total, "limit": limit, "offset": offset},
        "items": [
            {
                "product_id": r.product_id,
                "sku": r.sku,
                "name": r.name,
                "category": r.category,
                "price": float(r.price),
                "is_active": int(r.is_active),
                "stock":int(r.stock)
            }
            for r in rows
        ],
    }


# --------------------------
# Endpoint 2: Raw SQL example
# --------------------------
@app.get("/customers/{customer_id}/orders")
def customer_orders(
    customer_id: int, 
    db: Session = Depends(get_db)
):
    sql = text("""
        SELECT
          o.order_id,
          o.order_status,
          o.order_total,
          o.placed_at,
          COUNT(oi.order_item_id) AS item_lines
        FROM orders o
        LEFT JOIN order_items oi ON oi.order_id = o.order_id
        WHERE o.customer_id = :cid
        GROUP BY o.order_id
        ORDER BY o.placed_at DESC
        LIMIT 50
    """)
    rows = db.execute(sql, {"cid": customer_id}).mappings().all()
    if not rows:
        # could be "no orders" or invalid customer, keep it simple for lab:
        return {"customer_id": customer_id, "orders": []}
    return {"customer_id": customer_id, "orders": [dict(r) for r in rows]}

# --------------------------
# Endpoint 3: Analytics (SQL)
# --------------------------
@app.get("/analytics/top-products")
def top_products(
    hours: int = Query(72, ge=1, le=720), 
    db: Session = Depends(get_db)
):
    sql = text("""
        SELECT
          p.product_id,
          p.name,
          p.category,
          COUNT(*) AS views
        FROM page_views pv
        JOIN products p ON p.product_id = pv.product_id
        WHERE pv.product_id IS NOT NULL
          AND pv.viewed_at >= NOW() - INTERVAL :h HOUR
        GROUP BY p.product_id, p.name, p.category
        ORDER BY views DESC
        LIMIT 10
    """)
    rows = db.execute(sql, {"h": hours}).mappings().all()
    return {"window_hours": hours, "top_products": [dict(r) for r in rows]}



@app.get("/products/{product_id}/stock")
def get_stock(product_id: int, db: Session = Depends(get_db)):
    p = db.query(Product).filter(Product.product_id == product_id).one_or_none()
    if not p:
        raise HTTPException(status_code=404, detail="product not found")
    return {"product_id": int(p.product_id), "sku": p.sku, "stock": int(p.stock)}

@app.post("/products/{product_id}/stock/reset")
def reset_stock(product_id: int, body: StockResetRequest, db: Session = Depends(get_db)):
    with db.begin():
        p = (
            db.query(Product)
            .filter(Product.product_id == product_id)
            .with_for_update()
            .one_or_none()
        )
        if not p:
            raise HTTPException(status_code=404, detail="product not found")
        p.stock = body.stock
        db.add(p)

    return {"ok": True, "product_id": int(product_id), "new_stock": int(body.stock)}

# -----------------------------
# UNSAFE: Demonstrates race bugs
# -----------------------------
@app.post("/products/{product_id}/purchase-unsafe")
def purchase_unsafe(product_id: int, body: PurchaseRequest, db: Session = Depends(get_db)):
    p = db.query(Product).filter(Product.product_id == product_id).one_or_none()
    if not p:
        raise HTTPException(status_code=404, detail="product not found")

    if p.stock < body.qty:
        raise HTTPException(status_code=409, detail="insufficient stock")

    # optional: widen the race window so it breaks more reliably in class
    time.sleep(random.uniform(0.001, 0.01))

    p.stock -= body.qty
    db.add(p)
    db.commit()
    db.refresh(p)

    return {"ok": True, "product_id": int(product_id), "remaining_stock": int(p.stock)}

# -----------------------------
# SAFE: Transaction + row lock
# -----------------------------
@app.post("/products/{product_id}/purchase")
def purchase_safe(product_id: int, body: PurchaseRequest, db: Session = Depends(get_db)):
    try:
        with db.begin():
            p = (
                db.query(Product)
                .filter(Product.product_id == product_id)
                .with_for_update()
                .one_or_none()
            )
            if not p:
                raise HTTPException(status_code=404, detail="product not found")

            if p.stock < body.qty:
                raise HTTPException(status_code=409, detail="insufficient stock")

            p.stock -= body.qty
            db.add(p)

        return {"ok": True, "product_id": int(product_id), "remaining_stock": int(p.stock)}

    except OperationalError:
        # lock wait timeout / deadlock under high contention
        raise HTTPException(status_code=409, detail="conflict, retry")
    
@app.get("/products/{product_id}/stock")
def product_stock(product_id: int, db: Session = Depends(get_db)):
    p = db.query(Product).filter(Product.product_id == product_id).one_or_none()
    if not p:
        raise HTTPException(status_code=404, detail="product not found")
    return {"product_id": product_id, "stock": p.stock}