import os

env_path = os.path.join(os.getcwd(), 'backend', '.env')

try:
    with open(env_path, 'r') as f:
        content = f.read()
    
    if "DEVICE_LIMIT" not in content:
        with open(env_path, 'a') as f:
            f.write("\nDEVICE_LIMIT=-1\n")
        print("Added DEVICE_LIMIT=-1 to .env")
    else:
        print("DEVICE_LIMIT already exists in .env")

except Exception as e:
    print(f"Error updating .env: {e}")
