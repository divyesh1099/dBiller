import pytesseract
from PIL import Image
import sys
import os

try:
    print(f"Python executable: {sys.executable}")
    # Create a simple image with text
    img = Image.new('RGB', (100, 30), color = (255, 255, 255))
    
    # Try multiple paths for tesseract
    possible_paths = [
        r"C:\Program Files\Tesseract-OCR\tesseract.exe",
        r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
        r"C:\ProgramData\chocolatey\bin\tesseract.exe",
    ]
    
    tesseract_cmd = "tesseract"
    for path in possible_paths:
        if os.path.exists(path):
            tesseract_cmd = path
            break
            
    pytesseract.pytesseract.tesseract_cmd = tesseract_cmd
    print(f"Using tesseract binary: {tesseract_cmd}")

    # Try to get tesseract version
    version = pytesseract.get_tesseract_version()
    print(f"Tesseract Version: {version}")
    print("Tesseract is correctly installed and accessible by Python.")
except Exception as e:
    print(f"Error: {e}")
    print("Ensure tesseract is in your PATH or set pytesseract.pytesseract.tesseract_cmd")
