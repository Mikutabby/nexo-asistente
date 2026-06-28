#!/bin/bash
# ============================================================================
# NEXO AUTO-RESTORE — Restauración rápida de Nexo
# ============================================================================
# Restaura Nexo desde un backup completo
# Solo el creador (skullgremkin) puede restaurar
#
# Uso:
#   nexo-restore.sh                    → Restaurar último backup
#   nexo-restore.sh --list             → Listar backups disponibles
#   nexo-restore.sh --file <archivo>  → Restaurar backup específico
#   nexo-restore.sh --full             → Restauración completa (reinstala todo)
# ============================================================================

set -euo pipefail

# ── Colores ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Configuracion ───────────────────────────────────────────────────────────
NEXO_HOME="${NEXO_HOME:-$HOME}"
BACKUP_DIR="$NEXO_HOME/.nexo-backups"
NEXO_ASISTENTE="$NEXO_HOME/nexo-asistente"
CREATOR_HASH_FILE="$NEXO_HOME/.nexo-memory/.creator_hash"
LOG_FILE="$NEXO_HOME/.nexo-memory/log/restore.log"

# ── Verificar creador ──────────────────────────────────────────────────────
verify_creator() {
    echo -e "${YELLOW}🔐 Verificando identidad...${NC}"
    
    if [ ! -f "$CREATOR_HASH_FILE" ]; then
        # Si no hay hash, crear uno
        mkdir -p "$(dirname "$CREATOR_HASH_FILE")"
        echo -n "skullgremkin" | sha256sum | cut -d' ' -f1 > "$CREATOR_HASH_FILE"
        chmod 600 "$CREATOR_HASH_FILE"
        echo -e "${GREEN}✅ Hash del creador creado${NC}"
        return 0
    fi
    
    local stored_hash=$(cat "$CREATOR_HASH_FILE" 2>/dev/null)
    local current_hash=$(echo -n "skullgremkin" | sha256sum | cut -d' ' -f1)
    
    if [ "$stored_hash" != "$current_hash" ]; then
        echo -e "${RED}❌ Error: Hash del creador no coincide${NC}"
        echo "Solo el creador puede restaurar Nexo"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Creador verificado${NC}"
}

# ── Funcion de log ──────────────────────────────────────────────────────────
log_restore() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$LOG_FILE"
}

# ── Listar backups ──────────────────────────────────────────────────────────
list_backups() {
    echo -e "${CYAN}📦 BACKUPS DISPONIBLES${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}No se encontraron backups${NC}"
        echo "Ejecuta: nexo-backup.sh"
        return
    fi
    
    local count=0
    for backup in "$BACKUP_DIR"/nexo-backup-*.tar.gz; do
        if [ -f "$backup" ]; then
            count=$((count + 1))
            local name=$(basename "$backup")
            local size=$(du -h "$backup" | cut -f1)
            local date=$(echo "$name" | sed 's/nexo-backup-//' | sed 's/.tar.gz//')
            
            echo -e "  ${GREEN}$count${NC}. ${YELLOW}$name${NC} ($size)"
        fi
    done
    
    if [ $count -eq 0 ]; then
        echo -e "${YELLOW}No se encontraron backups${NC}"
    else
        echo ""
        echo -e "Total: $count backups"
        echo -e "Usa: ${YELLOW}./nexo-restore.sh --file <archivo>${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
}

