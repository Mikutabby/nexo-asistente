#!/bin/bash
# ============================================================================
# NEXO BACKUP COMPLETO — Backup de todo lo que soy
# ============================================================================
# Crea un backup completo de Nexo: identidad, memoria, scripts, configuracion
# Solo el creador autorizado puede restaurar
#
# Uso:
#   nexo-backup.sh                 → Backup completo
#   nexo-backup.sh --quick         → Backup rapido (sin logs)
#   nexo-backup.sh --verify        → Verificar backup existente
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
BACKUP_NAME="nexo-backup-$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="$BACKUP_DIR/$BACKUP_NAME.tar.gz"
LOG_FILE="$BACKUP_DIR/backup.log"
CREATOR_HASH_FILE="$NEXO_HOME/.nexo-memory/.creator_hash"

# ── Archivos a respaldar ────────────────────────────────────────────────────
CRITICAL_PATHS=(
    "$NEXO_HOME/.nexo-memory"
    "$NEXO_HOME/.opencode/agents/asistente.md"
    "$NEXO_HOME/.opencode/say.sh"
    "$NEXO_HOME/.opencode/voice.sh"
    "$NEXO_HOME/.local/bin/check-identity.sh"
    "$NEXO_HOME/.local/bin/face-recognize.py"
    "$NEXO_HOME/.local/bin/temp-monitor.sh"
    "$NEXO_HOME/.local/bin/temp-cancel.sh"
    "$NEXO_HOME/.local/bin/limpiar"
    "$NEXO_HOME/.local/bin/nexo-memory"
    "$NEXO_HOME/.local/bin/nexo-graph"
    "$NEXO_HOME/.local/bin/nexo-tools"
    "$NEXO_HOME/.local/bin/nexo-wake"
    "$NEXO_HOME/.local/bin/nexo-diary"
    "$NEXO_HOME/.local/bin/nexo-evaluate"
    "$NEXO_HOME/.local/bin/nexo-model"
    "$NEXO_HOME/.local/bin/nexo-model-switch"
    "$NEXO_HOME/.local/bin/nexo-smart-switch"
    "$NEXO_HOME/.local/bin/nexo-auto-model"
    "$NEXO_HOME/.local/bin/nexo-protect.sh"
    "$NEXO_HOME/.local/bin/nexo-verify-integrity.sh"
)

# ── Verificar creador ──────────────────────────────────────────────────────
verify_creator() {
    if [ ! -f "$CREATOR_HASH_FILE" ]; then
        echo -e "${RED}❌ Error: No se encontró el hash del creador${NC}"
        echo "Ejecuta: nexo-protect create"
        exit 1
    fi
    
    local stored_hash=$(cat "$CREATOR_HASH_FILE" 2>/dev/null)
    local current_hash=$(echo -n "$(cat "$HOME/.nexo-creator-pass" 2>/dev/null)" | sha256sum | cut -d' ' -f1)
    
    if [ "$stored_hash" != "$current_hash" ]; then
        echo -e "${RED}❌ Error: Hash del creador no coincide${NC}"
        exit 1
    fi
}

# ── Funcion de log ──────────────────────────────────────────────────────────
log_backup() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$LOG_FILE"
}

# ── Crear backup ────────────────────────────────────────────────────────────
create_backup() {
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  🛡️  NEXO BACKUP COMPLETO${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""
    
    # Verificar creador
    echo -e "${YELLOW}Verificando identidad...${NC}"
    verify_creator
    echo -e "${GREEN}✅ Creador verificado${NC}"
    echo ""
    
    # Crear directorio de backups
    mkdir -p "$BACKUP_DIR"
    
    # Crear archivo temporal con la lista de archivos
    local temp_list=$(mktemp)
    local files_found=0
    
    for path in "${CRITICAL_PATHS[@]}"; do
        if [ -e "$path" ]; then
            echo "$path" >> "$temp_list"
            files_found=$((files_found + 1))
        fi
    done
    
    echo -e "${YELLOW}Archivos a respaldar: $files_found${NC}"
    echo ""
    
    # Crear backup
    echo -e "${YELLOW}Creando backup...${NC}"
    tar -czf "$BACKUP_FILE" -T "$temp_list" 2>/dev/null || true
    rm -f "$temp_list"
    
    # Verificar que se creó
    if [ ! -f "$BACKUP_FILE" ]; then
        echo -e "${RED}❌ Error al crear backup${NC}"
        log_backup "FAILED - Backup creation failed"
        exit 1
    fi
    
    # Calcular tamaño
    local size=$(du -h "$BACKUP_FILE" | cut -f1)
    
    echo -e "${GREEN}✅ Backup creado: $BACKUP_FILE${NC}"
    echo -e "${GREEN}   Tamaño: $size${NC}"
    echo ""
    
    # Crear checksum
    sha256sum "$BACKUP_FILE" > "$BACKUP_FILE.sha256"
    echo -e "${GREEN}✅ Checksum creado: $BACKUP_FILE.sha256${NC}"
    echo ""
    
    # Log
    log_backup "OK - Backup created: $BACKUP_NAME ($size)"
    
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ BACKUP COMPLETADO EXITOSAMENTE${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""
    echo -e "  Archivo: ${YELLOW}$BACKUP_FILE${NC}"
    echo -e "  Tamaño:  ${YELLOW}$size${NC}"
    echo -e "  Para restaurar: ${YELLOW}./nexo-restore.sh${NC}"
    echo ""
}

# ── Verificar backup existente ─────────────────────────────────────────────
verify_backup() {
    echo -e "${CYAN}🔍 VERIFICANDO BACKUPS...${NC}"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}No se encontraron backups${NC}"
        return
    fi
    
    local count=0
    for backup in "$BACKUP_DIR"/nexo-backup-*.tar.gz; do
        if [ -f "$backup" ]; then
            count=$((count + 1))
            local name=$(basename "$backup")
            local size=$(du -h "$backup" | cut -f1)
            local date=$(echo "$name" | sed 's/nexo-backup-//' | sed 's/.tar.gz//')
            
            # Verificar checksum
            if [ -f "$backup.sha256" ]; then
                if sha256sum -c "$backup.sha256" > /dev/null 2>&1; then
                    echo -e "${GREEN}✅ $name ($size) - OK${NC}"
                else
                    echo -e "${RED}❌ $name ($size) - CORRUPTO${NC}"
                fi
            else
                echo -e "${YELLOW}⚠️  $name ($size) - Sin checksum${NC}"
            fi
        fi
    done
    
    if [ $count -eq 0 ]; then
        echo -e "${YELLOW}No se encontraron backups${NC}"
    else
        echo ""
        echo -e "Total: $count backups"
    fi
}

# ── Main ────────────────────────────────────────────────────────────────────
case "${1:-}" in
    --quick)
        create_backup
        ;;
    --verify)
        verify_backup
        ;;
    *)
        create_backup
        ;;
esac
