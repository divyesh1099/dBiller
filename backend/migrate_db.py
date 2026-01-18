import os
import sys
from sqlalchemy import create_engine, text, inspect
from dotenv import load_dotenv

# Load env vars
load_dotenv()

# Get DB URL from env or argument
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    print("Error: DATABASE_URL is not set.")
    sys.exit(1)

print(f"Connecting to: {DATABASE_URL.split('@')[-1]}") # Print host only for safety

try:
    engine = create_engine(DATABASE_URL)
except Exception as e:
    print(f"Configuration Error: {e}")
    sys.exit(1)

def migrate():
    print("Starting schema migration...")
    inspector = inspect(engine)
    
    # Map of table -> list of (column_name, column_type_def)
    required_columns = {
        "products": [("category", "VARCHAR")],
        "stores": [("dummy_check", "INTEGER")],
        "users": [
            ("email", "VARCHAR"),
            ("phone", "VARCHAR"),
            ("profile_photo", "VARCHAR"),
            ("organization_id", "INTEGER"),
            ("full_name", "VARCHAR"),
            ("user_code", "VARCHAR"),
        ],
        "organizations": [
            ("logo_url", "VARCHAR"),
            ("status", "VARCHAR"),
            ("subscription_id", "INTEGER"),
            ("trial_ends_at", "TIMESTAMP"),
            ("current_period_end", "TIMESTAMP"),
            ("node_limit", "INTEGER"),
        ],
        "subscriptions": [
            ("currency", "VARCHAR"),
            ("monthly_price", "FLOAT"),
            ("annual_price", "FLOAT"),
            ("features", "TEXT"),
            ("limits", "TEXT"),
            ("description", "TEXT"),
            ("badge_text", "VARCHAR"),
            ("is_featured", "BOOLEAN"),
            ("is_active", "BOOLEAN"),
            ("created_at", "TIMESTAMP"),
        ],
        "suppliers": [
            ("contact_name", "VARCHAR"),
            ("status", "VARCHAR"),
            ("logo_url", "VARCHAR"),
            ("category", "VARCHAR"),
            ("supplier_code", "VARCHAR"),
        ],
        "items": [
            ("category", "VARCHAR"),
            ("tags", "TEXT"),
            ("barcode", "VARCHAR"),
            ("reorder_point", "INTEGER"),
            ("min_stock", "INTEGER"),
            ("max_stock", "INTEGER"),
            ("warehouse_aisle", "VARCHAR"),
            ("bin_location", "VARCHAR"),
            ("ai_verified", "BOOLEAN"),
            ("ai_confidence", "FLOAT"),
        ],
        "orders": [
            ("order_number", "VARCHAR"),
            ("supplier_id", "INTEGER"),
            ("customer_name", "VARCHAR"),
            ("customer_email", "VARCHAR"),
            ("customer_phone", "VARCHAR"),
            ("billing_address", "TEXT"),
            ("notes", "TEXT"),
            ("confirmed_at", "TIMESTAMP"),
            ("shipped_at", "TIMESTAMP"),
            ("delivered_at", "TIMESTAMP"),
            ("cancelled_at", "TIMESTAMP"),
            ("expected_delivery_at", "TIMESTAMP"),
        ],
        "order_items": [
            ("sku", "VARCHAR"),
            ("image_url", "VARCHAR"),
            ("ai_verified", "BOOLEAN"),
            ("ai_confidence", "FLOAT"),
        ],
        "invoices": [
            ("source_url", "VARCHAR"),
            ("source_type", "VARCHAR"),
            ("ai_extracted", "BOOLEAN"),
            ("paid_at", "TIMESTAMP"),
        ],
        "invoice_items": [
            ("sku", "VARCHAR"),
            ("image_url", "VARCHAR"),
        ],
    }

    try:
        existing_tables = inspector.get_table_names()
        print(f"Found tables: {existing_tables}")
        
        with engine.begin() as conn:
            for table, columns in required_columns.items():
                if table in existing_tables:
                    existing_cols = [c["name"] for c in inspector.get_columns(table)]
                    for col_name, col_def in columns:
                        if col_name not in existing_cols:
                            print(f"Adding column {col_name} to {table}...")
                            try:
                                conn.execute(text(f"ALTER TABLE {table} ADD COLUMN {col_name} {col_def}"))
                                print(f" - Success")
                            except Exception as e:
                                print(f" - Error: {e}")
                        else:
                            # print(f"Column {col_name} exists in {table}")
                            pass
                else:
                    print(f"Table {table} not found. Skipping.")
    except Exception as e:
        print(f"Schema migration failed: {e}")

if __name__ == "__main__":
    migrate()
