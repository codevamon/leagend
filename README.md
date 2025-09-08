# 🏟️ Leagend

Plataforma web y móvil para organizar duelos de fútbol callejero en ≤3 min.  
Backend en **Rails 8.1**, frontend web con **Hotwire/Stimulus**, y app móvil con **Ionic + Capacitor**.

---

## 🚀 Cómo empezar

### Requisitos
- Ruby 3.2.6  
- Rails 8.1.x  
- Postgres 15+  
- Node.js 20+ (para frontend móvil con Ionic)  

### Instalación
```bash
# Clonar repo
git clone git@github.com:tu-org/leagend.git
cd leagend

# Instalar dependencias
bundle install
rails db:setup

# Variables de entorno
EDITOR="nano" bin/rails credentials:edit
# Añadir claves: Mapbox, Stripe, Google OAuth

# Iniciar servidor
bin/dev

```

---

### Seeds

```bash

rails db:seed

```

## 📂 Documentación

### SBSMI.md
 → Sistema de Búsqueda Sincronizada con Mapas Interactivos.

### PROMPTS.md
 → Guía de prompts quirúrgicos para Cursor.

### DEPLOY.md
 → Instrucciones de despliegue.

### ROADMAP.md
 → Plan de sprints y definición de hecho.

### UX.md
 → Principios de UX y flujo del wizard.

### UI.md
 → Documentación de UI, responsive y accesibilidad.

### ROLES.md
 → Sistema de roles (Membership, Admin, Owner, Referee).

### SEEDS.md
 → Seeds recomendados para demo/staging.

### COMPONENTS.md
 → Stimulus controllers y partials.

### PAYMENTS.md
 → Diseño del sistema de pagos con Stripe.

### MODELS.md
 → Modelos principales y de soporte.

### API.md
 → Endpoints RESTful web y API v1.

### QA.md
 → Estrategia de QA, CI/CD y pruebas.

### MOBILE.md
 → App móvil con Ionic + Capacitor.

### POSTMVP.md
 → Funcionalidades planificadas después del MVP.


##  ✅ Estado Actual

- Autenticación con Devise + Google OAuth.

- CRUD de arenas con verificación.

- Wizard de duelos (pasos 1–3) con mapa interactivo.

- Seeds básicos listos para demo.

- Integración inicial de Stripe (test mode pendiente).

## 📜 Licencia


Este proyecto es de **github.com/codevamon**.

Este proyecto se publica bajo licencia **MIT**.  
Desarrollado con ❤️ para la comunidad, con el objetivo de mostrar buenas prácticas en Rails + Ionic + Capacitor.  

Puedes usar el código con fines personales, educativos o de aprendizaje.  
Para uso **comercial** se requiere autorización expresa del autor.