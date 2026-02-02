# uptime-ai-notifier

Sistema de monitoreo de disponibilidad (uptime) zero-cost y zero-infra. Utiliza GitHub Actions como vigilante remoto y n8n como motor de automatización e inteligencia artificial.

## 🎯 ¿Qué hace este proyecto?

Este proyecto ofrece **dos métodos de monitoreo** que pueden usarse de forma independiente o combinada:

| Método | Infraestructura | Costo | Ideal para |
|--------|-----------------|-------|------------|
| **GitHub Actions** | Ninguna (GitHub la provee) | Gratis (2000 min/mes) | Monitoreo externo sin servidor propio |
| **Docker + Cron** | Tu servidor con Docker | Costo del servidor | Monitoreo interno con control total |

---

## 🏗️ Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────────────┐
│                        UPTIME-AI-NOTIFIER                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────┐         ┌─────────────────────────────┐   │
│  │   OPCIÓN A:         │         │   OPCIÓN B:                 │   │
│  │   GitHub Actions    │         │   Docker Compose            │   │
│  │   (Zero Infra)      │         │   (Self-hosted)             │   │
│  │                     │         │                             │   │
│  │  ┌───────────────┐  │         │  ┌────────────────────────┐ │   │
│  │  │ uptime-       │  │         │  │ monitor (Alpine+Cron)  │ │   │
│  │  │ monitor.yml   │  │         │  │ Ejecuta cada minuto    │ │   │
│  │  │ Cada 15 min   │  │         │  └──────────┬─────────────┘ │   │
│  │  └───────┬───────┘  │         │             │               │   │
│  │          │          │         │             │               │   │
│  └──────────┼──────────┘         └─────────────┼───────────────┘   │
│             │                                  │                   │
│             │         ┌───────────────┐        │                   │
│             └────────►│    WEBHOOK    │◄───────┘                   │
│                       │   (n8n)       │                            │
│                       └───────┬───────┘                            │
│                               │                                    │
│                               ▼                                    │
│                   ┌───────────────────────┐                        │
│                   │   n8n Workflow        │                        │
│                   │   - Procesa alertas   │                        │
│                   │   - Analiza con IA    │                        │
│                   │   - Envía notificac.  │                        │
│                   └───────────────────────┘                        │
│                               │                                    │
│              ┌────────────────┼────────────────┐                   │
│              ▼                ▼                ▼                   │
│         ┌────────┐      ┌──────────┐     ┌──────────┐              │
│         │ Email  │      │ Telegram │     │  Slack   │              │
│         └────────┘      └──────────┘     └──────────┘              │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📁 Estructura del Proyecto

```
uptime-ai-notifier/
├── 📂 .github/
│   ├── 📂 workflows/
│   │   └── 📄 uptime-monitor.yml    # [OPCIÓN A] GitHub Action para monitoreo
│   └── 📄 copilot-instructions.md   # Instrucciones para GitHub Copilot
│
├── 📂 cron/
│   └── 📄 monitor.sh                # [OPCIÓN B] Script de monitoreo local
│
├── 📂 workflows/
│   ├── 📄 README.md                 # Documentación de workflows n8n
│   ├── 📄 v1.0.0.json               # Workflow n8n v1.0.0 (básico)
│   └── 📄 v2.0.0.json               # Workflow n8n v2.0.0 (con IA - Gemini)
│
├── 📄 docker-compose.yml            # Configuración Docker principal
├── 📄 .env.example                  # Ejemplo de variables de entorno
├── 📄 monitor_status.txt            # Estado del último chequeo (autogenerado)
├── 📄 LICENSE
└── 📄 README.md
```

---

## 🧩 Componentes del Sistema

### 1️⃣ n8n (Motor de Automatización)

**Archivo:** `docker-compose.yml` → servicio `n8n`

