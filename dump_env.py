import os
base_dir = os.getcwd()
env_path = os.path.join(base_dir, 'backend', '.env')
dump_path = os.path.join(base_dir, 'env_dump.txt')

print(f"Reading from: {env_path}")
try:
    with open(env_path, 'r') as f:
        content = f.read()
    with open(dump_path, 'w') as f:
        f.write(content)
    print(f"Dumped to: {dump_path}")
    print(f"Content length: {len(content)}")
except Exception as e:
    print(f"Error: {e}")
