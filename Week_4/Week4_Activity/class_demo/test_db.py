from sqlalchemy import text
from db import engine

with engine.connect() as conn:
    r = conn.execute(text("SELECT 1")).scalar()
    print("DB says:", r)
