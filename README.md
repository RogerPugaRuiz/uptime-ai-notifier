# uptime-ai-notifier

Sistema de monitoreo de disponibilidad (uptime) zero-cost y zero-infra. Utiliza GitHub Actions como vigilante remoto y n8n como motor de automatización e inteligencia artificial.

## 🚀 Inicio Rápido

### Requisitos Previos

- Docker
- Docker Compose

### Entorno de Prueba (Test)

Para ejecutar n8n en modo de prueba con un solo comando:

```bash
docker-compose -f docker-compose.test.yml up -d
```

Accede a n8n en: http://localhost:5678

Para detener el servicio:

```bash
docker-compose -f docker-compose.test.yml down
```

### Entorno de Producción (Prod)

1. Copia el archivo de ejemplo de variables de entorno:

```bash
cp .env.example .env
```

2. Edita el archivo `.env` con tus configuraciones:

```env
N8N_HOST=tu-dominio.com
N8N_PROTOCOL=https
WEBHOOK_URL=https://tu-dominio.com:5678/
TIMEZONE=America/Mexico_City
```

**Nota:** Para usar HTTPS en producción, necesitas configurar un reverse proxy (como Nginx o Traefik) con certificados SSL. Por defecto, el archivo usa HTTP para localhost.

3. Ejecuta n8n en modo producción:

```bash
docker-compose -f docker-compose.prod.yml up -d
```

Accede a n8n en: http://tu-dominio.com:5678 (o https si configuraste SSL)

Para detener el servicio:

```bash
docker-compose -f docker-compose.prod.yml down
```

## 📁 Estructura del Proyecto

```
uptime-ai-notifier/
├── .github/
│   └── workflows/
│       └── uptime-monitor.yml  # GitHub Action para monitoreo
├── docker-compose.test.yml    # Configuración para entorno de prueba
├── docker-compose.prod.yml    # Configuración para entorno de producción
├── .env.example               # Ejemplo de variables de entorno
├── workflows/                 # Directorio para workflows de n8n
│   └── README.md
└── README.md
```

## 🔧 Configuración

### Variables de Entorno (Producción)

| Variable | Descripción | Por Defecto |
|----------|-------------|-------------|
| `N8N_HOST` | Host donde n8n es accesible | `localhost` |
| `N8N_PROTOCOL` | Protocolo (http o https) | `http` |
| `WEBHOOK_URL` | URL de webhooks para n8n | `http://localhost:5678/` |
| `TIMEZONE` | Zona horaria | `UTC` |

### Diferencias entre Test y Prod

**Test:**
- Logs en nivel debug
- Logs a consola
- Datos de ejecución se conservan por 7 días
- Restart: unless-stopped
- Sin healthcheck

**Prod:**
- Logs en nivel info
- Logs a archivo
- Datos de ejecución se conservan por 14 días
- Restart: always
- Healthcheck configurado
- Diagnósticos y personalización deshabilitados

## 📊 Workflows

Los workflows de n8n se pueden almacenar en el directorio `workflows/` para versionarlos. Los archivos en este directorio estarán disponibles en n8n cuando se ejecute.

## 🤖 Integración con GitHub Actions

Este proyecto incluye un workflow de GitHub Actions que monitorea el uptime de tu sitio web y envía alertas a n8n cuando detecta problemas.

### Configuración del Monitor de Uptime

1. **Configura n8n para recibir webhooks:**
   
   a. Accede a tu instancia de n8n (http://localhost:5678)
   
   b. Crea un nuevo workflow con un nodo "Webhook"
   
   c. Configura el webhook con el método POST
   
   d. Copia la URL del webhook (ej: `http://tu-dominio.com:5678/webhook/uptime-alert`)

2. **Agrega el webhook como secret en GitHub:**
   
   a. Ve a tu repositorio en GitHub
   
   b. Settings → Secrets and variables → Actions
   
   c. Click en "New repository secret"
   
   d. Nombre: `WEBHOOK_URL`
   
   e. Valor: La URL del webhook de n8n
   
   f. Click en "Add secret"

3. **Configura el sitio a monitorear:**
   
   Edita el archivo `.github/workflows/uptime-monitor.yml` y cambia la línea:
   ```yaml
   TARGET="https://google.com" # CAMBIA ESTO POR TU WEB REAL
   ```
   Por tu sitio web real.

4. **Prueba el workflow manualmente:**
   
   a. Ve a la pestaña "Actions" en tu repositorio
   
   b. Selecciona "Monitor de Uptime"
   
   c. Click en "Run workflow"
   
   d. Click en "Run workflow" nuevamente

### Funcionamiento del Monitor

- **Ejecución automática**: Cada 15 minutos (configurable en el cron)
- **Ejecución manual**: Disponible con un botón en la pestaña Actions
- **Detección de errores**: Verifica que el sitio responda con código HTTP 200
- **Alertas**: Si el sitio no responde correctamente, envía un JSON a n8n con:
  - `site`: URL del sitio monitoreado
  - `error_code`: Código HTTP recibido
  - `event`: "site_down"

### Ejemplo de Workflow en n8n

Puedes crear un workflow en n8n que:
1. Reciba el webhook cuando el sitio esté caído
2. Procese la información del error
3. Envíe notificaciones por:
   - Email
   - Slack
   - Discord
   - Telegram
   - SMS
4. Use IA para analizar patrones de fallos
5. Genere reportes automáticos

## 🔄 Comandos Útiles

### Ver logs

Test:
```bash
docker-compose -f docker-compose.test.yml logs -f
```

Prod:
```bash
docker-compose -f docker-compose.prod.yml logs -f
```

### Reiniciar servicio

Test:
```bash
docker-compose -f docker-compose.test.yml restart
```

Prod:
```bash
docker-compose -f docker-compose.prod.yml restart
```

### Eliminar volúmenes (¡CUIDADO! Esto borrará todos los datos)

Test:
```bash
docker-compose -f docker-compose.test.yml down -v
```

Prod:
```bash
docker-compose -f docker-compose.prod.yml down -v
```

## 🛡️ Seguridad

Para producción, se recomienda:
- Usar HTTPS (configurar con reverse proxy como Nginx o Traefik)
- Configurar autenticación en n8n
- Usar variables de entorno para credenciales sensibles
- Mantener actualizada la imagen de n8n

## 📝 Licencia

Ver archivo LICENSE para más detalles.
