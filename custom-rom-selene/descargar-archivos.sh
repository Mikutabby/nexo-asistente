#!/bin/bash
# Script para descargar todos los archivos necesarios para LineageOS 20 en selene

set -e

echo "=== DESCARGADOR DE ARCHIVOS PARA LINEAGEOS 20 - SELENE ==="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Directorio de trabajo
WORK_DIR="$HOME/redmi-selene"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "Directorio de trabajo: $WORK_DIR"
echo ""

# Verificar conexión a internet
if ! ping -c 1 google.com &> /dev/null; then
    echo -e "${RED}ERROR: No hay conexión a internet${NC}"
    exit 1
fi

echo -e "${GREEN}Conexión a internet: OK${NC}"
echo ""

# PASO 1: Descargar herramientas
echo "[1/6] Descargando herramientas..."
if [ ! -d "selenerom" ]; then
    git clone https://github.com/jzadl/selenerom.git 2>/dev/null
    echo -e "${GREEN}Guía descargada${NC}"
else
    echo -e "${YELLOW}Guía ya existe${NC}"
fi

# PASO 2: Descargar TWRP
echo "[2/6] Descargando TWRP..."
if [ ! -f "twrp-selene.zip" ]; then
    # Intentar desde halabtech
    wget -O twrp-selene.zip "https://support.halabtech.com/index.php?a=downloads&b=file&id=811396" 2>/dev/null || \
    wget -O twrp-selene.img "https://androidfilehost.com/?fid=14871746926876849150" 2>/dev/null
    echo -e "${GREEN}TWRP descargado${NC}"
else
    echo -e "${YELLOW}TWRP ya existe${NC}"
fi

# PASO 3: Descargar LineageOS
echo "[3/6] Buscando LineageOS..."
echo -e "${YELLOW}IMPORTANTE: Necesitas descargar LineageOS manualmente${NC}"
echo "  Opción 1: Usa el script selenerom/selene_downloader.sh"
echo "  Opción 2: Busca 'LineageOS selene SourceForge'"
echo ""

# PASO 4: Descargar GApps
echo "[4/6] Descargando GApps..."
if [ ! -f "gapps-arm64-13.zip" ]; then
    echo -e "${YELLOW}GApps no encontrado. Necesitas descargar manualmente:${NC}"
    echo "  Ve a: https://opengapps.org/"
    echo "  Selecciona: ARM64 > 13 > Pico o Nano"
    echo "  Guarda como: gapps-arm64-13.zip"
else
    echo -e "${GREEN}GApps ya existe${NC}"
fi

# PASO 5: Descargar Magisk
echo "[5/6] Descargando Magisk..."
if [ ! -f "magisk.apk" ]; then
    wget -O magisk.apk "https://github.com/topjohnwu/Magisk/releases/download/v27.0/Magisk-v27.0.apk" 2>/dev/null
    echo -e "${GREEN}Magisk descargado${NC}"
else
    echo -e "${YELLOW}Magisk ya existe${NC}"
fi

# PASO 6: Verificar archivos
echo "[6/6] Verificando archivos..."
echo ""
echo "=== ARCHIVOS DESCARGADOS ==="
echo ""

if [ -f "twrp-selene.zip" ] || [ -f "twrp-selene.img" ]; then
    echo -e "${GREEN}✓ TWRP${NC}"
else
    echo -e "${RED}✗ TWRP no encontrado${NC}"
fi

if [ -f "magisk.apk" ]; then
    echo -e "${GREEN}✓ Magisk${NC}"
else
    echo -e "${RED}✗ Magisk no encontrado${NC}"
fi

if [ -f "gapps-arm64-13.zip" ]; then
    echo -e "${GREEN}✓ GApps${NC}"
else
    echo -e "${YELLOW}⚠ GApps (descargar manualmente)${NC}"
fi

echo ""
echo "=== PRÓXIMOS PASOS ==="
echo ""
echo "1. Descarga LineageOS manualmente:"
echo "   - Ejecuta: cd selenerom && ./selene_downloader.sh"
echo "   - O busca en SourceForge"
echo ""
echo "2. Descarga GApps:"
echo "   - Ve a https://opengapps.org/"
echo "   - ARM64 > 13 > Pico"
echo ""
echo "3. Sigue la guía en: GUIA-COMPLETA.md"
echo ""
echo "4. Cuando estés listo, ejecuta: ./instalar-lineageos.sh"
echo ""
echo -e "${GREEN}¡Archivos listos!${NC}"