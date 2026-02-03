# Copilot Instructions - Uptime AI Notifier

## Arquitectura del Sistema

Sistema de monitoreo multi-servicio zero-cost con DOS métodos independientes:

### Método A: GitHub Actions (Zero-infra)
- Ejecuta cada 15 minutos desde GitHub (2000 min/mes gratis)
- Ver [.github/workflows/uptime-monitor.yml](.github/workflows/uptime-monitor.yml)
- Envía siempre al webhook (incluso si servicio está up) para logging completo

### Método B: Docker Local (Self-hosted)
- Monitor Alpine Linux con cron cada minuto configurable
- Lee múltiples servicios desde [config/services.json](../config/services.json)
- Script principal: [cron/monitor-multi.sh](../cron/monitor-multi.sh)
- Cada servicio puede tener `interval` diferente

**Flujo común**: Monitor → curl al sitio → POST webhook n8n → n8n procesa con IA → notificaciones multicanal

## Estructura de Componentes

### 1. n8n (Motor de Automatización)
- Corre en [docker-compose.yml](../docker-compose.yml), puerto 5678
- Webhook endpoint: `http://localhost:5678/webhook/monitor-alert`
- **CRÍTICO**: `EXECUTIONS_CONCURRENCY=1` para evitar race conditions en persistencia
- Volumen persistente: `n8n_data` para workflows y credentials
- Archivo compartido: `monitor_states.json` montado en `/home/node/.n8n-files/` (acceso filesystem desde workflows)

### 2. Monitor Multi-Servicio (Alpine)
- Contenedor único que lee array JSON de servicios
- Timeout: 30s por servicio, 2 reintentos automáticos
- Envía JSON estructurado: `{"service": "nombre", "site": "url", "error_code": "200", "event": "health_check", "timestamp": "ISO8601"}`
- **No** mantiene estado internamente - usa archivo externo si es necesario

### 3. Fix-Permissions (Init Container)
- Ejecuta una sola vez al inicio para arreglar permisos volúmenes n8n
- Se debe completar exitosamente antes de iniciar n8n (`depends_on.condition: service_completed_successfully`)
- Solución para problemas de permisos 1000:1000 en volumes

## Configuración de Servicios

Editar [config/services.json](../config/services.json) para agregar/modificar servicios monitoreados:

```json
{
  "name": "Nombre del Servicio",
  "url": "https://example.com/health",
  "interval": 60
}
```

**Convención**: Usar URLs de health check dedicadas cuando sea posible, no páginas HTML completas.

## Workflows n8n Versionados

Guardar en [workflows/](../workflows/) para control de versiones:
- **v1.0.0**: Alertas básicas single-site
- **v2.0.0**: Con Google Gemini para mensajes inteligentes
- **v3.0.0**: Multi-servicio con procesamiento avanzado
- **v3.1.0**: Última versión estable

**Importar/exportar**: n8n UI → Menu (⋯) → Import/Export → guardar con nombre vX.X.X.json

### Workflow Actual: v3.1.0 (Unified)

Workflow unificado que procesa alertas de **dos fuentes diferentes**:

**Flujo de nodos**:
```
Webhook → Read States JSON → Normalize & Process → If Status Changed → Send Alert to Telegram
                                      ↓
                           Prepare JSON for Save → Convert to File → Save States JSON
```

**Fuentes soportadas**:
| Fuente | Payload | Detección |
|--------|---------|-----------|
| **Monitor Interno** | `{service, site, error_code, timestamp}` | `service` es string |
| **StatusGator** | `{service: {name, current_status}, incident: {...}}` | `service` es objeto |

**Lógica de normalización** (nodo `Normalize & Process`):
- StatusGator estados: `operational`, `minor`, `major`, `critical`, `maintenance`
- Monitor interno: códigos HTTP (`200`, `4xx`, `5xx`, `000`)
- Todos se mapean a tipos: `up`, `down`, `degraded`, `maintenance`

