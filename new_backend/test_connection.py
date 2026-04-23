import asyncio
from app.core.config import settings
from sqlalchemy.ext.asyncio import create_async_engine

async def test_engine():
    url = settings.DATABASE_URL
    print(f"DATABASE_URL: {url}")
    
    engine = create_async_engine(
        url,
        pool_size=5,
        max_overflow=2,
        pool_pre_ping=True,
        connect_args={
            "ssl": False,
            "server_settings": {"application_name": "dharma_cms"},
        },
        echo=False
    )
    
    try:
        async with engine.begin() as conn:
            print("[OK] Connected to PostgreSQL!")
    except Exception as e:
        print(f"[ERROR] {type(e).__name__}: {e}")
    finally:
        await engine.dispose()

if __name__ == "__main__":
    asyncio.run(test_engine())
