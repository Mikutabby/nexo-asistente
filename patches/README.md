# Nexo Comprehensive Fixes — Patch 0002

## Que arregla

| # | Fix | Archivos | Gravedad |
|---|-----|----------|----------|
| 1 | **Wake loop quema disco**: ~9GB/dia en WAVs | `nexo-wake` | 🔴 Critico |
| 2 | **verify-secret.sh bypass**: hash de string vacio | `verify-secret.sh` | 🔴 Critico |
| 3 | **nexo-skill ignora args**: los comandos nunca recibian parametros | `nexo-skill` | 🔴 Critico |
| 4 | **Config fallback**: apuntaba a `opencode.json` (inexistente) | `nexo-model`, `nexo-model-switch`, `nexo-smart-switch`, `nexo-auto-model` | 🟡 Alto |
| 5 | **Restore silencioso**: `|| true` ocultaba errores de tar | `nexo-restore.sh` | 🟡 Alto |
| 6 | **install.sh sin --auto**: no soportaba instalacion headless | `install.sh` | 🟢 Medio |
| 7 | **drop_caches agresivo**: `echo 3` mataba rendimiento del sistema | `limpiar` | 🟢 Medio |
| 8 | **Regex roto en sensors**: nunca detectaba temperatura | `temp-monitor.sh` | 🟢 Medio |

## Como aplicar

```bash
cd /ruta/a/nexo-asistente
git am patches/0002-comprehensive-fixes.patch
```

O si no hay git:

```bash
cd /ruta/a/nexo-asistente
patch -p1 < patches/0002-comprehensive-fixes.patch
```

## Compatibilidad

- Aplica sobre `nexo-asistente` v2 (repo original)
- Diseñado para funcionar con el Parche 0001 (security-fixes)
- Testeado en Linux (x86_64) y Termux (proot-distro Ubuntu ARM64)
