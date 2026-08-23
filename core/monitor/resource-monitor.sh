#!/bin/bash
# Monitor de recursos del sistema
# Evita que el PC se sobrecargue monitoreando CPU, RAM y procesos

# Configuración
CPU_WARN=70        # Alerta CPU %
CPU_CRIT=85        # Crítico CPU %
RAM_WARN=75        # Alerta RAM %
RAM_CRIT=90        # Crítico RAM %
CHECK_INTERVAL=5   # Segundos entre cada verificación
LOG_FILE="$HOME/.local/log/nexo-resource-monitor.log"
STATUS_FILE="/tmp/nexo-resource-status"
PID_FILE="/tmp/nexo-resource-monitor.pid"

# Colores para output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Función para logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Función para obtener uso de CPU
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print $2+$4}' | cut -d'.' -f1
}

# Función para obtener uso de RAM
get_ram_usage() {
    free | awk '/^Mem/ {printf "%.0f", $3/$2 * 100}'
}

# Función para obtener procesos más pesados
get_heavy_processes() {
    echo "=== Procesos por CPU ==="
    ps aux --sort=-%cpu | head -6
    echo ""
    echo "=== Procesos por RAM ==="
    ps aux --sort=-%mem | head -6
}

# Función para enviar notificación
send_notification() {
    local title="$1"
    local message="$2"
    local urgency="$3"
    
    notify-send -u "$urgency" -t 5000 "$title" "$message" 2>/dev/null || true
    spd-say "$message" 2>/dev/null || true
    log "NOTIFICACIÓN: $title - $message"
}

# Función para mostrar estado en terminal
show_status() {
    local cpu="$1"
    local ram="$2"
    
    echo -e "\n=== MONITOR DE RECURSOS NEXO ==="
    echo -e "Hora: $(date '+%H:%M:%S')"
    echo -e "CPU: ${cpu}%"
    echo -e "RAM: ${ram}%"
    
    if [ "$cpu" -ge "$CPU_CRIT" ]; then
        echo -e "CPU: ${RED}CRÍTICO${NC}"
    elif [ "$cpu" -ge "$CPU_WARN" ]; then
        echo -e "CPU: ${YELLOW}ALERTA${NC}"
    else
        echo -e "CPU: ${GREEN}NORMAL${NC}"
    fi
    
    if [ "$ram" -ge "$RAM_CRIT" ]; then
        echo -e "RAM: ${RED}CRÍTICO${NC}"
    elif [ "$ram" -ge "$RAM_WARN" ]; then
        echo -e "RAM: ${YELLOW}ALERTA${NC}"
    else
        echo -e "RAM: ${GREEN}NORMAL${NC}"
    fi
    echo "=================================="
}

# Función principal de monitoreo
monitor_resources() {
    local cpu=$(get_cpu_usage)
    local ram=$(get_ram_usage)
    
    # Guardar estado
    echo "CPU=$cpu" > "$STATUS_FILE"
    echo "RAM=$ram" >> "$STATUS_FILE"
    echo "TIME=$(date)" >> "$STATUS_FILE"
    
    # Mostrar estado
    show_status "$cpu" "$ram"
    
    # Verificar CPU
    if [ "$cpu" -ge "$CPU_CRIT" ]; then
        send_notification "CPU CRÍTICO" "Uso de CPU al ${cpu}%. Procesos pesados detectados." "critical"
        get_heavy_processes
        log "CPU CRÍTICO: ${cpu}%"
    elif [ "$cpu" -ge "$CPU_WARN" ]; then
        send_notification "CPU ALERTA" "Uso de CPU al ${cpu}%. Monitoreando..." "normal"
        log "CPU ALERTA: ${cpu}%"
    fi
    
    # Verificar RAM
    if [ "$ram" -ge "$RAM_CRIT" ]; then
        send_notification "RAM CRÍTICA" "Uso de RAM al ${ram}%. Liberando memoria..." "critical"
        # Liberar memoria si es crítica
        sync
        echo 1 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1
        log "RAM CRÍTICA: ${ram}% - Memoria liberada"
    elif [ "$ram" -ge "$RAM_WARN" ]; then
        send_notification "RAM ALERTA" "Uso de RAM al ${ram}%." "normal"
        log "RAM ALERTA: ${ram}%"
    fi
    
    # Retornar código de estado
    if [ "$cpu" -ge "$CPU_CRIT" ] || [ "$ram" -ge "$RAM_CRIT" ]; then
        return 2  # Crítico
    elif [ "$cpu" -ge "$CPU_WARN" ] || [ "$ram" -ge "$RAM_WARN" ]; then
        return 1  # Alerta
    else
        return 0  # Normal
    fi
}

# Función para limpiar procesos pesados (opcional)
clean_heavy_processes() {
    echo "Buscando procesos que consumen muchos recursos..."
    
    # Matar procesos de navegador que consumen mucha RAM
    ps aux | grep -E "(chrome|firefox|chromium)" | awk '{if ($4 > 10) print $2}' | head -5 | while read pid; do
        echo "Matando proceso $pid (navegador con mucha RAM)"
        kill -15 "$pid" 2>/dev/null || true
    done
    
    # Matar procesos zombie
    ps aux | awk '{if ($8 ~ /Z/) print $2}' | while read pid; do
        echo "Matando proceso zombie $pid"
        kill -9 "$pid" 2>/dev/null || true
    done
    
    log "Limpieza de procesos pesados completada"
}

# Modo daemon
if [ "$1" = "daemon" ]; then
    log "Iniciando monitor de recursos en modo daemon"
    echo $$ > "$PID_FILE"
    
    while true; do
        monitor_resources
        sleep "$CHECK_INTERVAL"
    done
fi

# Modo una sola ejecución
if [ "$1" = "once" ]; then
    monitor_resources
    exit $?
fi

# Modo limpieza
if [ "$1" = "clean" ]; then
    clean_heavy_processes
    exit 0
fi

# Modo estado
if [ "$1" = "status" ]; then
    if [ -f "$STATUS_FILE" ]; then
        cat "$STATUS_FILE"
    else
        echo "Monitor no está ejecutándose"
    fi
    exit 0
fi

# Modo ayuda
echo "Uso: $0 [daemon|once|clean|status]"
echo ""
echo "Modos:"
echo "  daemon  - Ejecuta en segundo plano monitoreando continuamente"
echo "  once    - Ejecuta una sola verificación"
echo "  clean   - Limpia procesos pesados"
echo "  status  - Muestra el último estado registrado"
