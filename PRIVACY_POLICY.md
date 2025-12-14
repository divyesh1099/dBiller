# Privacy Policy for dBiller

**Effective Date:** 2025-12-15  
**App Name:** dBiller  
**Platforms:** Android, Web  
**Company/Owner:** dBiller (internal project)

## Data We Collect
- **Account Data:** Username and password you provide to sign in. Passwords are hashed and never stored in plain text.
- **Device Identifiers:** Device ID used to enforce device limits and manage logins.
- **Store Profile:** Store name and optional store logo you upload.
- **Inventory & Billing Data:** Products, prices, stock counts, categories, and billing transactions created inside the app.
- **Images You Upload:** Product photos and receipt images for OCR/scan features.
- **Logs & Diagnostics:** Basic server logs (timestamps, endpoints) for troubleshooting. No chat or PII content is intentionally stored in logs.

## How We Use Data
- Authenticate users and manage device access.
- Store and manage inventory, billing, and receipts.
- Process images for OCR (scan items) to suggest products.
- Display store branding (logo) in the app.
- Maintain app security, prevent abuse, and improve reliability.

## Where Data Is Stored
- **Backend Database:** Inventory, billing, user, and device records.
- **Object Storage:** Uploaded images (product photos, store logos, scan uploads). In development we may store files locally under `/uploads`; in production we use configured object storage (e.g., S3/R2).

## Sharing
- We do **not** sell personal data.
- Data is shared only with infrastructure providers necessary to operate the service (e.g., hosting/object storage/CDN).

## Retention
- Data is kept while your account is active. We retain logs for a limited period for troubleshooting.
- You may request deletion of your account and associated data; some records may remain where required for security, audit, or legal compliance.

## Security
- Passwords are hashed; access requires authentication.
- Transport uses HTTPS when deployed behind TLS. Ensure your production deployment is served over HTTPS.
- Uploaded files are stored with controlled access; avoid uploading sensitive personal data.

## Your Choices
- You can manage products, store info, and uploaded images in the app.
- If you do not want OCR/scan, do not upload images for that feature.

## Children
- The app is not directed to children under 13 and should be used by business users only.

## Contact
- For privacy questions or data requests, contact the project owner/administrator.
