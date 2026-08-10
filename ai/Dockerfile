FROM python:3.11-slim

WORKDIR /app

# curl only, for poking at the service from inside the container while
# debugging. No compiler is installed: every dependency below ships a prebuilt
# wheel, so build-essential would add roughly 350MB and compile nothing.
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
