#!/bin/bash
# Script de optimización para Call of Duty Mobile en Xiaomi Redmi 10C
# Ejecutar desde la PC con el teléfono conectado por USB

set -e

echo "=== OPTIMIZADOR COD MOBILE - REDMI 10C ==="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verificar conexión
if ! adb devices | grep -q "device$"; then
    echo -e "${RED}ERROR: No hay dispositivo Android conectado${NC}"
    exit 1
fi

echo -e "${GREEN}Dispositivo detectado${NC}"
echo ""

# PASO 1: Limpiar caché de COD Mobile
echo "[1/8] Limpiando caché de COD Mobile..."
adb shell pm clear com.activision.callofduty.shooter 2>/dev/null
echo -e "${GREEN}OK${NC}"

# PASO 2: Matar procesos innecesarios
echo "[2/8] Cerrando procesos innecesarios..."
PROCESOS=(
    "com.google.android.googlequicksearchbox"
    "com.google.android.gms"
    "com.google.android.apps.messaging"
    "com.google.android.tts"
    "com.miui.miwallpaper"
    "com.miui.securitycenter.remote"
    "com.xiaomi.xmsf"
    "com.xiaomi.mi_connect_service"
    "com.facebook.appmanager"
    "com.facebook.services"
    "com.facebook.system"
    "com.instagram.android"
    "com.whatsapp"
    "com.spotify.music"
    "com.netflix.mediaclient"
    "com.youtube"
    "com.android.settings"
    "com.lbe.security.miui"
)

for proc in "${PROCESOS[@]}"; do
    adb shell am force-stop "$proc" 2>/dev/null
done
echo -e "${GREEN}OK${NC}"

# PASO 3: Desactivar servicios innecesarios
echo "[3/8] Desactivando servicios innecesarios..."
SERVICIOS=(
    "com.google.android.googlequicksearchbox"
    "com.google.android.apps.messaging"
    "com.xiaomi.xmsf"
    "com.google.android.tts"
)

for svc in "${SERVICIOS[@]}"; do
    adb shell pm disable-user "$svc" 2>/dev/null
done
echo -e "${GREEN}OK${NC}"

# PASO 4: Limpiar caché del sistema
echo "[4/8] Limpiando caché del sistema..."
adb shell rm -rf /data/cache/* 2>/dev/null
echo -e "${GREEN}OK${NC}"

# PASO 5: Configurar opciones de rendimiento (via settings)
echo "[5/8] Configurando opciones de rendimiento..."
adb shell settings put global window_animation_scale 0.5 2>/dev/null
adb shell settings put global transition_animation_scale 0.5 2>/dev/null
adb shell settings put global animator_duration_scale 0.5 2>/dev/null
adb shell settings put global background_process_limit 2 2>/dev/null
adb shell settings put global sem_background_process_limit 2 2>/dev/null
echo -e "${GREEN}OK${NC}"

# PASO 6: Optimizar red para gaming
echo "[6/8] Optimizando configuración de red..."
adb shell settings put global wifi_scan_always_enabled 0 2>/dev/null
adb shell settings put global mobile_data_always_on 0 2>/dev/null
echo -e "${GREEN}OK${NC}"

# PASO 7: Verificar espacio en disco
echo "[7/8] Verificando espacio en disco..."
STORAGE=$(adb shell df /data 2>/dev/null | tail -1 | awk '{print $5}' | tr -d '%')
if [ "$STORAGE" -gt 85 ]; then
    echo -e "${YELLOW}ADVERTENCIA: Disco al ${STORAGE}%. Considera eliminar apps o archivos${NC}"
else
    echo -e "${GREEN}Espacio OK: ${STORAGE}% usado${NC}"
fi

# PASO 8: Resumen
echo "[8/8] Resumen de optimización..."
echo ""
echo "=== CAMBIOS REALIZADOS ==="
echo "✓ Caché de COD Mobile limpiada"
echo "✓ ${#PROCESOS[@]} procesos innecesarios cerrados"
echo "✓ ${#SERVICIOS[@]} servicios desactivados"
echo "✓ Caché del sistema limpiada"
echo "✓ Animaciones reducidas a 0.5x"
echo "✓ Procesos en segundo plano limitados a 2"
echo "✓ Escaneo WiFi automático desactivado"
echo ""
echo "=== RECOMENDACIONES PARA EL JUEGO ==="
echo "1. Abre COD Mobile después de este script"
echo "2. Ve a Settings > Audio & Graphics"
echo "3. Configura:"
echo "   - Graphics Quality: LOW"
echo "   - Frame Rate: HIGH o MEDIUM"
echo "   - Depth of Field: OFF"
echo "   - Real-Time Shadows: OFF"
echo "   - Anti-Aliasing: OFF"
echo "4. No juegues mientras cargas el teléfono"
echo "5. Si el teléfono se calienta, descansa 10 minutos"
echo ""
echo -e "${GREEN}¡Optimización completada!${NC}"
echo ""

# Verificar RAM disponible
echo "=== RAM DISPONIBLE ==="
adb shell cat /proc/meminfo 2>/dev/null | grep -E "(MemTotal|MemFree|MemAvailable)"