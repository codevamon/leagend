# 🚀 Deploy — Leagend

## 1. Infraestructura mínima
- Rails 8.1 en Render/Fly/Heroku-like.  
- DB: Postgres.  
- Storage: S3-compatible.  
- Seeds de demo para staging.  

## 2. Pasos Básicos
1. `rails db:setup` + `rails db:seed`.  
2. Configurar `credentials.yml.enc` con:  
   - Mapbox token.  
   - Stripe (modo test).  
   - Google OAuth.  
3. `rails assets:clobber && rails assets:precompile`.  

## 3. CI/CD
- GitHub Actions con:  
  - `rubocop`  
  - `rspec` básico  
- Deploy automático a staging tras pasar tests.  

## 4. Notas
- Mantener staging para demos públicas.  
- Usar fixtures de duelos, arenas y usuarios.  
- Documentar credenciales de prueba (Stripe, Google).  
