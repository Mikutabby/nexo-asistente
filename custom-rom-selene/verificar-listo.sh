#!/bin/bash
# Script de verificación pre-instalación
# Verifica que todo esté listo para instalar LineageOS

set -e

echo "=== VERIFICADOR PRE-INSTALACIÓN - SELENE ==="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

# Verificar conexión
echo "[1/8] Verificando conexión USB..."
if adb devices | grep -q "device$"; then
    echo -e "${GREEN}✓ Dispositivo conectado${NC}"
else
    echo -e "${RED}✗ No hay dispositivo conectado${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Verificar modelo
echo ""
echo "[2/8] Verificando modelo del dispositivo..."
MODEL=$(adb shell getprop ro.product.device 2>/dev/null)
if [ "$MODEL" = "selene" ]; then
    echo -e "${GREEN}✓ Modelo correcto: selene${NC}"
else
    echo -e "${RED}✗ Modelo incorrecto: $MODEL (esperado: selene)${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Verificar bootloader
echo ""
echo "[3/8] Verificando bootloader..."
LOCKED=$(adb shell getprop ro.boot.flash.locked 2>/dev/null)
if [ "$LOCKED" = "0" ]; then
    echo -e "${GREEN}✓ Bootloader desbloqueado${NC}"
else
    echo -e "${RED}✗ Bootloader bloqueado${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Verificar batería
echo ""
echo "[4/8] Verificando batería..."
BATTERY=$(adb shell cat /sys/class/power_supply/battery/capacity 2>/dev/null)
if [ "$BATTERY" -ge 50 ]; then
    echo -e "${GREEN}✓ Batería: ${BATTERY}%${NC}"
else
    echo -e "${YELLOW}⚠ Batería baja: ${BATTERY}% (mínimo 50%)${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Verificar depuración USB
echo ""
echo "[5/8] Verificando depuración USB..."
DEBUG=$(adb shell getprop persist.sys.usb.config 2>/dev/null)
if echo "$DEBUG" | grep -q "adb"; then
    echo -e "${GREEN}✓ Depuración USB habilitada${NC}"
else
    echo -e "${YELLOW}⚠ Depuración USB podría no estar habilitada${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Verificar espacio en disco
echo ""
echo "[6/8] Verificando espacio en disco..."
STORAGE=$(adb shell df /data 2>/dev/null | tail -1 | awk '{print $4}')
STORAGE_MB=$((STORAGE / 1024))
if [ "$STORAGE_MB" -gt 1000 ]; then
    echo -e "${GREEN}✓ Espacio suficiente: ${STORAGE_MB} MB${NC}"
else
    echo -e "${YELLOW}⚠ Poco espacio: ${STORAGE_MB} MB${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Verificar archivos descargados
echo ""
echo "[7/8] Verificando archivos descargados..."
WORK_DIR="$HOME/redmi-selene"

if [ -f "$WORK_DIR/twrp-selene.zip" ] || [ -f "$WORK_DIR/twrp-selene.img" ]; then
    echo -e "${GREEN}✓ TWRP encontrado${NC}"
else
    echo -e "${RED}✗ TWRP no encontrado${NC}"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "$WORK_DIR/magisk.apk" ]; then
    echo -e "${GREEN}✓ Magisk encontrado${NC}"
else
    echo -e "${YELLOW}⚠ Magisk no encontrado (opcional)${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Verificar internet
echo ""
echo "[8/8] Verificando conexión a internet..."
if ping -c 1 google.com &> /dev/null; then
    echo -e "${GREEN}✓ Conexión a internet${NC}"
else
    echo -e "${YELLOW}⚠ Sin conexión a internet${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Resumen
echo ""
echo "=== RESUMEN ==="
echo ""
echo "Errores: $ERRORS"
echo "Advertencias: $WARNINGS"
echo ""

if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}❌ HAY ERRORES. Corrígelos antes de continuar.${NC}"
    echo ""
    echo "Errores encontrados:"
    if [ "$MODEL" != "selene" ]; then
        echo "  - Modelo incorrecto"
    fi
    if [ "$LOCKED" = "1" ]; then
        echo "  - Bootloader bloqueado"
    fi
    if [ ! -f "$WORK_DIR/twrp-selene.zip" ] && [ ! -f "$WORK_DIR/twrp-selene.img" ]; then
        echo "  - TWRP no encontrado"
    fi
    exit 1
fi

if [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  HAY ADVERTENCIAS. Puedes continuar, pero revisa.${NC}"
    echo ""
    echo "Advertencias:"
    if [ "$BATTERY" -lt 50 ]; then
        echo "  - Batería baja"
    fi
    if [ ! -f "$WORK_DIR/magisk.apk" ]; then
        echo "  - Magisk no encontrado (opcional)"
    fi
fi

if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "${GREEN}✅ TODO LISTO PARA INSTALAR LINEAGEOS 20${NC}"
fi

echo ""
echo "=== PRÓXIMO PASO ==="
echo ""
echo "Si todo está OK, ejecuta:"
echo "  ./instalar-lineageos.sh"
echo ""
echo "O siéguete la guía completa:"
echo "  cat GUIA-COMPLETA.md"
echo ""
echo "¡Buena suerte! 🎉"