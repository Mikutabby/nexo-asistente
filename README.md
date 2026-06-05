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
│   └── nexo-wake      Deteccion de palabra de activacion
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
|---|---|---|
| Monitor temp | Apaga el PC si se sobrecalienta | `install.sh` (paso 5) |
| Voz TTS | Nexo habla por los parlantes | Automatico si instalas dependencias |
| Voz STT | Nexo escucha lo que decis | `voice.sh` con SpeechRecognition |
| Backup cifrado | Backup diario con GPG | `install.sh` (paso 6) |
| Wake word | Nexo escucha su nombre | `nexo-wake daemon start` |
| Knowledge graph | Memoria semantica | `install.sh` (paso 7) |

## Personalizacion

Nexo se adapta a vos con el tiempo, pero puedes acelerar el proceso:

- Contale tus preferencias directamente: "Nexo, prefiero que me hables en tono formal"
- Mostrale tus rutinas: usalo regularmente y aprendera tus horarios
- Pedile que recuerde cosas: "Nexo, recorda que mi contraseña de WiFi es X"
- Agregale herramientas: `nexo-tools add nombre descripcion comando`

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
