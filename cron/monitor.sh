#!/bin/sh

# Variables pasadas desde Docker Compose:
# - SERVICE_NAME: Nombre legible del servicio
# - TARGET: URL a monitorear
# - WEBHOOK_URL: Endpoint de n8n

echo "--- Iniciando chequeo: $(date) ---"
echo "Servicio: ${SERVICE_NAME:-Desconocido}"
echo "Objetivo: $TARGET"

# Realizamos la petición
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time 30 \
    --retry 2 \
    "$TARGET")

echo "Resultado: $HTTP_CODE"

# Enviamos al webhook con información del servicio
curl -L -X POST -H "Content-Type: application/json" \
    -d "{
      \"service\": \"${SERVICE_NAME:-$TARGET}\",
      \"site\": \"$TARGET\",
      \"error_code\": \"$HTTP_CODE\",
      \"event\": \"health_check\",
      \"timestamp\": \"$(date -Iseconds)\"
    }" \
    --max-time 10 \
    --fail \
    --silent \
    "$WEBHOOK_URL"

echo "
--- Chequeo finalizado ---"