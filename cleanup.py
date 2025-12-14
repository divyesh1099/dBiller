import os
try:
    if os.path.exists("dump_frontend.py"): os.remove("dump_frontend.py")
    if os.path.exists("frontend_dump.txt"): os.remove("frontend_dump.txt")
    if os.path.exists("restore_env.py"): os.remove("restore_env.py")
    print("Cleaned up.")
except Exception as e:
    print(f"Error: {e}")
