#!/bin/bash
# Configurador del monitor de recursos Nexo
# Permite cambiar los umbrales de alerta

set -e

echo "=== CONFIGURADOR MONITOR DE RECURSOS NEXO ==="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Archivo de configuración
CONFIG_FILE="$HOME/.local/bin/nexo-resource-monitor"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}ERROR: Monitor no instalado. Ejecuta install-resource-monitor.sh primero${NC}"
    exit 1
fi

# Mostrar configuración actual
echo "Configuración actual:"
echo "===================="
grep -E '(CPU_WARN|CPU_CRIT|RAM_WARN|RAM_CRIT|CHECK_INTERVAL)' "$CONFIG_FILE"
echo ""

# Pedir nuevos valores
echo "Ingresa los nuevos valores (deja vacío para mantener el actual):"
echo ""

read -p "CPU Alerta [%] (actual: $(grep '^CPU_WARN=' "$CONFIG_FILE" | cut -d'=' -f2)): " new_cpu_warn
read -p "CPU Crítico [%] (actual: $(grep '^CPU_CRIT=' "$CONFIG_FILE" | cut -d'=' -f2)): " new_cpu_crit
read -p "RAM Alerta [%] (actual: $(grep '^RAM_WARN=' "$CONFIG_FILE" | cut -d'=' -f2)): " new_ram_warn
read -p "RAM Crítico [%] (actual: $(grep '^RAM_CRIT=' "$CONFIG_FILE" | cut -d'=' -f2)): " new_ram_crit
read -p "Intervalo de verificación [seg] (actual: $(grep '^CHECK_INTERVAL=' "$CONFIG_FILE" | cut -d'=' -f2)): " new_interval

# Actualizar configuración
if [ -n "$new_cpu_warn" ]; then
    sed -i "s/^CPU_WARN=.*/CPU_WARN=$new_cpu_warn/" "$CONFIG_FILE"
    echo -e "${GREEN}CPU Alerta actualizado a $new_cpu_warn%${NC}"
fi

if [ -n "$new_cpu_crit" ]; then
    sed -i "s/^CPU_CRIT=.*/CPU_CRIT=$new_cpu_crit/" "$CONFIG_FILE"
    echo -e "${GREEN}CPU Crítico actualizado a $new_cpu_crit%${NC}"
fi

if [ -n "$new_ram_warn" ]; then
    sed -i "s/^RAM_WARN=.*/RAM_WARN=$new_ram_warn/" "$CONFIG_FILE"
    echo -e "${GREEN}RAM Alerta actualizado a $new_ram_warn%${NC}"
fi

if [ -n "$new_ram_crit" ]; then
    sed -i "s/^RAM_CRIT=.*/RAM_CRIT=$new_ram_crit/" "$CONFIG_FILE"
    echo -e "${GREEN}RAM Crítico actualizado a $new_ram_crit%${NC}"
fi

if [ -n "$new_interval" ]; then
    sed -i "s/^CHECK_INTERVAL=.*/CHECK_INTERVAL=$new_interval/" "$CONFIG_FILE"
    echo -e "${GREEN}Intervalo actualizado a $new_interval segundos${NC}"
fi

echo ""
echo "=== CONFIGURACIÓN ACTUALIZADA ==="
echo ""
echo "Los cambios se aplicarán la próxima vez que el monitor se inicie."
echo "Si el monitor está ejecutándose, reinícialo:"
echo "  nexo-skill run recursos detener"
echo "  nexo-skill run recursos daemon"
