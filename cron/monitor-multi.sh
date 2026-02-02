#!/bin/sh
# ═══════════════════════════════════════════════════════════════
# Monitor Multi-Servicio
# Lee servicios desde /etc/services.json y los chequea
# ═══════════════════════════════════════════════════════════════

CONFIG_FILE="/etc/services.json"
WEBHOOK_URL="${WEBHOOK_URL:-http://n8n:5678/webhook/monitor-alert}"

check_service() {
    SERVICE_NAME="$1"
    SERVICE_URL="$2"
    
    echo "[$(date '+%H:%M:%S')] Chequeando: $SERVICE_NAME"
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        --max-time 30 \
        --retry 2 \
        "$SERVICE_URL")
    
    echo "[$(date '+%H:%M:%S')] $SERVICE_NAME → $HTTP_CODE"
    
    # Construir JSON manualmente para evitar problemas de escape
    JSON_PAYLOAD="{\"service\":\"${SERVICE_NAME}\",\"site\":\"${SERVICE_URL}\",\"error_code\":\"${HTTP_CODE}\",\"event\":\"health_check\",\"timestamp\":\"$(date -Iseconds)\"}"
    
    echo "[DEBUG] Enviando: $JSON_PAYLOAD"
    
    # Enviar resultado al webhook
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$JSON_PAYLOAD" \
        --max-time 10 \
        "$WEBHOOK_URL"
    
    echo ""
}

run_monitors() {
    echo ""
    echo "═══════════════════════════════════════════════════"
    echo "  Monitor Multi-Servicio - $(date)"
    echo "═══════════════════════════════════════════════════"
    
    # Leer JSON y procesar cada servicio secuencialmente
    COUNT=$(jq length "$CONFIG_FILE")
    
    i=0
    while [ $i -lt $COUNT ]; do
        SERVICE_NAME=$(jq -r ".[$i].name" "$CONFIG_FILE")
        SERVICE_URL=$(jq -r ".[$i].url" "$CONFIG_FILE")
        
        check_service "$SERVICE_NAME" "$SERVICE_URL"
        
        i=$((i + 1))
    done
    
    echo "═══════════════════════════════════════════════════"
    echo ""
}

# Ejecutar una vez al inicio
run_monitors

# Loop infinito con intervalos
while true; do
    sleep "${CHECK_INTERVAL:-60}"
    run_monitors
done
