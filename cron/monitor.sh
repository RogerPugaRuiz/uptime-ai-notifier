#!/bin/sh

# No editamos las URLs aquí, las pasamos por el Docker Compose para mayor flexibilidad
echo "--- Iniciando chequeo: $(date) ---"
echo "Objetivo: $TARGET"

# Realizamos la petición
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time 30 \
    --retry 2 \
    "$TARGET")

echo "Resultado: $HTTP_CODE"
    
curl -L -X POST -H "Content-Type: application/json" \
    -d "{\"site\": \"$TARGET\", \"error_code\": \"$HTTP_CODE\", \"event\": \"site_down\", \"timestamp\": \"$(date)\"}" \
    --max-time 10 \
    --fail \
    --silent \
    "$WEBHOOK_URL"
echo "
--- Chequeo finalizado ---
"