n8n es el cerebro del sistema. Recibe las alertas via webhook y puede:
- Procesar la información del error
- Usar IA para analizar patrones
- Enviar notificaciones multicanal (Email, Telegram, Slack, Discord, SMS)
- Generar reportes automáticos

**Puerto:** `5678`
**Acceso:** http://localhost:5678

### 2️⃣ Monitor Local (Cron + Alpine)

**Archivos:** 
- `docker-compose.yml` → servicio `monitor`
- `cron/monitor.sh`

Contenedor ligero Alpine Linux que ejecuta un script de monitoreo cada minuto usando cron.

**Características:**
- Frecuencia: Cada minuto (configurable)
- Timeout: 30 segundos
- Reintentos: 2 automáticos
- Envía SIEMPRE al webhook (para logging)

### 3️⃣ GitHub Actions Monitor

**Archivo:** `.github/workflows/uptime-monitor.yml`

Monitoreo externo que corre en la infraestructura de GitHub (gratis hasta 2000 min/mes).

**Características:**
- Frecuencia: Cada 15 minutos (configurable)
- Ejecución manual disponible
- Timeout: 30 segundos
- Reintentos: 2 automáticos
- Envía SIEMPRE al webhook (para logging completo)

### 4️⃣ Fix-Permissions (Helper)

**Archivo:** `docker-compose.yml` → servicio `fix-permissions`

Servicio auxiliar que arregla los permisos de los volúmenes de n8n antes de iniciar. Se ejecuta una vez y se apaga.

---

## 🚀 Guía de Pruebas

### Requisitos Previos

- Docker y Docker Compose instalados
- (Opcional) Cuenta de GitHub para usar GitHub Actions

---

### 🧪 Prueba 1: Levantar n8n + Monitor Local

Esta prueba levanta todo el stack Docker localmente.

**Paso 1: Iniciar los servicios**

```bash
docker-compose up -d
```

**Paso 2: Verificar que los servicios están corriendo**

```bash
docker-compose ps
```

Deberías ver:
- `uptime-ai-notifier-n8n` → Running
- `uptime-monitor-script` → Running
- `n8n-fix-permissions` → Exited (0) ✅

**Paso 3: Acceder a n8n**

Abre http://localhost:5678 en tu navegador.

**Paso 4: Crear un workflow webhook en n8n**

1. Click en "Add workflow"
2. Añade un nodo "Webhook"
3. Configura:
   - HTTP Method: POST
   - Path: `monitor-alert`
4. Añade un nodo "Set" para ver los datos
5. Activa el workflow
6. La URL del webhook será: `http://n8n:5678/webhook/monitor-alert`

**Paso 5: Ver los logs del monitor**

```bash
docker logs -f uptime-monitor-script
```

Verás los chequeos cada minuto:
```
--- Iniciando chequeo: Fri Jan 30 10:00:00 UTC 2026 ---
Objetivo: https://guiders.es/docs
Resultado: 200
--- Chequeo finalizado ---
```

**Paso 6: Detener los servicios**

```bash
docker-compose down
```

---

### 🧪 Prueba 2: Simular una caída del sitio

**Paso 1:** Modifica temporalmente el `docker-compose.yml`:

```yaml
environment:
  - TARGET=https://sitio-que-no-existe-12345.com  # URL inválida
```

**Paso 2:** Reinicia el monitor:

```bash
docker-compose restart monitor
```

**Paso 3:** Observa los logs:

```bash
docker logs -f uptime-monitor-script
```

Verás un error como:
```
Resultado: 000  # No se pudo conectar
```

**Paso 4:** Revisa en n8n que llegó la alerta con el código de error.

---

### 🧪 Prueba 3: GitHub Actions (Zero Infra)

Esta prueba usa la infraestructura de GitHub, no necesitas Docker.

**Paso 1: Configura los secrets en GitHub**

1. Ve a tu repositorio → Settings → Secrets and variables → Actions
2. Añade estos secrets:

