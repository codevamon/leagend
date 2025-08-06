# 🧪 TEST CASES CRÍTICOS - FLUJO DE DUELOS

## 🎯 **OBJETIVO**
Validar que el flujo de duelos funcione correctamente en todos los escenarios críticos para MVP.

## 📋 **TEST CASES PRIORITARIOS**

### **1. CREACIÓN DE DUELOS**
- [ ] **TC-001**: Usuario crea duelo con equipo existente
  - Usuario logueado con club/clan
  - Selecciona equipo válido
  - Configura fecha/hora futura
  - Selecciona tipo de duelo
  - **Resultado esperado**: Duelo creado, status 'open', redirige a show

- [ ] **TC-002**: Usuario crea duelo sin arena
  - No selecciona arena
  - **Resultado esperado**: Duelo creado, disponible para desafíos

- [ ] **TC-003**: Usuario crea duelo con arena
  - Selecciona arena válida
  - **Resultado esperado**: Duelo creado, arena asignada

- [ ] **TC-004**: Validaciones de fecha/hora
  - Fecha pasada → Error
  - Hora inválida → Error
  - Duración > 6 horas → Error

### **2. DESAFÍOS (CHALLENGES)**
- [ ] **TC-005**: Enviar desafío exitoso
  - Duelo A (con arena) desafía a Duelo B (sin arena)
  - Misma fecha/hora (±24h)
  - **Resultado esperado**: Challenge creado, notificación enviada

- [ ] **TC-006**: Aceptar desafío
  - Admin del duelo desafiado acepta
  - **Resultado esperado**: Duelos fusionados, away_team asignado

- [ ] **TC-007**: Rechazar desafío
  - Admin rechaza desafío
  - **Resultado esperado**: Challenge marcado como rejected, duelos independientes

- [ ] **TC-008**: Desafío duplicado
  - Intentar enviar mismo desafío 2 veces
  - **Resultado esperado**: Error, no crear duplicado

### **3. FUSIÓN DE DUELOS**
- [ ] **TC-009**: Fusión exitosa
  - Verificar que callups se copien correctamente
  - Verificar que lineups se copien correctamente
  - Verificar que no haya duplicados
  - **Resultado esperado**: Un solo duelo con ambos equipos

- [ ] **TC-010**: Validaciones de fusión
  - Duelo ya tiene away_team → Error
  - Duelo terminado → Error
  - Fechas diferentes → Error

### **4. GESTIÓN DE JUGADORES**
- [ ] **TC-011**: Convocar jugadores
  - Admin convoca jugadores del equipo
  - **Resultado esperado**: Callups creados, notificaciones enviadas

- [ ] **TC-012**: Aceptar/rechazar convocatoria
  - Jugador acepta convocatoria
  - Jugador rechaza convocatoria
  - **Resultado esperado**: Status actualizado, lineup creado/eliminado

### **5. INICIO DE DUELO**
- [ ] **TC-013**: Iniciar duelo válido
  - Suficientes jugadores confirmados
  - Fecha/hora correcta
  - **Resultado esperado**: Status 'ongoing'

- [ ] **TC-014**: Iniciar duelo inválido
  - Pocos jugadores → Error
  - Fecha futura → Error
  - Sin rival → Error

## 🔧 **EDGE CASES CRÍTICOS**

### **1. CONCURRENCIA**
- [ ] **EC-001**: Dos usuarios desafían mismo duelo simultáneamente
- [ ] **EC-002**: Admin acepta/rechaza mientras otro usuario envía desafío

### **2. DATOS INCONSISTENTES**
- [ ] **EC-003**: Duelo con callups pero sin lineups
- [ ] **EC-004**: Duelo fusionado con datos duplicados

### **3. PERMISOS**
- [ ] **EC-005**: Usuario sin permisos intenta gestionar duelo
- [ ] **EC-006**: Usuario intenta desafiar su propio duelo

## 🚨 **BUGS CONOCIDOS A VERIFICAR**

### **1. DuelMerger**
- [ ] Verificar que no duplique callups/lineups
- [ ] Verificar transacciones en caso de error
- [ ] Verificar notificaciones post-fusión

### **2. Flujo de Creación**
- [ ] Verificar que session[:duel_data] se limpie correctamente
- [ ] Verificar redirecciones en flujo legacy
- [ ] Verificar validaciones de equipos

### **3. Challenges**
- [ ] Verificar que no se puedan crear challenges circulares
- [ ] Verificar que challenges se limpien al fusionar
- [ ] Verificar notificaciones de challenges

## 📊 **MÉTRICAS DE ÉXITO**

### **Funcionalidad**
- ✅ Todos los test cases pasan
- ✅ No hay errores 500 en producción
- ✅ Flujo completo funciona en < 2 minutos

### **UX**
- ✅ Creación de duelo en < 30 segundos
- ✅ Desafíos se procesan en < 5 segundos
- ✅ Fusión de duelos en < 10 segundos

### **Datos**
- ✅ No hay callups/lineups duplicados
- ✅ Todos los duelos tienen status válido
- ✅ Challenges tienen referencias válidas

## 🎯 **PRIORIDADES PARA MVP**

### **CRÍTICO (Hacer ahora)**
1. TC-001, TC-002: Creación básica
2. TC-005, TC-006: Desafíos y fusión
3. EC-001, EC-003: Edge cases críticos

### **IMPORTANTE (Hacer después)**
1. TC-011, TC-012: Gestión de jugadores
2. TC-013, TC-014: Inicio de duelo
3. EC-005, EC-006: Permisos

### **NICE-TO-HAVE (Post-MVP)**
1. Notificaciones avanzadas
2. Estadísticas de duelos
3. Historial de challenges

## 🔍 **COMANDOS DE TESTING**

```bash
# Test manual rápido
rails console
# Crear duelo de prueba
duel = Duel.create!(home_team: Team.first, starts_at: 1.hour.from_now, duel_type: 'friendly')
# Verificar estado
duel.status # => 'open'
duel.can_be_challenged? # => true/false

# Test de fusión
challenge = Challenge.create!(challenger_duel: duel1, challengee_duel: duel2)
DuelMerger.call(challenge)
# Verificar resultado
duel1.reload.away_team # => debería ser duel2.home_team
```

## 📝 **NOTAS DE IMPLEMENTACIÓN**

- **DuelMerger**: Usar transacciones para consistencia
- **Challenges**: Validar antes de crear
- **Callups**: Evitar duplicados con exists?
- **Notificaciones**: Async para mejor performance 