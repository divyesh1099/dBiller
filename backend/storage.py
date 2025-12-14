import boto3
import os
from botocore.exceptions import NoCredentialsError
from fastapi import UploadFile
import uuid

# R2 Configuration
R2_ENDPOINT_URL = os.getenv("R2_ENDPOINT_URL")
R2_ACCESS_KEY_ID = os.getenv("R2_ACCESS_KEY_ID")
R2_SECRET_ACCESS_KEY = os.getenv("R2_SECRET_ACCESS_KEY")
R2_BUCKET_NAME = os.getenv("R2_BUCKET_NAME", "dbiller-images")
PUBLIC_BASE_URL = os.getenv("PUBLIC_BASE_URL", "http://localhost:8001")

def get_s3_client():
    if not R2_ENDPOINT_URL or not R2_ACCESS_KEY_ID or not R2_SECRET_ACCESS_KEY:
        print("R2 Credentials not set. Falling back to local storage.")
        return None
        
    return boto3.client(
        's3',
        endpoint_url=R2_ENDPOINT_URL,
        aws_access_key_id=R2_ACCESS_KEY_ID,
        aws_secret_access_key=R2_SECRET_ACCESS_KEY
    )

async def upload_file_to_r2(file: UploadFile, folder: str = "products") -> str:
    s3 = get_s3_client()
    # Enable reading file content
    file_content = await file.read()
    
    # Generate unique filename
    file_extension = file.filename.split(".")[-1]
    filename = f"{folder}/{uuid.uuid4()}.{file_extension}"

    def _save_locally() -> str:
        os.makedirs("uploads", exist_ok=True)
        local_path = os.path.join("uploads", filename)
        os.makedirs(os.path.dirname(local_path), exist_ok=True)
        with open(local_path, "wb") as f:
            f.write(file_content)
        print(f"[upload_debug] saved local file at {local_path} ({len(file_content)} bytes)")
        # Return relative URL so frontend can resolve it against its own API base
        return f"/uploads/{filename}"

    # Local fallback
    if not s3:
        return _save_locally()

    try:
        s3.put_object(
            Bucket=R2_BUCKET_NAME,
            Key=filename,
            Body=file_content,
            ContentType=file.content_type
            # ACL='public-read' # R2 buckets are usually private or public via domain. 
            # If public bucket, we don't need ACL usually or it's not supported identically.
        )
        
        # Reset file pointer if needed downstream? Usually not if we consumed it.
        # But we return the URL.
        
        # Assuming R2 bucket is connected to a public domain or we construct the R2 dev URL
        # For pure R2, URL is often: https://<account>.r2.cloudflarestorage.com/<bucket>/<key>
        # Or better: https://custom.domain.com/<key>
        # We will return a constructable URL or just the Key if user configures a public domain.
        # For now, let's assume a public domain variable or return the direct R2 URL format 
        # (which requires auth usually unless public access is on). 
        # User didn't specify public domain, so we'll assume standard public access enabled on bucket.
        
        # We will rely on user setting a PUBLIC_URL_BASE env var, or return a placeholder relative path.
        # Let's return the full URL if we can guess it, otherwise just the key.
        
        # Best practice for R2: If pub access enabled (dev mode), use the R2.dev subdomain if enabled or custom domain.
        # I'll use a placeholder variable for the base URL.
        
        public_url_base = os.getenv("R2_PUBLIC_URL_BASE", "") # e.g., https://pub-xyz.r2.dev
        if public_url_base:
            return f"{public_url_base}/{filename}"
        
        return filename 
        
    except Exception as e:
        print(f"Upload Error: {e}. Falling back to local storage.")
        return _save_locally()
