# ⚡ Prompts Quirúrgicos — Leagend

## 1. Regla General
Todo **prompt quirúrgico para Cursor** debe seguir dos fases:
1. **Diagnóstico:** generar ≥10 preguntas (o más) para entender contexto antes de proponer cambios.  
2. **Ejecución:** redactar un prompt final ultra-preciso con base en las respuestas.  

## 2. Principios
- Nunca asumir: siempre confirmar con preguntas.  
- Cambios acotados por archivo.  
- Prohibido “reemplazos ciegos”: si selector/ID no existe, primero localizar archivo correcto.  
- Mantener integridad del wizard y SBSMI.  

## 3. Ejemplo de Flujo
- Usuario pide: “hacer seleccionables las arenas en el Step 1”.  
- Diagnóstico: preguntas sobre HTML actual, targets Stimulus, clases CSS, eventos globales.  
- Prompt final: instrucción quirúrgica con código pegable, sin alterar lo que ya funciona.  

## 4. Meta
- Evitar daños colaterales en flujo.  
- Mantener consistencia entre front y back.  
- Usar nombres claros: `leagend:event` + controllers Stimulus.  