**Detección de cambios**:
- Compara `status_code` actual vs anterior en `monitor_states.json`
- **StatusGator**: Siempre alerta (ya viene pre-filtrado)
- **Monitor interno**: Solo alerta si hay cambio de estado

**Clasificación de alertas**:
- `is_recovery`: Transición a `up` desde otro estado
- `is_down`: Transición a `down`
- `is_degraded`: Transición a `degraded`
- `is_maintenance`: Transición a `maintenance`

**Historial**: Guarda últimos 50 cambios por servicio en `monitor_states.json`

**Notificación**: Telegram con emojis según tipo (🟢 recovery, 🚨 down, 🟡 degraded, 🔧 maintenance)

Configurar en [docker-compose.yml](../docker-compose.yml):
- `WEBHOOK_URL`: Endpoint del webhook n8n (default: `http://n8n:5678/webhook/monitor-alert`)
- `CHECK_INTERVAL`: Segundos entre chequeos del monitor Docker (default: 60)
- `TIMEZONE`: Zona horaria (default: Europe/Madrid)
- `EXECUTIONS_DATA_MAX_AGE`: Horas para mantener ejecuciones (default: 336 = 14 días)

Para GitHub Actions, configurar secrets:
- `WEBHOOK_URL` (requerido): URL pública del webhook n8n
- `TARGET_URL` (opcional): Default es https://google.com

## Comandos de Desarrollo

**Inicio del stack completo**:
```bash
docker-compose up -d
```

**Ver logs en tiempo real**:
```bash
docker-compose logs -f              # todos los servicios
docker-compose logs -f n8n          # solo n8n
docker-compose logs -f monitor      # solo monitor
```

**Reiniciar tras cambios en scripts**:
```bash
docker-compose restart monitor      # reinicia solo el monitor
docker-compose restart              # reinicia todo
```

**Verificar estado**:
```bash
docker-compose ps
```

**Limpiar todo (DESTRUYE DATOS)**:
```bash
docker-compose down -v
```

## Debugging Workflows

1. **Verificar webhook accesible**: 
   ```bash
   curl -X POST http://localhost:5678/webhook/monitor-alert \
     -H "Content-Type: application/json" \
     -d '{"service":"Test","site":"https://test.com","error_code":"200","event":"health_check","timestamp":"2026-02-03T10:00:00Z"}'
   ```

2. **Ver logs monitor**: `docker-compose logs -f monitor` - buscar líneas `[DEBUG] Enviando:`

3. **Revisar ejecuciones en n8n**: http://localhost:5678 → Executions (panel izquierdo)

4. **Verificar permisos volumen**: Si n8n no arranca, revisar logs de `fix-permissions`

## Persistencia y Estados

- `monitor_states.json`: Archivo autogenerado por workflows n8n para tracking de estados (up/down) entre ejecuciones
- Montado en contenedor n8n: `/home/node/.n8n-files/monitor_states.json`
- Estructura típica: `{"serviceName": {"status": "up|down", "lastCheck": "timestamp", "downSince": "timestamp"}}`
- **Importante**: n8n necesita `N8N_BLOCK_FS_WRITE_ACCESS=false` para escribir en este archivo

## Patrones y Decisiones de Arquitectura

- **Un monitor, múltiples servicios**: Preferir agregar servicios en JSON sobre crear múltiples contenedores
- **Enviar siempre**: Webhooks se envían en todos los casos (200, 4xx, 5xx) para logging centralizado en n8n
- **Concurrencia=1**: Evita problemas de escritura concurrente en archivos JSON compartidos
- **Init containers**: Patrón para setup de permisos antes del servicio principal
- **Network bridge**: Red Docker interna `uptime-ai` para comunicación n8n ↔ monitor sin exponer puertos

## Seguridad

- n8n en localhost:5678 - **NO exponer sin autenticación**
- Configurar credenciales en n8n UI al primer inicio
- Para producción con webhook público: usar reverse proxy (Nginx/Traefik) con HTTPS
- Nunca versionar credenciales de API en workflows JSON - usar sistema de credentials de n8n
