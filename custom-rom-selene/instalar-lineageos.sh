#!/bin/bash
# Script de instalación automatizado para LineageOS 20 en Redmi 10 2022 (selene)
# ⚠️ ESTE SCRIPT BORRA TODO. ASEGÚRATE DE TENER BACKUP.

set -e

echo "=== INSTALADOR LINEAGEOS 20 - REDMI 10 2022 (SELENE) ==="
echo ""
echo "⚠️  ADVERTENCIA: ESTE PROCESO BORRA TODOS LOS DATOS"
echo "⚠️  ASEGÚRATE DE TENER BACKUP COMPLETO"
echo ""
read -p "¿Continuar? (s/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Cancelado."
    exit 0
fi

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Directorio de trabajo
WORK_DIR="$HOME/redmi-selene"
cd "$WORK_DIR" 2>/dev/null || { echo -e "${RED}ERROR: Ejecuta primero descargar-archivos.sh${NC}"; exit 1; }

# Verificar conexión
if ! adb devices | grep -q "device$"; then
    echo -e "${RED}ERROR: No hay dispositivo Android conectado${NC}"
    echo "Conecta el teléfono con depuración USB habilitada"
    exit 1
fi

echo -e "${GREEN}Dispositivo detectado${NC}"
echo ""

# PASO 1: Verificar prerequisites
echo "[1/8] Verificando prerequisites..."

# Verificar batería
BATTERY=$(adb shell cat /sys/class/power_supply/battery/capacity 2>/dev/null)
if [ "$BATTERY" -lt 50 ]; then
    echo -e "${RED}ERROR: Batería al ${BATTERY}%. Necesitas al menos 50%${NC}"
    exit 1
fi
echo -e "${GREEN}Batería: ${BATTERY}% OK${NC}"

# Verificar bootloader
BOOTLOADER=$(adb shell getprop ro.boot.flash.locked 2>/dev/null)
if [ "$BOOTLOADER" = "1" ]; then
    echo -e "${RED}ERROR: Bootloader bloqueado. Desbloquea primero.${NC}"
    exit 1
fi
echo -e "${GREEN}Bootloader: Desbloqueado OK${NC}"

# Verificar archivos
if [ ! -f "twrp-selene.zip" ] && [ ! -f "twrp-selene.img" ]; then
    echo -e "${RED}ERROR: TWRP no encontrado. Ejecuta descargar-archivos.sh primero.${NC}"
    exit 1
fi
echo -e "${GREEN}Archivos: OK${NC}"
echo ""

# PASO 2: Backup
echo "[2/8] Creando backup..."
BACKUP_DIR="$HOME/backup-redmi10-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Guardando lista de apps..."
adb shell pm list packages > "$BACKUP_DIR/packages.txt"
echo -e "${GREEN}Backup de metadatos${NC}"
echo ""

# PASO 3: Reiniciar a bootloader
echo "[3/8] Reiniciando a bootloader..."
adb reboot bootloader
sleep 5
echo -e "${GREEN}En bootloader${NC}"

# PASO 4: Flash TWRP
echo "[4/8] Instalando TWRP..."
if [ -f "twrp-selene.img" ]; then
    # Método fastboot
    fastboot flash boot_a twrp-selene.img
    fastboot flash boot_b twrp-selene.img
else
    # Método mtkclient (si está disponible)
    if command -v python3 &> /dev/null && [ -d "$HOME/mtkclient" ]; then
        cd "$HOME/mtkclient"
        python3 mtk w boot_a "$WORK_DIR/twrp-selene.img"
        python3 mtk w boot_b "$WORK_DIR/twrp-selene.img"
        cd "$WORK_DIR"
    else
        echo -e "${RED}ERROR: Necesitas twrp-selene.img para flash por fastboot${NC}"
        echo "Descarga desde: https://androidfilehost.com/?fid=14871746926876849150"
        exit 1
    fi
fi
echo -e "${GREEN}TWRP instalado${NC}"

# PASO 5: Reiniciar a Recovery
echo "[5/8] Reiniciando a Recovery..."
fastboot reboot recovery
sleep 10
echo -e "${GREEN}En Recovery${NC}"
echo ""

# PASO 6: Wipe
echo "[6/8] Limpiando particiones..."
echo "⚠️  IMPORTANTE: En TWRP, selecciona:"
echo "  1. Wipe > Advanced Wipe"
echo "  2. Selecciona: Dalvik, Cache, System, Data"
echo "  3. Swipe to Wipe"
echo ""
echo "Presiona Enter cuando hayas terminado de hacer wipe..."
read

# PASO 7: Flash LineageOS
echo "[7/8] Instalando LineageOS..."
echo "⚠️  IMPORTANTE: En TWRP:"
echo "  1. Install > Busca el zip de LineageOS"
echo "  2. Selecciona el zip"
echo "  3. Swipe to Confirm Flash"
echo ""
echo "¿LineageOS ya está instalado? (s/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${GREEN}LineageOS instalado${NC}"
else
    echo "Instala LineageOS manualmente desde TWRP y vuelve a ejecutar este script."
    echo "O ejecuta: adb sideload lineage-selene.zip"
    exit 0
fi

# PASO 8: Flash GApps (opcional)
echo "[8/8] Instalando GApps..."
echo "¿Quieres instalar GApps? (s/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    if [ -f "gapps-arm64-13.zip" ]; then
        echo "Usa TWRP para instalar GApps:"
        echo "  1. Install > Selecciona gapps-arm64-13.zip"
        echo "  2. Swipe to Confirm Flash"
        echo ""
        echo "Presiona Enter cuando GApps esté instalado..."
        read
        echo -e "${GREEN}GApps instalado${NC}"
    else
        echo -e "${YELLOW}GApps no encontrado. Instálalo manualmente después.${NC}"
    fi
fi

# Reiniciar
echo ""
echo "=== INSTALACIÓN COMPLETADA ==="
echo ""
echo "Reiniciando al sistema..."
fastboot reboot

echo ""
echo -e "${GREEN}¡LineageOS 20 instalado!${NC}"
echo ""
echo "La primera vez puede tardar 5-10 minutos en arrancar."
echo "No toques el teléfono mientras arranca."
echo ""
echo "=== PRÓXIMOS PASOS ==="
echo "1. Configurar wizard de inicio"
echo "2. Conectar a WiFi"
echo "3. Instalar apps desde Play Store"
echo "4. Configurar para gaming (ver GUIA-COMPLETA.md)"
echo ""
echo "=== BACKUP GUARDADO EN ==="
echo "$BACKUP_DIR"
echo ""
echo "¡Buena suerte! 🎉"