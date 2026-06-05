#!/bin/bash
# =============================================================================
# Nexo Asistente - Instalador interactivo
# =============================================================================
# Este script instala Nexo en el sistema del usuario.
# Es interactivo: pregunta antes de cada paso y se adapta al usuario.
# =============================================================================

set -euo pipefail

# ─── Colores ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"
OPENCODE_DIR="$HOME/.opencode"
AGENT_DIR="$HOME/.opencode/agents"
CONFIG_DIR="$HOME/.config/opencode"

# ─── Banner ──────────────────────────────────────────────────────────────────
echo -e "${CYAN}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║        Nexo Asistente v2             ║"
echo "  ║  Instalador interactivo              ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${NC}"

# ─── 1. Detectar usuario ────────────────────────────────────────────────────
CURRENT_USER=$(whoami)
info "Usuario actual del sistema: ${CURRENT_USER}"

read -p "Como quieres que te llame Nexo? (Enter para usar '${CURRENT_USER}'): " USER_NAME
USER_NAME="${USER_NAME:-$CURRENT_USER}"
ok "Nexo te llamara: ${USER_NAME}"

# ─── 2. Verificar sudo ──────────────────────────────────────────────────────
echo ""
info "Verificando acceso sudo..."
if sudo -n true 2>/dev/null; then
    ok "Acceso sudo sin contrasena verificado"
else
    warn "Se necesita acceso sudo para algunas funciones."
    warn "El instalador continuara, pero algunas caracteristicas requieren sudo."
    warn "Configura NOPASSWD en sudoers para una experiencia completa."
fi

# ─── 3. Detectar sistema operativo ──────────────────────────────────────────
echo ""
info "Detectando sistema operativo..."
if command -v apt &>/dev/null; then
    PKG_MANAGER="apt"
    PKG_INSTALL="apt install -y"
    ok "Sistema Debian/Ubuntu detectado"
elif command -v pacman &>/dev/null; then
    PKG_MANAGER="pacman"
    PKG_INSTALL="pacman -S --noconfirm"
    ok "Sistema Arch detectado"
elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
    PKG_INSTALL="dnf install -y"
    ok "Sistema Fedora detectado"
else
    warn "Sistema operativo no reconocido. Continuando con dependencias minimas."
    PKG_MANAGER=""
    PKG_INSTALL=""
fi

# ─── 4. Instalar dependencias ───────────────────────────────────────────────
echo ""
info "Paso 1: Instalar dependencias del sistema"
read -p "Instalar dependencias basicas? (espeak-ng, python3, jq, curl) [S/n]: " INSTALL_DEPS
INSTALL_DEPS="${INSTALL_DEPS:-S}"

if [[ "$INSTALL_DEPS" =~ ^[Ss]$ ]]; then
    if [ -n "$PKG_MANAGER" ]; then
        info "Instalando dependencias..."
        case "$PKG_MANAGER" in
            apt)
                sudo apt update -qq 2>/dev/null
                sudo $PKG_INSTALL espeak-ng mpg123 python3 python3-pip jq curl wget 2>/dev/null && ok "Dependencias instaladas" || warn "Alguna dependencia fallo"
                ;;
            pacman)
                sudo $PKG_INSTALL espeak-ng mpg123 python python-pip jq curl wget 2>/dev/null && ok "Dependencias instaladas" || warn "Alguna dependencia fallo"
                ;;
            dnf)
                sudo $PKG_INSTALL espeak-ng mpg123 python3 python3-pip jq curl wget 2>/dev/null && ok "Dependencias instaladas" || warn "Alguna dependencia fallo"
                ;;
        esac
    else
        warn "No se pudo instalar dependencias automaticamente."
        warn "Instala manualmente: espeak-ng, python3, mpg123, jq, curl"
    fi
else
    info "Omitiendo instalacion de dependencias"
fi

# ─── 5. Instalar dependencias Python ────────────────────────────────────────
echo ""
info "Paso 2: Dependencias Python"
read -p "Instalar dependencias Python? (gtts, speechrecognition) [S/n]: " INSTALL_PY
INSTALL_PY="${INSTALL_PY:-S}"

if [[ "$INSTALL_PY" =~ ^[Ss]$ ]]; then
    pip3 install --break-system-packages gtts SpeechRecognition 2>/dev/null && \
        ok "Dependencias Python instaladas" || \
        pip3 install gtts SpeechRecognition 2>/dev/null && \
        ok "Dependencias Python instaladas" || \
        warn "No se pudieron instalar dependencias Python (pip3 requiere --break-system-packages)"
fi

# ─── 6. Copiar scripts ─────────────────────────────────────────────────────
echo ""
info "Paso 3: Copiar scripts del sistema"

mkdir -p "$INSTALL_DIR"

