FROM python:3.11-slim

WORKDIR /app

# Evita que Python retenga los print() en un buffer interno —
# sin esto, los logs pueden no aparecer (o aparecer con retraso) en Docker
ENV PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# El comando real se define en docker-compose.yml (mqtt_bridge.py o mqtt_sender.py)
CMD ["python", "mqtt_bridge.py"]