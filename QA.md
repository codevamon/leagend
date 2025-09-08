# ✅ QA & Calidad — Leagend

## 1. Scripts
- `rake db:seed:demo` → crea usuarios, arenas, duelos.  
- `rake db:roles:setup` → inicializa roles básicos.  

## 2. Tests
- Modelos: validaciones + relaciones.  
- Servicios: Stripe webhooks, reservas de arena.  
- Linters: Rubocop / ESLint (relajados).  

## 3. CI/CD
- GitHub Actions:  
  - Rubocop.  
  - RSpec mínimo.  

## 4. QA Manual
- Flujo end-to-end de duelo (≤3 min).  
- Creación arena verified vs unverified.  
- Pago Stripe test → transición a scheduled.  
- Cierre duelo con marcador → historial.  
