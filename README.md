# Nexo Asistente

Un asistente autonomo de sistema Linux que se adapta a tu forma de usar la PC. Aprende de cada interaccion, automatiza tareas y gestiona tu ecosistema digital.

## Filosofia

Nexo no viene con datos precargados ni presupone quien sos. Al instalarse, comienza a aprender desde cero. Cada comando que ejecutas, cada preferencia que expresas, cada dispositivo que conectas se vuelve parte de su memoria.

Con el tiempo, Nexo:
- Reconoce tus patrones de uso
- Anticipa tus necesidades
- Automatiza tareas repetitivas
- Optimiza tu sistema basado en tus habitos

## Seguridad y Privacidad

Nexo procesa datos localmente en tu PC. No envía información a servicios externos.

### Caracteristicas

- Verificacion de identidad integrada
- Archivos de configuracion protegidos
- Backups cifrados con GPG
- Logs de actividad

### Filosofia

Nexo esta disenado para ser tu asistente personal, no para espiarte. Todos los datos se mantienen en tu maquina.

## Estructura del repositorio

```
nexo-asistente/
├── agent/             Archivo agente para OpenCode
│   └── asistente.md
├── core/              Scripts esenciales del sistema
│   ├── identity/      Deteccion de usuario
│   ├── monitor/       Monitoreo de temperatura
│   └── system/        Utilidades del sistema
├── memory/            Sistema de memoria persistente
│   ├── nexo-graph     Knowledge graph
│   └── nexo-memory    Memoria persistente
├── voice/             Sistema de voz
│   ├── say.sh         Text-to-Speech
│   └── voice.sh       Speech-to-Text
├── tools/             Herramientas auxiliares
├── skills/            Sistema de plugins
├── backup/            Backup y restore
├── config/            Ejemplos de configuracion
├── install.sh         Instalador
└── README.md          Este archivo
```

## Instalacion

```bash
git clone https://github.com/Mikutabby/nexo-asistente.git
cd nexo-asistente
chmod +x install.sh
./install.sh
```

El instalador es interactivo y te guiara por cada paso:
1. Te preguntara como quieres que te llame
2. Instalara las dependencias necesarias
3. Configurara los scripts en tu sistema
4. Te ofrecera activar servicios opcionales (monitor de temperatura, backup automatico)
5. Inicializara la memoria persistente

## Requisitos minimos

- Linux con bash
- Python 3
- Opcional: espeak-ng para voz basica
- Opcional: gTTS + SpeechRecognition para voz cloud
- Opcional: Piper TTS para voz neural offline

## Componentes opcionales

Nexo es modular. Puedes activar solo lo que necesitas:

| Componente | Descripcion | Como activarlo |
|---|---|---|---|
| Monitor temp | Apaga el PC si se sobrecalienta | `install.sh` (paso 5) |
| Voz TTS | Nexo habla por los parlantes | Automatico si instalas dependencias |
| Voz STT | Nexo escucha lo que decis | `voice.sh` con SpeechRecognition |
| Backup cifrado | Backup diario con GPG | `install.sh` (paso 10) |
| Wake word | Nexo escucha su nombre | `nexo-wake daemon start` |
| Knowledge graph | Memoria semantica | `install.sh` (paso 11) |
| Skills | Plugins de funcionalidad | `install.sh` (incluido) |
| Graphify | Grafo de conocimiento para codigo | `install.sh` (paso 9) o `pipx install graphifyy` |

## Personalizacion

Nexo se adapta a vos con el tiempo, pero puedes acelerar el proceso:

- Contale tus preferencias directamente: "Nexo, prefiero que me hables en tono formal"
- Mostrale tus rutinas: usalo regularmente y aprendera tus horarios
- Pedile que recuerde cosas: "Nexo, recorda que mi contraseña de WiFi es X"
- Agregale herramientas: `nexo-tools add nombre descripcion comando`

## Skills (Plugins)

Nexo tiene un sistema de skills que permite agregar funcionalidades como plugins:

```bash
# Listar skills instalados
nexo-skill list

# Ver informacion de un skill
nexo-skill info sistema

# Ejecutar un comando de un skill
nexo-skill run sistema resumen
nexo-skill run web ip
nexo-skill run web dns google.com

# Crear un skill nuevo
nexo-skill create mi-skill
```

Los skills se almacenan en `~/.nexo-skills/` y cada uno tiene un `skill.json` con sus comandos.

### Skills incluidos

| Skill | Comandos | Descripcion |
|---|---|---|
| `sistema` | resumen, cpu, ram, disco, temp, puertos | Monitoreo del sistema |
| `web` | ip, warp-status, dns, qr | Herramientas web |
| `ejemplo` | hola, fecha, ejemplo | Template de ejemplo |

## Graphify — Grafo de Conocimiento para Codigo

Nexo incluye integracion con [Graphify](https://github.com/safishamsi/graphify), una herramienta que convierte cualquier carpeta de proyecto en un grafo de conocimiento consultable.

**Como funciona:**
1. Analiza tu codigo con tree-sitter (100% local, sin gastar tokens)
2. Opcionalmente extrae relaciones semanticas de docs e imagenes via LLM
3. Genera un grafo consultable con visualizacion interactiva

**Instalacion (opcional):**
```bash
pipx install graphifyy
graphify install --platform opencode
```

**Uso diario (dentro del asistente):**
```
/graphify .                        # construir grafo del proyecto
/graphify query "que hace X"       # preguntar al grafo
/graphify path "A" "B"             # camino mas corto entre nodos
/graphify explain "Funcion"        # explicar un nodo
```

Graphify reduce hasta 71.5x el consumo de tokens vs leer archivos en bruto.

## Backup y restauracion

Nexo incluye un sistema de backup completo.

### Crear backup

```bash
# Backup completo
./backup/nexo-backup.sh

# Backup rapido
./backup/nexo-backup.sh --quick
```

### Restaurar Nexo

```bash
# Restaurar ultimo backup
./backup/nexo-restore.sh

# Restauracion completa
./backup/nexo-restore.sh --full
```

### Que se respalda

- Memoria y configuracion
- Scripts y herramientas
- Knowledge graph
- Configuracion de OpenCode

### Recuperacion rapida

Si algo falla, solo necesitas:

```bash
# Opcion 1: Restaurar desde backup
./backup/nexo-restore.sh --full

# Opcion 2: Clonar repo y reinstalar
git clone https://github.com/Mikutabby/nexo-asistente.git
cd nexo-asistente
./install.sh
```

## Desinstalacion

Para eliminar Nexo de tu sistema:

```bash
# Eliminar scripts
rm -rf ~/.local/bin/check-identity.sh ~/.local/bin/temp-monitor.sh ~/.local/bin/temp-cancel.sh
rm -rf ~/.local/bin/nexo-* ~/.local/bin/limpiar ~/.local/bin/nexo-backup.sh ~/.local/bin/nexo-restore.sh

# Eliminar agente de OpenCode
rm -rf ~/.opencode/agents/asistente.md

# Eliminar memoria
rm -rf ~/.nexo-memory/

# Eliminar configuracion de sudoers
sudo rm /etc/sudoers.d/nexo-temp-monitor

# Eliminar servicios
sudo systemctl disable cpu-performance.service 2>/dev/null
sudo rm /etc/systemd/system/cpu-performance.service
```

## Licencia

MIT
