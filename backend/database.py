from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

# Default to sqlite if not set (for safety/dev), but production will throw if not set properly eventually
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./dbiller.db")

# Postgres requires a different connect string format if using certain drivers, 
# typically 'postgresql://user:password@host/dbname'
# Neon provides 'postgres://', which SQLAlchemy handles fine usually.

engine = create_engine(SQLALCHEMY_DATABASE_URL)
if "sqlite" in SQLALCHEMY_DATABASE_URL:
     engine = create_engine(
        SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
