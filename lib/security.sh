# ── Security Functions for Nexo Asistente ──────────────────────────────
# Funciones compartidas de seguridad para todos los scripts de identidad.
# Source este archivo en cualquier script que necesite verificación.
#
# Functions:
#   security_rate_limit <key> [max_attempts] [window_seconds]
#   security_audit_log <event> [details]
#   security_hash <string>  → SHA256 hash (con salt opcional)
#   security_verify_hash <input> <expected_hash>
#   security_lockout_check <key> [lockout_seconds]
#   security_increment_fail <key>
#   security_reset_fail <key>

NEXO_SECURITY_DIR="${NEXO_SECURITY_DIR:-$HOME/.nexo-memory/.security}"
NEXO_AUDIT_DIR="${NEXO_AUDIT_DIR:-$HOME/.nexo-memory/log/audit}"

# ── Rate Limiting ─────────────────────────────────────────────────────
# Almacena intentos fallidos en archivos temporales.
# Key: identificador único (ej: "verify_creator", "verify_secret")

security_rate_limit() {
    local key="$1"
    local max_attempts="${2:-5}"
    local window="${3:-300}"  # 5 minutos por defecto
    local fail_file="$NEXO_SECURITY_DIR/fail_${key//[^a-zA-Z0-9]/_}"
    local now
    now=$(date +%s)

    mkdir -p "$NEXO_SECURITY_DIR"

    if [ ! -f "$fail_file" ]; then
        echo "0:$now" > "$fail_file"
        chmod 600 "$fail_file"
        return 0
    fi

    local content
    content=$(cat "$fail_file")
    local count="${content%%:*}"
    local first_fail="${content##*:}"

    # Si pasó la ventana de tiempo, resetear
    if [ $((now - first_fail)) -gt "$window" ]; then
        echo "0:$now" > "$fail_file"
        return 0
    fi

    # Si excedió el máximo, bloquear
    if [ "$count" -ge "$max_attempts" ]; then
        local remaining=$(( window - (now - first_fail) ))
        security_audit_log "RATE_LIMITED" "key=$key attempts=$count cooldown=${remaining}s"
        echo "❌ Demasiados intentos. Esperá ${remaining}s."
        return 1
    fi

    return 0
}

security_increment_fail() {
    local key="$1"
    local fail_file="$NEXO_SECURITY_DIR/fail_${key//[^a-zA-Z0-9]/_}"
    local now
    now=$(date +%s)

    mkdir -p "$NEXO_SECURITY_DIR"

    if [ ! -f "$fail_file" ]; then
        echo "1:$now" > "$fail_file"
        return
    fi

    local content
    content=$(cat "$fail_file")
    local count="${content%%:*}"
    echo "$((count + 1)):${content##*:}" > "$fail_file"
}

security_reset_fail() {
    local key="$1"
    local fail_file="$NEXO_SECURITY_DIR/fail_${key//[^a-zA-Z0-9]/_}"
    rm -f "$fail_file"
}

security_lockout_check() {
    local key="$1"
    local lockout="${2:-300}"
    local fail_file="$NEXO_SECURITY_DIR/fail_${key//[^a-zA-Z0-9]/_}"
    local now
    now=$(date +%s)

    if [ ! -f "$fail_file" ]; then
        return 0
    fi

    local content
    content=$(cat "$fail_file")
    local count="${content%%:*}"
    local first_fail="${content##*:}"

    if [ "$count" -ge 5 ] && [ $((now - first_fail)) -lt "$lockout" ]; then
        local remaining=$(( lockout - (now - first_fail) ))
        echo "🔒 Bloqueado. Esperá ${remaining}s."
        return 1
    fi

    return 0
}

# ── Audit Logging ─────────────────────────────────────────────────────
# Log inmutable de eventos de seguridad. Cada línea es un evento JSON.

security_audit_log() {
    local event="$1"
    local details="${2:-}"
    local user
    user=$(whoami 2>/dev/null || echo "unknown")
    local now
    now=$(date '+%Y-%m-%dT%H:%M:%S%z')
    local pid=$$

    mkdir -p "$NEXO_AUDIT_DIR"

    local audit_file="$NEXO_AUDIT_DIR/audit-$(date +%Y-%m-%d).log"

    # Formato: timestamp|event|user|pid|details
    echo "$now | $event | user=$user | pid=$pid | $details" >> "$audit_file"
    chmod 600 "$audit_file"
}

# ── Hash Seguro ───────────────────────────────────────────────────────
# Hash SHA256 con salt opcional. Nunca loggear el input.

security_hash() {
    local input="$1"
    local salt="${2:-}"
    echo -n "${salt}${input}" | sha256sum | cut -d' ' -f1
}

security_verify_hash() {
    local input="$1"
    local expected="$2"
    local salt="${3:-}"
    local actual
    actual=$(security_hash "$input" "$salt")
    [ "$actual" = "$expected" ]
}

# ── Identity File (fuera de /tmp) ─────────────────────────────────────

security_get_identity_file() {
    echo "$HOME/.nexo-memory/.current-identity"
}

security_write_identity() {
    local identity="$1"
    local user="$2"
    local id_file
    id_file=$(security_get_identity_file)

    mkdir -p "$(dirname "$id_file")"
    cat > "$id_file" <<EOF
{"identity":"$identity","user":"$user","timestamp":$(date +%s)}
EOF
    chmod 600 "$id_file"
}

security_read_identity() {
    local id_file
    id_file=$(security_get_identity_file)
    if [ -f "$id_file" ]; then
        cat "$id_file"
    else
        echo '{"identity":"nobody","user":"","timestamp":0}'
    fi
}

# ── File Immutability ─────────────────────────────────────────────────
# Intenta hacer archivo inmutable con chattr +i. Fallback a chmod 444.

security_make_immutable() {
    local file="$1"
    if command -v chattr &>/dev/null; then
        chattr +i "$file" 2>/dev/null && return 0
    fi
    chmod 444 "$file" 2>/dev/null
}

# ── Initialization ────────────────────────────────────────────────────

security_init() {
    mkdir -p "$NEXO_SECURITY_DIR" "$NEXO_AUDIT_DIR"
    chmod 700 "$NEXO_SECURITY_DIR" "$NEXO_AUDIT_DIR"
}
