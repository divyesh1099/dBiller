import requests
import uuid

# Production URL
BASE_URL = "https://dbiller-production.up.railway.app"
# Use the license key generated
LICENSE_KEY = "9492cf32-3b7e-4caa-a0c5-194b967da3ec" 

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
        "store_name": "Test Store"
    }
    
    try:
        reg_response = requests.post(f"{BASE_URL}/register", data=register_payload)
        
        if reg_response.status_code != 200:
            print(f"❌ Registration Failed: {reg_response.status_code} {reg_response.text}")
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
            print(f"❌ Login Failed: {login_response.status_code} {login_response.text}")
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
