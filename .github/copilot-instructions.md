# Copilot Instructions - Uptime AI Notifier

## Arquitectura del Sistema

Sistema de monitoreo zero-cost que combina:
- **GitHub Actions** como vigilante remoto (ejecuta verificaciones cada 15 min)
- **n8n** (containerizado) como motor de automatización e IA
- **Comunicación**: GitHub Actions → n8n vía webhook POST

Flujo de datos: GitHub Actions curl al sitio → si falla → POST a webhook n8n → n8n procesa y envía notificaciones

## Entornos

Dos configuraciones Docker Compose separadas:
- **Test** ([docker-compose.test.yml](docker-compose.test.yml)): logs debug, consola, 7 días de datos, puerto 5678
- **Prod** ([docker-compose.prod.yml](docker-compose.prod.yml)): logs info, archivo, 14 días de datos, healthcheck, variables desde `.env`

Comando específico: `docker-compose -f docker-compose.{test|prod}.yml {up|down|logs|restart}`

## Variables de Entorno

Producción usa archivo `.env` (crear desde [.env.example](.env.example)):
- `N8N_HOST`: host accesible (default: localhost)
- `N8N_PROTOCOL`: http o https (requiere reverse proxy para https)
- `WEBHOOK_URL`: URL completa del webhook n8n
- `TIMEZONE`: zona horaria para logs/ejecuciones

## GitHub Actions Configuration

[.github/workflows/uptime-monitor.yml](.github/workflows/uptime-monitor.yml) requiere secrets en GitHub:
- `WEBHOOK_URL` (requerido): URL del webhook de n8n
- `TARGET_URL` (opcional): sitio a monitorear (default: https://google.com)

Payload enviado a n8n en falla:
```json
{"site": "URL", "error_code": "HTTP_CODE", "event": "site_down"}
```

## Workflows n8n

- Guardar en [workflows/](workflows/) para versionarlos
- Montado read-only en contenedor: `./workflows:/home/node/.n8n/workflows:ro`
- Formatos: JSON exportados desde n8n UI

## Convenciones Específicas

- **Puertos fijos**: n8n siempre en 5678 (ambos entornos)
- **Network isolation**: cada entorno usa su propia red Docker bridge
- **Volumenes nombrados**: `n8n_test_data` y `n8n_prod_data` para persistencia
- **Logs producción**: montados en `./logs` para acceso externo
- **Healthcheck**: solo en prod, verifica endpoint raíz cada 30s

## Debugging Workflows

Flujo de troubleshooting:
1. Verificar logs: `docker-compose -f docker-compose.{env}.yml logs -f`
2. Confirmar webhook accesible desde GitHub (usar curl manual)
3. Revisar ejecuciones en n8n UI (http://localhost:5678)
4. En test: nivel debug activo por defecto

## Comandos de Desarrollo

No usar `docker` directamente - siempre especificar archivo compose:
```bash
# Iniciar
docker-compose -f docker-compose.test.yml up -d

# Ver logs en tiempo real
docker-compose -f docker-compose.test.yml logs -f

# Reiniciar tras cambios config
docker-compose -f docker-compose.test.yml restart

# Limpiar todo (DESTRUYE DATOS)
docker-compose -f docker-compose.test.yml down -v
```

## Seguridad en Producción

- HTTPS requiere reverse proxy externo (Nginx/Traefik) - n8n no maneja SSL directamente
- Autenticación n8n: configurar en UI primera ejecución
- Credentials sensibles: solo en variables entorno, nunca en workflows versionados
- Actualizar imagen: `docker-compose pull` antes de `up`
