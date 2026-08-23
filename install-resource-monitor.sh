#!/bin/bash
# Instalador del monitor de recursos Nexo
# Evita que el PC se sobrecargue

set -e

echo "=== INSTALADOR MONITOR DE RECURSOS NEXO ==="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verificar que se ejecuta como usuario normal
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}ERROR: No ejecutes este instalador como root${NC}"
    exit 1
fi

# Directorio actual
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Copiar script principal
echo "[1/4] Instalando script principal..."
mkdir -p ~/.local/bin
cp "$SCRIPT_DIR/core/monitor/resource-monitor.sh" ~/.local/bin/nexo-resource-monitor
chmod +x ~/.local/bin/nexo-resource-monitor
echo -e "${GREEN}OK${NC}"

# 2. Copiar skill
echo "[2/4] Instalando skill de recursos..."
mkdir -p ~/.nexo-skills/recursos
cp "$SCRIPT_DIR/skills/recursos/skill.json" ~/.nexo-skills/recursos/
echo -e "${GREEN}OK${NC}"

# 3. Configurar permisos para limpiar caché
echo "[3/4] Configurando permisos..."
echo "Se necesita sudo para liberar memoria cuando esté crítica."
echo "El monitor puede ejecutarse sin sudo, pero la limpieza de RAM requiere permisos."
echo ""

# 4. Preguntar si quiere instalar servicio systemd
read -p "¿Quieres que el monitor se ejecute automáticamente al iniciar? (s/n): " install_service
if [ "$install_service" = "s" ] || [ "$install_service" = "S" ]; then
    echo "[4/4] Instalando servicio systemd..."
    
    # Crear archivo de servicio
    sudo tee /etc/systemd/system/nexo-resource-monitor.service > /dev/null << EOF
[Unit]
Description=Nexo Resource Monitor - Monitoreo de recursos del sistema
After=network.target

[Service]
Type=simple
ExecStart=/home/$USER/.local/bin/nexo-resource-monitor daemon
Restart=always
RestartSec=10
User=$USER
Environment=HOME=/home/$USER

[Install]
WantedBy=multi-user.target
EOF

    # Habilitar e iniciar servicio
    sudo systemctl daemon-reload
    sudo systemctl enable nexo-resource-monitor.service
    sudo systemctl start nexo-resource-monitor.service
    
    echo -e "${GREEN}Servicio instalado y iniciado${NC}"
else
    echo "[4/4] Omitiendo instalación del servicio"
fi

echo ""
echo "=== INSTALACIÓN COMPLETADA ==="
echo ""
echo "Uso:"
echo "  nexo-resource-monitor once     # Verificar una vez"
echo "  nexo-resource-monitor daemon   # Ejecutar en segundo plano"
echo "  nexo-resource-monitor clean    # Limpiar procesos pesados"
echo "  nexo-resource-monitor status   # Ver estado"
echo ""
echo "Dentro del asistente Nexo:"
echo "  nexo-skill run recursos monitorear"
echo "  nexo-skill run recursos daemon"
echo "  nexo-skill run recursos limpiar"
echo ""
echo "Configuración:"
echo "  CPU Alerta: 70%"
echo "  CPU Crítico: 85%"
echo "  RAM Alerta: 75%"
echo "  RAM Crítico: 90%"
echo ""
echo "Los logs se guardan en: /var/log/nexo-resource-monitor.log"
