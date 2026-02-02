# 📂 Workflows n8n

Este directorio contiene los workflows de n8n preconfigurados para el sistema de monitoreo.

## 📋 Versiones Disponibles

| Versión | Archivo | Descripción |
|---------|---------|-------------|
| **v1.0.0** | `v1.0.0.json` | Workflow básico de alertas |
| **v2.0.0** | `v2.0.0.json` | Workflow con IA (Google Gemini) para generar mensajes inteligentes |

---

## 🚀 v1.0.0 - Workflow Básico

Workflow sencillo que recibe alertas del monitor y las procesa de forma básica.

**Características:**
- Webhook receptor (`/webhook/monitor-alert`)
- Procesamiento básico de datos
- Notificación directa

---

## 🤖 v2.0.0 - Workflow con IA

Workflow avanzado que utiliza **Google Gemini** para generar mensajes de alerta inteligentes.

**Características:**
- Webhook receptor (`/webhook/monitor-alert`)
- Integración con Google Gemini 2.0 Flash
- Generación automática de mensajes formateados para WhatsApp
- Análisis contextual del error

**Requisitos:**
- Credenciales de API de Google Gemini configuradas en n8n

---

## 📥 Cómo Importar

1. Abre n8n en http://localhost:5678
2. Ve a **Workflows** → **Add workflow**
3. Click en los tres puntos (**...**) → **Import from file**
4. Selecciona el archivo JSON de la versión deseada
5. Configura las credenciales necesarias (si aplica)
6. **Activa** el workflow

---

## 🔧 Personalización

Puedes exportar tus workflows personalizados desde n8n y guardarlos aquí para control de versiones:

1. En n8n, abre el workflow
2. Click en los tres puntos (**...**) → **Download**
3. Guarda el archivo en este directorio con un nombre descriptivo
