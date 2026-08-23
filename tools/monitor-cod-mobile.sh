#!/bin/bash
# Monitor de rendimiento para COD Mobile en Redmi 10C
# Ejecutar antes de jugar para verificar que todo está óptimo

echo "=== MONITOR DE RENDIMIENTO COD MOBILE ==="
echo ""

# Verificar conexión
if ! adb devices | grep -q "device$"; then
    echo "ERROR: No hay dispositivo Android conectado"
    exit 1
fi

echo "Estado actual del teléfono:"
echo ""

# RAM
echo "1. MEMORIA RAM:"
RAM_TOTAL=$(adb shell cat /proc/meminfo 2>/dev/null | grep MemTotal | awk '{print $2}')
RAM_FREE=$(adb shell cat /proc/meminfo 2>/dev/null | grep MemFree | awk '{print $2}')
RAM_AVAIL=$(adb shell cat /proc/meminfo 2>/dev/null | grep MemAvailable | awk '{print $2}')

echo "   Total: $((RAM_TOTAL/1024)) MB"
echo "   Libre: $((RAM_FREE/1024)) MB"
echo "   Disponible: $((RAM_AVAIL/1024)) MB"

if [ "$RAM_AVAIL" -lt 800000 ]; then
    echo "   ⚠️  ADVERTENCIA: RAM baja. Cierra apps antes de jugar."
else
    echo "   ✅ RAM suficiente para gaming"
fi
echo ""

# Almacenamiento
echo "2. ALMACENAMIENTO:"
STORAGE_USED=$(adb shell df /data 2>/dev/null | tail -1 | awk '{print $5}' | tr -d '%')
echo "   Usado: ${STORAGE_USED}%"

if [ "$STORAGE_USED" -gt 85 ]; then
    echo "   ⚠️  ADVERTENCIA: Poco espacio libre."
else
    echo "   ✅ Espacio suficiente"
fi
echo ""

# Procesos
echo "3. PROCESOS:"
PROCESOS=$(adb shell ps -A 2>/dev/null | wc -l)
echo "   Totales: $PROCESOS"

if [ "$PROCESOS" -gt 100 ]; then
    echo "   ⚠️  ADVERTENCIA: Muchos procesos activos."
else
    echo "   ✅ Procesos bajo control"
fi
echo ""

# COD Mobile
echo "4. CALL OF DUTY MOBILE:"
COD_RUNNING=$(adb shell ps -A 2>/dev/null | grep -i callofduty | wc -l)
if [ "$COD_RUNNING" -gt 0 ]; then
    echo "   ✅ Juego ejecutándose"
else
    echo "   ⏸️  Juego no está corriendo"
fi

# Caché de COD
COD_CACHE=$(adb shell du -s /data/data/com.activision.callofduty.shooter 2>/dev/null | awk '{print $1}')
if [ -n "$COD_CACHE" ]; then
    echo "   Caché: $((COD_CACHE/1024)) MB"
else
    echo "   Caché: Limpiada"
fi
echo ""

# Configuración de rendimiento
echo "5. CONFIGURACIÓN DE RENDIMIENTO:"
ANIM_SCALE=$(adb shell settings get global window_animation_scale 2>/dev/null)
BG_LIMIT=$(adb shell settings get global background_process_limit 2>/dev/null)

echo "   Animaciones: ${ANIM_SCALE:-default}"
echo "   Límite BG processes: ${BG_LIMIT:-default}"
echo ""

# Recomendaciones
echo "=== RECOMENDACIONES ==="
echo ""

if [ "$RAM_AVAIL" -lt 800000 ]; then
    echo "❌ RAM insuficiente. Ejecuta: optimizar-cod-mobile.sh"
fi

if [ "$STORAGE_USED" -gt 85 ]; then
    echo "❌ Poco espacio. Elimina apps o archivos grandes."
fi

if [ "$PROCESOS" -gt 150 ]; then
    echo "❌ Demasiados procesos. Reinicia el teléfono."
fi

echo ""
echo "=== CONSEJOS PARA MEJOR RENDIMIENTO ==="
echo "1. Reinicia el teléfono antes de jugar"
echo "2. No juegues mientras cargas el teléfono"
echo "3. Configura gráficos en LOW en el juego"
echo "4. Si el teléfono se calienta, descansa 10 min"
echo "5. Usa WiFi estable (no datos móviles)"
echo ""
echo "=== MONITOREO COMPLETADO ==="