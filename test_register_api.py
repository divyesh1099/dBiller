import requests
import uuid

# Production URL
BASE_URL = "https://dbiller-production.up.railway.app"

# Read the license key from file
try:
    with open("backend/license_key.txt", "r") as f:
        LICENSE_KEY = f.read().strip()
    print(f"Using License Key: {LICENSE_KEY}")
except FileNotFoundError:
    print("❌ Error: backend/license_key.txt not found. Please run generate_license.py first.")
    exit(1) 

def test_full_flow():
    print(f"Testing Full Flow on {BASE_URL}")
    
    # 1. Register
    username = f"testuser_{uuid.uuid4().hex[:6]}"
    password = "password123"
    device_id = f"device_{uuid.uuid4().hex[:6]}"
    
    print(f"--- 1. Registering {username} ---")
    register_payload = {
        "username": username,
        "password": password,
        "device_id": device_id,
        "license_key": LICENSE_KEY,
        "store_name": "Test Store",
        "email": f"{username}@example.com" # Adding email just in case
    }
    
    try:
        reg_response = requests.post(f"{BASE_URL}/register", data=register_payload) # Note: requests.post(data=...) sends form-encoded, json=... sends JSON
        
        # Check if we messed up sending data vs json
        # If the API expects JSON, validation error "field required" might happen because we sent form data.
        
        if reg_response.status_code != 200:
            print(f"❌ Registration Failed: {reg_response.status_code}")
            print(f"Response Body: {reg_response.text}")
            return
        
        print("✅ Registration Successful!")
        
        # 2. Login
        print(f"--- 2. Logging in ---")
        login_payload = {
            "username": username,
            "password": password,
            "grant_type": "password",
            "device_id": device_id
        }
        
        login_response = requests.post(f"{BASE_URL}/token", data=login_payload)
        
        if login_response.status_code != 200:
            print(f"❌ Login Failed: {login_response.status_code}")
            print(f"Response Body: {login_response.text}")
            return
            
        token = login_response.json()["access_token"]
        print(f"✅ Login Successful! Token: {token[:10]}...")
        
        # 3. Fetch Invoices
        print(f"--- 3. Fetching Invoices ---")
        headers = {"Authorization": f"Bearer {token}"}
        
        inv_response = requests.get(f"{BASE_URL}/invoices/", headers=headers)
        
        if inv_response.status_code == 200:
            print("✅ Fetch Invoices Successful!")
            print(inv_response.json())
        else:
            print(f"❌ Fetch Invoices Failed: {inv_response.status_code}")
            print(f"Response Body: {inv_response.text}")

    except Exception as e:
        print(f"❌ Exception occurred: {e}")

if __name__ == "__main__":
    test_full_flow()
