import uuid
from database import SessionLocal, engine
import models

# Ensure tables exist
models.Base.metadata.create_all(bind=engine)

def generate_key():
    db = SessionLocal()
    key = str(uuid.uuid4())
    license_obj = models.License(key=key)
    db.add(license_obj)
    db.commit()
    print(f"Generated License Key: {key}")
    db.close()

if __name__ == "__main__":
    generate_key()
