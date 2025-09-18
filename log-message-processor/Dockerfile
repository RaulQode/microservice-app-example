FROM python:3.6-alpine

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache gcc musl-dev

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY . .

# Run the application
CMD ["python", "main.py"] 