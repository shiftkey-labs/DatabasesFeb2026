# pooling_demo.py
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import time
import threading

DATABASE_URL = "mysql+pymysql://root:Alfanash67@localhost:3306/prod_sql_week2"

# Create engine with pooling
engine = create_engine(
    DATABASE_URL,
    pool_size=3,          
    max_overflow=1,
    pool_pre_ping=True,
    echo=True            
)

SessionLocal = sessionmaker(bind=engine)

def show_pool_status():
    """Display pool status using proper SQLAlchemy methods"""
    print(f"\n📊 Pool Status:")
    print(f"   - Size: {engine.pool.size()}")
    print(f"   - Overflow: {engine.pool._max_overflow}")
    
    # These are available:
    print(f"   - Checked-in connections: {engine.pool.checkedin()}")  # Connections available in the pool
    print(f"   - Total connections: {engine.pool.total()}")  # Remove this line because it does not exist
    
    # Instead, use this:
    pool_status = engine.pool.status()
    print(f"   - Pool status: {pool_status}")
    
    # If you want to see how many active connections exist:
    try:
        # This was an incorrect indirect way to see total connections
        print(f"   - Connections in use: {engine.pool.checkedin()}")  # This was wrong!
        # checkedin() means available connections, not connections currently in use
    except:
        pass

def show_pool_details():
    """Display more detailed pool information"""
    print(f"\n🔧 Pool Details:")
    print(f"   - Pool class: {engine.pool.__class__.__name__}")
    print(f"   - Pool size: {engine.pool.size()}")
    print(f"   - Overflow: {engine.pool._max_overflow}")
    print(f"   - Timeout: {engine.pool._timeout}")
    print(f"   - Recycle: {engine.pool._recycle}")
    
    # Number of available (ready-to-use) connections
    print(f"   - Connections ready: {engine.pool.checkedin()}")
    
    # Approximate number of total created connections
    # We cannot retrieve this directly, but we can observe how large the pool has grown

def test_connection_pooling():
    print("="*60)
    print("🔌 Testing Connection Pooling")
    print("="*60)
    
    # Initial state – no connections created yet
    show_pool_details()
    
    # First request – pool creates a new connection
    print("\n📨 Request 1:")
    with SessionLocal() as session:
        show_pool_details()
        session.execute(text("SELECT 1"))
        print("   ✅ Query executed")
    
    # After session closes, the connection returns to the pool
    print("\n🔄 After request 1 closed:")
    show_pool_details()
    
    # Second request – reuses the same previous connection
    print("\n📨 Request 2:")
    with SessionLocal() as session:
        show_pool_details()
        session.execute(text("SELECT 1"))
        print("   ✅ Query executed")
    
    print("\n🔄 After request 2 closed:")
    show_pool_details()

def test_concurrent_requests():
    """Test multiple concurrent requests"""
    print("\n" + "="*60)
    print("🔄 Testing Concurrent Requests")
    print("="*60)
    
    def worker(worker_id):
        print(f"   👤 Worker {worker_id}: start")
        with SessionLocal() as session:
            print(f"   👤 Worker {worker_id}: got connection")
            print(f"      Pool has {engine.pool.checkedin()} free connections")
            time.sleep(2)  # Simulate heavy work
            session.execute(text("SELECT SLEEP(1)"))  # Simulate heavier DB work
            print(f"   👤 Worker {worker_id}: finished the job")
        print(f"   👤 Worker {worker_id}: returned to pool")
        print(f"      Pool now has {engine.pool.checkedin()} free connections")
    
    # 7 concurrent requests (more than pool_size=3)
    threads = []
    for i in range(7):
        t = threading.Thread(target=worker, args=(i,))
        threads.append(t)
        t.start()
    
    # Wait for all threads to finish
    for t in threads:
        t.join()

def monitor_pool_during_requests():
    """Monitor pool while handling requests"""
    print("\n" + "="*60)
    print("📊 Monitoring Pool During Activity")
    print("="*60)
    
    print(f"\n🟢 Initial state:")
    print(f"   - Connections ready: {engine.pool.checkedin()}")
    
    for i in range(7):
        print(f"\n📨 Request {i+1}:")
        with SessionLocal() as session:
            print(f"   - Connections ready (during): {engine.pool.checkedin()}")
            session.execute(text("SELECT 1"))
            time.sleep(0.5)
        print(f"   - Connections ready (after): {engine.pool.checkedin()}")

if __name__ == "__main__":
    # Test 1: See how pooling works
    test_connection_pooling()
    
    # Test 2: Concurrent requests
    print("\n" + "="*60)
    test_concurrent_requests()
    
    # Test 3: Monitoring
    monitor_pool_during_requests()