# Core
cp "$SCRIPT_DIR/core/identity/check-identity.sh" "$INSTALL_DIR/" 2>/dev/null && chmod +x "$INSTALL_DIR/check-identity.sh"
cp "$SCRIPT_DIR/core/monitor/temp-monitor.sh" "$INSTALL_DIR/" 2>/dev/null && chmod +x "$INSTALL_DIR/temp-monitor.sh"
cp "$SCRIPT_DIR/core/monitor/temp-cancel.sh" "$INSTALL_DIR/" 2>/dev/null && chmod +x "$INSTALL_DIR/temp-cancel.sh"
cp "$SCRIPT_DIR/core/system/limpiar" "$INSTALL_DIR/" 2>/dev/null && chmod +x "$INSTALL_DIR/limpiar"

# Memory
cp "$SCRIPT_DIR/memory/nexo-graph" "$INSTALL_DIR/" 2>/dev/null && chmod +x "$INSTALL_DIR/nexo-graph"
cp "$SCRIPT_DIR/memory/nexo-memory" "$INSTALL_DIR/" 2>/dev/null && chmod +x "$INSTALL_DIR/nexo-memory"

# Voice
cp "$SCRIPT_DIR/voice/say.sh" "$OPENCODE_DIR/" 2>/dev/null && chmod +x "$OPENCODE_DIR/say.sh"
mkdir -p "$HOME/.opencode"
cp "$SCRIPT_DIR/voice/voice.sh" "$OPENCODE_DIR/" 2>/dev/null && chmod +x "$OPENCODE_DIR/voice.sh"

# Tools
cp "$SCRIPT_DIR/tools/nexo-diary" "$INSTALL_DIR/" 2>/dev/null && chmod +x "$INSTALL_DIR/nexo-diary"
cp "$SCRIPT_DIR/tools/nexo-evaluate" "$INSTALL_DIR/" 2>/dev/null && chmod +x "$INSTALL_DIR/nexo-evaluate"
cp "$SCRIPT_DIR/tools/nexo-tools" "$INSTALL_DIR/" 2>/dev/null && chmod +x "$INSTALL_DIR/nexo-tools"
cp "$SCRIPT_DIR/tools/nexo-wake" "$INSTALL_DIR/" 2>/dev/null && chmod +x "$INSTALL_DIR/nexo-wake"

# Backup
cp "$SCRIPT_DIR/backup/nexo-backup.sh" "$INSTALL_DIR/" 2>/dev/null && chmod +x "$INSTALL_DIR/nexo-backup.sh"
cp "$SCRIPT_DIR/backup/nexo-restore.sh" "$INSTALL_DIR/" 2>/dev/null && chmod +x "$INSTALL_DIR/nexo-restore.sh"

ok "Scripts copiados a ${INSTALL_DIR} y ${OPENCODE_DIR}"

# ─── 7. Configurar agente de OpenCode ──────────────────────────────────────
echo ""
info "Paso 4: Configurar agente de OpenCode"
read -p "Configurar Nexo como agente de OpenCode? [S/n]: " SETUP_OPENCODE
SETUP_OPENCODE="${SETUP_OPENCODE:-S}"

if [[ "$SETUP_OPENCODE" =~ ^[Ss]$ ]]; then
    mkdir -p "$AGENT_DIR"
    
    # Copiar asistente.md (es generico, no necesita reemplazos)
    cp "$SCRIPT_DIR/agent/asistente.md" "$AGENT_DIR/asistente.md"
    
    ok "Agente de OpenCode configurado en ${AGENT_DIR}/asistente.md"
    info "Para usarlo, agrega esto a tu ~/.config/opencode/opencode.jsonc:"
    echo '  "instructions": ["agents/asistente.md"]'
    
    # Copiar ejemplo de configuracion
    mkdir -p "$CONFIG_DIR"
    if [ ! -f "$CONFIG_DIR/opencode.jsonc" ]; then
        cp "$SCRIPT_DIR/config/opencode.jsonc.example" "$CONFIG_DIR/"
        info "Ejemplo de configuracion copiado a ${CONFIG_DIR}/opencode.jsonc.example"
    fi
fi

# ─── 8. Configurar servicios ───────────────────────────────────────────────
echo ""
info "Paso 5: Servicios del sistema (OPCIONAL)"
read -p "Configurar servicio de rendimiento CPU (cpu-performance)? [s/N]: " SETUP_CPU
if [[ "$SETUP_CPU" =~ ^[Ss]$ ]]; then
    sudo cp "$SCRIPT_DIR/config/cpu-performance.service" /etc/systemd/system/ 2>/dev/null
    sudo systemctl daemon-reload 2>/dev/null
    sudo systemctl enable cpu-performance.service 2>/dev/null
    sudo systemctl start cpu-performance.service 2>/dev/null && ok "CPU Performance activado" || warn "No se pudo activar CPU Performance"
fi

