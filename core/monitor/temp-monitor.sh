#!/bin/bash
# Monitor de temperatura - avisa por parlantes y apaga si es critico
# Cancelar apagado: temp-cancel.sh

WARN=75       # Alerta temprana (solo avisa)
CRIT=80       # Shutdown
COOLDOWN=480  # 8 minutos
LOG_TAG="nexo-temp-monitor"
STATUS_FILE="/tmp/nexo-temp-monitor-status"

# Leer temperatura
TEMP=""
if [ -f /sys/class/thermal/thermal_zone1/temp ]; then
    TEMP=$(awk '{printf "%d", $1/1000}' /sys/class/thermal/thermal_zone1/temp)
elif [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP=$(awk '{printf "%d", $1/1000}' /sys/class/thermal/thermal_zone0/temp)
fi

if [ -z "$TEMP" ]; then
    TEMP=$(sensors 2>/dev/null | grep "Package id 0:" | grep -oP '+\?\d+\.\d+°C' | head -1 | tr -d '+°C' | awk -F. '{print $1}')
fi

[ -z "$TEMP" ] && exit 1

echo "$TEMP" > "$STATUS_FILE"
logger -t "$LOG_TAG" "${TEMP}°C"

# ---- PRE-ALERTA (solo aviso, sin apagar) ----
if [ "$TEMP" -ge "$WARN" ] && [ "$TEMP" -lt "$CRIT" ]; then
    logger -t "$LOG_TAG" "Precaucion: ${TEMP}°C"
    notify-send -u critical -t 6000 \
        "Temperatura: ${TEMP}°C" \
        "Cuidado, se esta calentando." 2>/dev/null || true
    spd-say "Cuidado, la temperatura esta en ${TEMP} grados" 2>/dev/null || true
    exit 0
fi

# ---- CRITICO ----
if [ "$TEMP" -ge "$CRIT" ]; then
    # Si ya estamos en cooldown, no repetir
    if [ -f /tmp/nexo-temp-monitor-cooldown ]; then
        exit 0
    fi

    logger -t "$LOG_TAG" "CRITICO! ${TEMP}°C"

    # Hablar por los parlantes
    spd-say "ATENCION. Temperatura critica: ${TEMP} grados. El sistema se apagara en dos minutos. Decid no para cancelar." 2>/dev/null || true

    notify-send -u critical -t 12000 \
        "CRITICO: ${TEMP}°C" \
        "Apagado en 2 minutos.\nGuarda tu trabajo.\nCancelar: temp-cancel.sh" 2>/dev/null || true

    wall "  TEMPERATURA CRITICA: ${TEMP}°C
  Apagado en 2 minutos. Guarda tu trabajo.
  Decid NO para cancelar."

    touch /tmp/nexo-temp-monitor-cooldown

    # Esperar 1 minuto
    sleep 60

    # Si cancelaron, salir
    if [ ! -f /tmp/nexo-temp-monitor-cooldown ]; then
        logger -t "$LOG_TAG" "Apagado cancelado por el usuario"
        spd-say "Apagado cancelado" 2>/dev/null || true
        exit 0
    fi

    # Segundo aviso
    spd-say "Un minuto restante. Guarda tu trabajo." 2>/dev/null || true
    notify-send -u critical -t 8000 \
        "1 minuto restante" \
        "Apagado en 60 segundos." 2>/dev/null || true
    wall "  1 minuto para el apagado."

    sleep 30

    if [ ! -f /tmp/nexo-temp-monitor-cooldown ]; then
        logger -t "$LOG_TAG" "Apagado cancelado por el usuario"
        spd-say "Apagado cancelado" 2>/dev/null || true
        exit 0
    fi

    # Tercer aviso
    spd-say "Treinta segundos. Ultimo aviso." 2>/dev/null || true
    notify-send -u critical -t 8000 \
        "30 segundos" \
        "Ultimo aviso." 2>/dev/null || true
    wall "  30 segundos."

    sleep 30

    if [ ! -f /tmp/nexo-temp-monitor-cooldown ]; then
        logger -t "$LOG_TAG" "Apagado cancelado por el usuario"
        spd-say "Apagado cancelado" 2>/dev/null || true
        exit 0
    fi

    # Apagar y programar reinicio
    spd-say "Apagando sistema" 2>/dev/null || true
    sudo /sbin/rtcwake -m off -s "$COOLDOWN"
    sudo /usr/bin/systemctl poweroff
fi