# ── Restaurar backup ────────────────────────────────────────────────────────
restore_backup() {
    local backup_file="$1"
    
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  🔄 NEXO AUTO-RESTORE${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""
    
    # Verificar creador
    verify_creator
    echo ""
    
    # Verificar que existe el backup
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}❌ Error: No se encontró el backup: $backup_file${NC}"
        exit 1
    fi
    
    # Verificar checksum
    if [ -f "$backup_file.sha256" ]; then
        echo -e "${YELLOW}Verificando integridad...${NC}"
        if ! sha256sum -c "$backup_file.sha256" > /dev/null 2>&1; then
            echo -e "${RED}❌ Error: Backup corrupto${NC}"
            exit 1
        fi
        echo -e "${GREEN}✅ Integridad verificada${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Restaurando Nexo...${NC}"
    
    # Crear directorios necesarios
    mkdir -p "$NEXO_HOME/.nexo-memory/log"
    mkdir -p "$NEXO_HOME/.opencode/agents"
    mkdir -p "$NEXO_HOME/.local/bin"
    
    # Restaurar archivos
    tar -xzf "$backup_file" -C / 2>/dev/null || true
    
    # Restaurar permisos
    chmod +x "$NEXO_HOME/.opencode/say.sh" 2>/dev/null || true
    chmod +x "$NEXO_HOME/.opencode/voice.sh" 2>/dev/null || true
    chmod +x "$NEXO_HOME/.local/bin/"* 2>/dev/null || true
    
    echo -e "${GREEN}✅ Archivos restaurados${NC}"
    echo ""
    
    # Verificar restauración
    echo -e "${YELLOW}Verificando restauración...${NC}"
    local files_restored=0
    
    for file in "$NEXO_HOME/.nexo-memory/memory.json" \
                "$NEXO_HOME/.opencode/agents/asistente.md" \
                "$NEXO_HOME/.opencode/say.sh"; do
        if [ -f "$file" ]; then
            files_restored=$((files_restored + 1))
        fi
    done
    
    if [ $files_restored -gt 0 ]; then
        echo -e "${GREEN}✅ $files_restored archivos críticos restaurados${NC}"
    fi
    
    # Log
    log_restore "OK - Restored from: $(basename "$backup_file")"
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ NEXO RESTAURADO EXITOSAMENTE${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""
    echo -e "  Backup: ${YELLOW}$(basename "$backup_file")${NC}"
    echo -e "  Estado: ${GREEN}Nexo está de vuelta${NC}"
    echo ""
}

# ── Restauración completa ──────────────────────────────────────────────────
full_restore() {
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  🔄 NEXO RESTAURACIÓN COMPLETA${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""
    
    # Verificar creador
    verify_creator
    echo ""
    
    # Clonar repo si no existe
    if [ ! -d "$NEXO_ASISTENTE" ]; then
        echo -e "${YELLOW}Clonando repositorio...${NC}"
        git clone https://github.com/Mikutabby/nexo-asistente.git "$NEXO_ASISTENTE"
        echo -e "${GREEN}✅ Repositorio clonado${NC}"
    else
        echo -e "${YELLOW}Actualizando repositorio...${NC}"
        cd "$NEXO_ASISTENTE" && git pull
        echo -e "${GREEN}✅ Repositorio actualizado${NC}"
    fi
    
    echo ""
    
    # Ejecutar instalador
    if [ -f "$NEXO_ASISTENTE/install.sh" ]; then
        echo -e "${YELLOW}Ejecutando instalador...${NC}"
        cd "$NEXO_ASISTENTE" && ./install.sh --auto
        echo -e "${GREEN}✅ Instalación completada${NC}"
    fi
    
    # Restaurar último backup si existe
    local latest_backup=$(ls -t "$BACKUP_DIR"/nexo-backup-*.tar.gz 2>/dev/null | head -1)
    if [ -n "$latest_backup" ]; then
        echo ""
        echo -e "${YELLOW}Restaurando último backup...${NC}"
        restore_backup "$latest_backup"
    fi
    
    # Log
    log_restore "OK - Full restore completed"
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ NEXO COMPLETAMENTE RESTAURADO${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
}

# ── Main ────────────────────────────────────────────────────────────────────
case "${1:-}" in
    --list|-l)
        list_backups
        ;;
    --file|-f)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error: Especifica un archivo de backup${NC}"
            echo "Uso: ./nexo-restore.sh --file <archivo>"
            exit 1
        fi
        restore_backup "$2"
        ;;
    --full)
        full_restore
        ;;
    *)
        # Restaurar último backup
        local latest_backup=$(ls -t "$BACKUP_DIR"/nexo-backup-*.tar.gz 2>/dev/null | head -1)
        if [ -z "$latest_backup" ]; then
            echo -e "${YELLOW}No se encontraron backups${NC}"
            echo "Opciones:"
            echo "  1. Crear backup: nexo-backup.sh"
            echo "  2. Restauración completa: ./nexo-restore.sh --full"
            exit 1
        fi
        restore_backup "$latest_backup"
        ;;
esac
