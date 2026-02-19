
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import time
import threading

class PatternDemo:
    def __init__(self):
        self.engine = create_engine(
            "mysql+pymysql://root:Alfanash67@localhost/prod_sql_week2",
            pool_size=3,
            max_overflow=2
        )
        self.SessionLocal = sessionmaker(bind=self.engine)
    
    def pattern1_open_close(self, request_id):
        """Pattern 1: Open-Use-Close"""
        print(f"\n📞 Request {request_id}: Opening connection...")
        start = time.time()
        
        # OPEN
        conn = self.engine.connect()
        
        # USE
        result = conn.execute(text("SELECT SLEEP(0.5)"))
        
        # CLOSE
        conn.close()
        
        elapsed = (time.time() - start) * 1000
        print(f"   ✅ Completed in {elapsed:.2f}ms")
    
    def pattern2_connection_pool(self, request_id):
        """Pattern 2: Connection Pool"""
        print(f"\n🔄 Request {request_id}: Borrowing from pool...")
        start = time.time()
        
        # BORROW from pool
        conn = self.engine.connect()
        
        # USE
        result = conn.execute(text("SELECT SLEEP(0.5)"))
        
        # RETURN to pool (auto on context exit)
        conn.close()
        
        elapsed = (time.time() - start) * 1000
        print(f"   ✅ Completed in {elapsed:.2f}ms")
        print(f"   📊 Pool free: {self.engine.pool.checkedin()}")
    
    def pattern3_session(self, request_id):
        """Pattern 3: Session Pattern"""
        print(f"\n📝 Request {request_id}: Creating session...")
        start = time.time()
        
        # CREATE session (gets connection from pool)
        session = self.SessionLocal()
        
        try:
            # USE session for work
            result = session.execute(text("SELECT SLEEP(0.5)"))
            session.commit()
        finally:
            # CLOSE session (returns connection)
            session.close()
        
        elapsed = (time.time() - start) * 1000
        print(f"   ✅ Completed in {elapsed:.2f}ms")
    
    def run_comparison(self):
        """Compare all patterns"""
        print("="*60)
        print("🔬 DATABASE ACCESS PATTERNS COMPARISON")
        print("="*60)
        
        # Test Pattern 1
        print("\n📌 PATTERN 1: Open-Use-Close")
        print("-"*40)
        for i in range(3):
            self.pattern1_open_close(i)
        
        # Test Pattern 2
        print("\n📌 PATTERN 2: Connection Pool")
        print("-"*40)
        for i in range(5):
            self.pattern2_connection_pool(i)
        
        # Test Pattern 3
        print("\n📌 PATTERN 3: Session Pattern")
        print("-"*40)
        for i in range(3):
            self.pattern3_session(i)

if __name__ == "__main__":
    demo = PatternDemo()
    demo.run_comparison()