#!/bin/bash
# Script para volver a MIUI desde LineageOS
# Útil si algo sale mal

set -e

echo "=== RESTAURADOR MIUI - REDMI 10 2022 (SELENE) ==="
echo ""
echo "⚠️  ESTE SCRIPT RESTAURA MIUI ORIGINAL"
echo "⚠️  TODOS LOS DATOS DE LINEAGEOS SE PERDERÁN"
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

# Verificar conexión
if ! adb devices | grep -q "device$"; then
    echo -e "${RED}ERROR: No hay dispositivo Android conectado${NC}"
    exit 1
fi

echo -e "${GREEN}Dispositivo detectado${NC}"
echo ""

# PASO 1: Buscar MIUI ROM
echo "[1/4] Buscando MIUI ROM..."
MIUI_ROM=$(find . -name "*.zip" -path "*MIUI*" -o -name "*.zip" -path "*miui*" 2>/dev/null | head -1)

if [ -z "$MIUI_ROM" ]; then
    echo -e "${YELLOW}MIUI ROM no encontrado. Descargando...${NC}"
    echo "Descarga MIUI ROM manualmente:"
    echo "  Ve a: https://xiaomirom.com/en/download/redmi-10-10-2022-10-prime-selene-stable-V13.0.16.0.SKUMIXM/"
    echo "  Guarda el archivo en: $HOME/redmi-selene/"
    echo ""
    echo "Presiona Enter cuando hayas descargado el ROM..."
    read
    MIUI_ROM=$(find . -name "*.zip" -path "*MIUI*" -o -name "*.zip" -path "*miui*" 2>/dev/null | head -1)
fi

if [ -z "$MIUI_ROM" ]; then
    echo -e "${RED}ERROR: No se encontró MIUI ROM${NC}"
    echo "Descárgalo manualmente y vuelve a ejecutar este script."
    exit 1
fi

echo -e "${GREEN}MIUI ROM encontrado: $MIUI_ROM${NC}"
echo ""

# PASO 2: Reiniciar a Recovery
echo "[2/4] Reiniciando a Recovery..."
adb reboot recovery
sleep 10
echo -e "${GREEN}En Recovery${NC}"

# PASO 3: Flash MIUI
echo "[3/4] Instalando MIUI..."
echo "⚠️  IMPORTANTE: En TWRP:"
echo "  1. Wipe > Advanced Wipe"
echo "  2. Selecciona: Dalvik, Cache, System, Data"
echo "  3. Swipe to Wipe"
echo "  4. Install > Selecciona el zip de MIUI"
echo "  5. Swipe to Confirm Flash"
echo ""
echo "Presiona Enter cuando MIUI esté instalado..."
read
echo -e "${GREEN}MIUI instalado${NC}"

# PASO 4: Reiniciar
echo "[4/4] Reiniciando al sistema..."
adb reboot

echo ""
echo -e "${GREEN}¡MIUI restaurado!${NC}"
echo ""
echo "La primera vez puede tardar 5-10 minutos en arrancar."
echo ""
echo "=== ALTERNATIVA: SP Flash Tool ==="
echo "Si TWRP no funciona, usa SP Flash Tool:"
echo "  1. Descarga SP Flash Tool"
echo "  2. Descarga Fastboot ROM de MIUI"
echo "  3. Flashea desde SP Flash Tool"
echo ""
echo "¡Listo! 🎉"