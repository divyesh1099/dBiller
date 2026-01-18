# Use an official Python runtime as a parent image
FROM python:3.10-slim

# Set the working directory in the container
WORKDIR /app

# Install system dependencies
# tesseract-ocr: for OCR functionality
# gcc, libpq-dev: for building psycopg2 (PostgreSQL adapter)
RUN apt-get update && apt-get install -y \
    tesseract-ocr \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy the requirements file into the container at /app
COPY requirements.txt .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Expose port 8001
EXPOSE 8001

# Run with Gunicorn for production
# Workers: 4 (adjust based on CPU cores)
# Bind: 0.0.0.0:8001
# Worker Class: uvicorn.workers.UvicornWorker (for FastAPI/ASGI)
CMD ["gunicorn", "main:app", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8001"]