read -p "Configurar monitor de temperatura (temp-monitor)? [s/N]: " SETUP_TEMP
if [[ "$SETUP_TEMP" =~ ^[Ss]$ ]]; then
    # Configurar sudoers
    sudo sed "s/USERNAME/${USER_NAME}/g" "$SCRIPT_DIR/config/sudoers.temp-monitor" | \
        sudo tee /etc/sudoers.d/nexo-temp-monitor >/dev/null 2>&1
    sudo chmod 440 /etc/sudoers.d/nexo-temp-monitor 2>/dev/null && \
        ok "Sudoers configurado para temp-monitor" || \
        warn "No se pudo configurar sudoers (requiere privilegios)"
    
    # Configurar crontab
    (crontab -l 2>/dev/null; echo "*/2 * * * * $INSTALL_DIR/temp-monitor.sh >/dev/null 2>&1") | crontab - 2>/dev/null && \
        ok "Crontab configurado para temp-monitor" || \
        warn "No se pudo configurar crontab"
fi

# ─── 9. Configurar backup automatico ───────────────────────────────────────
echo ""
info "Paso 6: Backup automatico (OPCIONAL)"
read -p "Configurar backup diario con cron? [s/N]: " SETUP_BACKUP
if [[ "$SETUP_BACKUP" =~ ^[Ss]$ ]]; then
    (crontab -l 2>/dev/null; echo "0 4 * * * $INSTALL_DIR/nexo-backup.sh >/dev/null 2>&1") | crontab - 2>/dev/null && \
        ok "Backup diario configurado (4 AM)" || \
        warn "No se pudo configurar backup"
    
    info "Configura una passphrase para el backup cifrado:"
    read -s -p "Passphrase (dejala vacia para desactivar cifrado): " BACKUP_PASS
    echo ""
    if [ -n "$BACKUP_PASS" ]; then
        echo "$BACKUP_PASS" > "$HOME/.nexo-backup-pass"
        chmod 600 "$HOME/.nexo-backup-pass"
        ok "Passphrase guardada en ~/.nexo-backup-pass"
    fi
fi

# ─── 10. Inicializar memoria ────────────────────────────────────────────────
echo ""
info "Paso 7: Inicializar memoria de Nexo"
read -p "Inicializar memoria persistente ahora? [S/n]: " INIT_MEM
INIT_MEM="${INIT_MEM:-S}"

if [[ "$INIT_MEM" =~ ^[Ss]$ ]]; then
    mkdir -p "$HOME/.nexo-memory"
    
    # Crear memory.json inicial
    USER_HASH=$(echo -n "$USER_NAME" | md5sum | cut -d' ' -f1)
    cat > "$HOME/.nexo-memory/memory.json" <<EOF
{
  "user_name": "${USER_NAME}",
  "user_hash": "${USER_HASH}",
  "nexo_version": "2.0",
  "created_at": $(date +%s),
  "facts": [],
  "habits": [],
  "learned_commands": [],
  "network_devices": [],
  "improvements": []
}
EOF
    ok "Memoria inicializada para: ${USER_NAME}"
    
    # Inicializar knowledge graph
    if [ -f "$INSTALL_DIR/nexo-graph" ]; then
        $INSTALL_DIR/nexo-graph init 2>/dev/null && ok "Knowledge graph inicializado" || warn "No se pudo inicializar knowledge graph"
    fi
fi

# ─── 11. PATH ───────────────────────────────────────────────────────────────
echo ""
info "Paso 8: Agregar INSTALL_DIR al PATH"
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    SHELL_CONFIG="$HOME/.bashrc"
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    fi
    echo "" >> "$SHELL_CONFIG"
    echo "# Nexo Asistente" >> "$SHELL_CONFIG"
    echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_CONFIG"
    ok "INSTALL_DIR agregado a PATH en ${SHELL_CONFIG}"
    info "Ejecuta: source ${SHELL_CONFIG}"
else
    ok "INSTALL_DIR ya esta en el PATH"
fi

# ─── Resumen final ──────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Instalacion completada!          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GREEN}Usuario:${NC}     ${USER_NAME}"
echo -e "  ${GREEN}Scripts en:${NC}  ${INSTALL_DIR}"
echo -e "  ${GREEN}Agente en:${NC}   ${AGENT_DIR}/asistente.md"
echo ""
echo "  Nexo ahora te conoce como ${USER_NAME}."
echo "  Cada interaccion, aprendera mas de vos."
echo "  Experimenta, proba, rompe y construi."
echo "  Nexo se adapta a VOS."
echo ""
echo -e "  ${YELLOW}Para empezar a usar Nexo en OpenCode:${NC}"
echo "  1. Agrega 'agents/asistente.md' a tus instrucciones de opencode"
echo "  2. O ejecuta: opencode --instructions agents/asistente.md"
echo ""

# Marcar instalacion
date > "$HOME/.nexo-installed"
echo "2.0" > "$HOME/.nexo-version"