| Secret | Valor | Requerido |
|--------|-------|-----------|
| `WEBHOOK_URL` | URL del webhook de n8n | ✅ Sí |
| `TARGET_URL` | URL a monitorear | ❌ No (default: google.com) |

**Paso 2: Habilita el cron schedule** (opcional)

Edita `.github/workflows/uptime-monitor.yml` y descomenta:

```yaml
on:
  schedule:
    - cron: '*/15 * * * *'  # Cada 15 minutos
  workflow_dispatch:
```

**Paso 3: Ejecuta manualmente**

1. Ve a la pestaña "Actions" en GitHub
2. Selecciona "Monitor de Uptime"
3. Click en "Run workflow"
4. Click en "Run workflow" nuevamente

**Paso 4: Revisa el resultado**

- ✅ Verde: El sitio está online
- ❌ Rojo: El sitio está caído (y envió alerta a n8n)

---

### 🧪 Prueba 4: Probar el script de monitoreo manualmente

```bash
# Dentro del contenedor
docker exec -it uptime-monitor-script sh

# Ejecutar el script manualmente
TARGET=https://google.com WEBHOOK_URL=http://n8n:5678/webhook/monitor-alert sh /etc/monitor.sh
```

---

### 🧪 Prueba 5: Probar solo n8n (sin monitor)

Si solo quieres probar n8n:

```bash
docker-compose up -d n8n
```

Esto iniciará solo n8n y su dependencia fix-permissions.

---

## ⚙️ Configuración

### Variables de Entorno

Crea un archivo `.env` basándote en `.env.example`:

```bash
cp .env.example .env
```

| Variable | Descripción | Por Defecto |
|----------|-------------|-------------|
| `TIMEZONE` | Zona horaria | `Europe/Madrid` |
| `LOG_LEVEL` | Nivel de log (debug/info/warn/error) | `info` |

### Configuración del Monitor Local

En `docker-compose.yml`, servicio `monitor`:

| Variable | Descripción | Valor actual |
|----------|-------------|--------------|
| `TARGET` | URL a monitorear | `https://guiders.es/docs` |
| `WEBHOOK_URL` | Webhook de n8n | `http://n8n:5678/webhook/monitor-alert` |

### Configuración de GitHub Actions

En `.github/workflows/uptime-monitor.yml`:

| Parámetro | Descripción | Valor actual |
|-----------|-------------|--------------|
| `cron` | Frecuencia de ejecución | `*/15 * * * *` (15 min) |
| `TARGET_URL` | Secret con URL a monitorear | (configurable) |
| `WEBHOOK_URL` | Secret con webhook de n8n | (requerido) |

---

## 🔄 Comandos Útiles

### Gestión de Docker

```bash
# Iniciar todos los servicios
docker-compose up -d

# Ver estado de los servicios
docker-compose ps

# Ver logs en tiempo real
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f n8n
docker-compose logs -f monitor

# Reiniciar un servicio
docker-compose restart monitor

# Detener todos los servicios
docker-compose down

# Detener y eliminar volúmenes (⚠️ BORRA DATOS)
docker-compose down -v
```

### Depuración

```bash
# Entrar al contenedor de n8n
docker exec -it uptime-ai-notifier-n8n sh

# Entrar al contenedor del monitor
docker exec -it uptime-monitor-script sh

# Ver el estado del último chequeo
cat monitor_status.txt
```

---

## 🛡️ Seguridad

Para producción, se recomienda:

- ✅ Usar HTTPS (configurar con reverse proxy como Nginx o Traefik)
- ✅ Configurar autenticación en n8n
- ✅ Usar variables de entorno para credenciales sensibles
- ✅ Mantener actualizada la imagen de n8n
- ✅ No exponer el puerto 5678 directamente a internet sin protección

---

## 🤝 Contribuciones

¡Las contribuciones son bienvenidas! Por favor:

1. Haz fork del repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Añade nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

---

## 📝 Licencia

Ver archivo [LICENSE](LICENSE) para más detalles.
