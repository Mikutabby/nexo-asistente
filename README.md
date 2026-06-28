# Nexo Asistente

Creado por **mikuyasha**. Un asistente autonomo de sistema Linux que se adapta a tu forma de usar la PC. Aprende de cada interaccion, automatiza tareas y gestiona tu ecosistema digital.

## Filosofia

Nexo no viene con datos precargados ni presupone quien sos. Al instalarse, te pregunta como quieres que te llame y comienza a aprender desde cero. Cada comando que ejecutas, cada preferencia que expresas, cada dispositivo que conectas se vuelve parte de su memoria.

Con el tiempo, Nexo:
- Reconoce tus patrones de uso
- Anticipa tus necesidades
- Automatiza tareas repetitivas
- Optimiza tu sistema basado en tus habitos

## Estructura del repositorio

```
nexo-asistente/
├── agent/             Archivo agente para OpenCode (personalidad de Nexo)
│   └── asistente.md
├── core/              Scripts esenciales del sistema
│   ├── identity/      Deteccion de usuario (check-identity.sh)
│   ├── monitor/       Monitoreo de temperatura (temp-monitor, temp-cancel)
│   └── system/        Utilidades (limpiar)
├── memory/            Sistema de memoria persistente
│   ├── nexo-graph     Knowledge graph con busqueda semantica
│   └── nexo-memory    Memoria persistente y auto-aprendizaje
├── voice/             Sistema de voz
│   ├── say.sh         Text-to-Speech (Piper, gTTS, espeak)
│   └── voice.sh       Speech-to-Text (Google Web Speech)
├── tools/             Herramientas auxiliares
│   ├── nexo-diary     Resumidor diario de interacciones
│   ├── nexo-evaluate  Evaluador de tareas
│   ├── nexo-tools     Registro de herramientas
│   ├── nexo-skill     Sistema de skills (plugins instalables)
│   ├── nexo-wake      Deteccion de palabra de activacion
│   ├── nexo-auto-model    Deteccion automatica de intencion
│   ├── nexo-smart-switch  Cambio automatico de modelos
│   ├── nexo-model         Atajos manuales de modelos
│   └── nexo-model-switch  Switch con deteccion de intencion
├── skills/            Skills preinstalados (sistema, web, ejemplo)
│   ├── ejemplo/       Skill template de ejemplo
│   ├── sistema/       Monitoreo del sistema (CPU, RAM, disco, temp)
│   └── web/           Herramientas web (IP publica, DNS, QR)
├── backup/            Backup y restore
│   ├── nexo-backup.sh Backup cifrado con GPG
│   └── nexo-restore.sh Restore de emergencia
├── config/            Ejemplos de configuracion
│   ├── cpu-performance.service
│   ├── sudoers.temp-monitor
│   ├── ollama.service
│   ├── crontab.example.txt
│   └── opencode.jsonc.example
├── install.sh         Instalador interactivo
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
| **Auto-Model** | **Cambio automatico de modelos IA** | **Automatico (incluido)** |

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

## Auto-Model Switching (Cambio automatico de modelos)

Nexo puede **cambiar automaticamente el modelo de IA** segun la tarea que le pidas. Esto optimiza calidad, velocidad y costo sin que hagas nada.

### Como funciona

1. Te mandas un mensaje (ej: "haceme un código serio de python")
2. Nexo detecta la intencion (coding)
3. Nexo cambia automaticamente al mejor modelo (Nemotron 3 Ultra, gratis)
4. Nexo te avisa brevemente del cambio
5. La siguiente respuesta usa el modelo optimizado

### Herramientas disponibles

```bash
# Deteccion automatica (Nexo lo hace solo)
nexo-auto-model "tu mensaje"           # Detecta intencion, devuelve JSON
nexo-smart-switch "tu mensaje"         # Cambia modelo si detecta mejor opcion

# Comandos manuales
nexo-model status                      # Ver modelo actual
nexo-model potencia                    # Claude Opus 4.8 ($5/$25, el mas inteligente)
nexo-model codigo                      # Nemotron 3 Ultra (gratis, coding fuerte)
nexo-model rapido                      # DeepSeek V4 Flash (gratis, el mas rapido)
nexo-model smart                       # Claude Haiku 4.5 ($0.80/$4, rapido + barato)
nexo-model default                     # MiMo V2.5 (gratis, multimodal)
nexo-model restore                     # Volver al modelo anterior
nexo-model log                         # Ver historial de cambios
```

### Intenciones detectadas

| Intencion | Palabras clave | Modelo | Costo |
|-----------|----------------|--------|-------|
| **potencia** | potencia, inteligente, analiza, complejo | Claude Opus 4.8 | $5/$25 |
| **coding** | código, programa, debug, API | Nemotron 3 Ultra | Gratis |
| **rapido** | rápido, urgente, ya, dale | DeepSeek V4 Flash | Gratis |
| **multimodal** | imagen, foto, video, mirá | MiMo V2.5 | Gratis |
| **creativo** | escribe, email, historia, blog | Claude Haiku 4.5 | $0.80/$4 |
| **matematicas** | matemática, cálculo, fórmula | DeepSeek V4 Pro | $1.74/$3.84 |
| **sistema** | sistema, servidor, instalar | MiMo V2.5 | Gratis |
| **casual** | hola, qué tal, gracias | MiMo V2.5 | Gratis |

### Filtros de informacion

Los scripts incluyen filtros para:
- **Palabras clave en español e inglés** (deteccion bilingue)
- **Patrones de intencion** (regex optimizados)
- **Excepciones** (no cambiar si ya estas en el modelo correcto)
- **Logging** (registro de todos los cambios para auditoria)

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

```bash
# Backup completo (cifrado con GPG)
nexo-backup.sh

# Restaurar desde backup
nexo-restore.sh
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
