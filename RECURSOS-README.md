# Sistema de Gestión de Recursos Nexo

Este sistema previene que tu PC se sobrecargue monitoreando el uso de CPU y RAM.

## Características

- Monitoreo continuo de CPU y RAM
- Alertas visuales y de sonido
- Limpieza automática de memoria cuando es crítica
- Detección de procesos pesados
- Configurable (umbrales de alerta)
- Integrado con el sistema de skills de Nexo

## Instalación

```bash
cd ~/nexo-asistente
chmod +x install-resource-monitor.sh
./install-resource-monitor.sh
```

## Uso

### Desde terminal

```bash
# Verificar recursos una vez
nexo-resource-monitor once

# Ejecutar en segundo plano
nexo-resource-monitor daemon

# Detener monitor
pkill -f nexo-resource-monitor

# Limpiar procesos pesados
nexo-resource-monitor clean

# Ver estado
nexo-resource-monitor status
```

### Desde Nexo

```bash
# Monitorear recursos
nexo-skill run recursos monitorear

# Iniciar daemon
nexo-skill run recursos daemon

# Detener daemon
nexo-skill run recursos detener

# Limpiar procesos
nexo-skill run recursos limpiar

# Ver procesos por CPU
nexo-skill run recursos cpu

# Ver procesos por RAM
nexo-skill run recursos ram
```

## Configuración

### Valores por defecto

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| CPU_WARN | 70% | Alerta de CPU |
| CPU_CRIT | 85% | Crítico de CPU |
| RAM_WARN | 75% | Alerta de RAM |
| RAM_CRIT | 90% | Crítico de RAM |
| CHECK_INTERVAL | 5s | Intervalo de verificación |

### Cambiar configuración

```bash
chmod +x configure-resource-monitor.sh
./configure-resource-monitor.sh
```

## Logs

Los registros se guardan en:
```
/var/log/nexo-resource-monitor.log
```

## Servicio systemd

Si instalaste el servicio, se ejecuta automáticamente al iniciar el sistema.

### Comandos del servicio

```bash
# Ver estado
sudo systemctl status nexo-resource-monitor

# Detener
sudo systemctl stop nexo-resource-monitor

# Iniciar
sudo systemctl start nexo-resource-monitor

# Deshabilitar auto-inicio
sudo systemctl disable nexo-resource-monitor
```

## Comportamiento

### Alerta (WARN)
- Notificación visual
- Aviso por voz
- Registro en log

### Crítico (CRIT)
- Notificación visual urgente
- Aviso por voz urgente
- Limpieza automática de memoria
- Registro en log

## Integración con temp-monitor

El sistema de recursos funciona junto con el monitor de temperatura:
- `temp-monitor.sh` - Monitorea temperatura y apaga si es necesario
- `resource-monitor.sh` - Monitorea CPU y RAM, limpia si es necesario

Ambos se ejecutan en paralelo y se complementan.

## Desinstalación

```bash
# Detener servicio
sudo systemctl stop nexo-resource-monitor
sudo systemctl disable nexo-resource-monitor
sudo rm /etc/systemd/system/nexo-resource-monitor.service
sudo systemctl daemon-reload

# Eliminar archivos
rm ~/.local/bin/nexo-resource-monitor
rm -rf ~/.nexo-skills/recursos
rm /var/log/nexo-resource-monitor.log
```
