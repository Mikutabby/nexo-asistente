# Guía Completa: LineageOS 20 para Redmi 10 2022 (selene)

## ⚠️ ADVERTENCIAS IMPORTANTES

**LEER ANTES DE CONTINUAR:**
- **TODO SE BORRARÁ** - Haz backup de TODO antes de empezar
- **SE PIERDE LA GARANTÍA** - Ya la perdiste al desbloquear bootloader
- **RIESGO DE BRICK** - Si sigues la guía correctamente, el riesgo es bajo
- **BATERÍA 70%+** - El teléfono debe tener carga suficiente
- **CABLE USB BUENO** - Usa el original o uno de calidad
- **apps BANCARIAS** - No funcionarán (SafetyNet roto)
- **Google Pay** - No funcionará

**EL AUTOR NO SE HACE RESPONSABLE POR DAÑOS.**

---

## 📱 Tu Dispositivo

| Dato | Valor |
|------|-------|
| Modelo | Redmi 10 2022 (21121119VL) |
| Código | selene |
| SoC | MediaTek Helio G88 (MT6769H) |
| Android | 12 (MIUI 13) |
| Bootloader | ✅ Desbloqueado |
| Particiones | A/B (dual boot) |
| Architecture | arm64-v8a |

---

## 📋 Requisitos

### Hardware
- PC con Linux (ya tienes)
- Cable USB original o de buena calidad
- Batería del teléfono al 70%+
- MicroSD (recomendado)

### Software
```bash
# Instalar herramientas necesarias
sudo apt install android-tools-adb android-tools-fastboot git python3 python3-pip unzip wget
```

---

## 📥 Archivos Necesarios

### 1. LineageOS 20 para selene
- **Fuente**: github.com/jzadl/selenerom
- **Alternativa**: SourceForge builds de hasan6034

### 2. TWRP Recovery para selene
- **Opción A**: halabtech.com (TWRP MIUI14 OS13.zip - 34MB)
- **Opción B**: androidfilehost.com (twrp-3.6.0_11-0-selene_2.img - 64MB)
- **Opción C**: OrangeFox Recovery (alternativa a TWRP)

### 3. GApps (Google Apps)
- **OpenGApps**: opengapps.org (ARM64, Android 13, Pico o Nano)

### 4. Magisk (opcional, para root)
- **GitHub**: github.com/topjohnwu/Magisk/releases

---

## 🔧 PASO 1: Preparar el Teléfono

### 1.1 Activar Depuración USB
```
Settings > About phone > Tap "MIUI Version" 7 times
Settings > Additional settings > Developer options
Enable "USB debugging"
Enable "OEM unlocking" (ya debería estar activo)
```

### 1.2 Verificar Bootloader Desbloqueado
```bash
adb reboot bootloader
fastboot getvar unlocked
# Debe mostrar: unlocked: yes
fastboot reboot
```

### 1.3 Hacer Backup Completo
```bash
# Backup de apps y datos
adb backup -apk -shared -all -f ~/backup-redmi10-$(date +%Y%m%d).ab

# Backup de IMEI (importante)
adb shell su -c "cat /proc/device-tree/nvdata/nvram" > ~/imei-backup.txt
```

---

## 🔧 PASO 2: Descargar Archivos

### 2.1 Crear Directorio de Trabajo
```bash
mkdir -p ~/redmi-selene
cd ~/redmi-selene
```

### 2.2 Descargar LineageOS
```bash
# Opción 1: Usar el script descargador
git clone https://github.com/jzadl/selenerom.git
cd selenerom
chmod +x selene_downloader.sh
./selene_downloader.sh

# Opción 2: Descarga manual
# Buscar "LineageOS selene" en SourceForge
```

### 2.3 Descargar TWRP
```bash
# Opción A: Desde halabtech (recomendado)
wget -O twrp-selene.zip "https://support.halabtech.com/index.php?a=downloads&b=file&id=811396"

# Opción B: Desde androidfilehost
wget -O twrp-selene.img "https://androidfilehost.com/?fid=14871746926876849150"

# Opción C: OrangeFox Recovery
wget -O orangeFox-selene.img "https://androidfilehost.com/?fid=14871746926876849153"
```

### 2.4 Descargar GApps
```bash
# Para Android 13, ARM64
wget -O gapps-arm64-13.zip "https://github.com/nicholaschum/opengapps/releases/download/13/pico/pico-20231017-arm64-13.0.zip"
```

### 2.5 Descargar Magisk (opcional)
```bash
wget -O magisk.apk "https://github.com/topjohnwu/Magisk/releases/download/v27.0/Magisk-v27.0.apk"
```

---

## 🔧 PASO 3: Instalar TWRP Recovery

### Método 1: Usando mtkclient (recomendado para MediaTek)
```bash
# Instalar mtkclient
git clone https://github.com/bkerler/mtkclient.git
cd mtkclient
pip3 install -r requirements.txt
sudo cp Setup/Linux/*.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules

# Desbloquear bootloader (si no está desbloqueado)
python3 mtk e metadata,userdata,md_udc

# Flash TWRP
# Apagar el teléfono completamente
# Conectar USB mientras mantienes Vol+ y/o Vol-
python3 mtk w boot_a ~/redmi-selene/twrp-selene.img
python3 mtk w boot_b ~/redmi-selene/twrp-selene.img
```

### Método 2: Usando Fastboot
```bash
cd ~/redmi-selene

# Reiniciar en bootloader
adb reboot bootloader

# Flash TWRP en ambos slots
fastboot flash boot_a twrp-selene.img
fastboot flash boot_b twrp-selene.img

# Reiniciar a recovery
fastboot reboot recovery
```

### Verificar TWRP
```bash
# El teléfono debería estar en TWRP Recovery
# Si pide contraseña, significa que /data está encriptado
# Seleccionar "Cancel" y luego "Format Data" (esto borra todo)
```

---

## 🔧 PASO 4: Flash LineageOS

### Desde TWRP:
1. **Backup primero** (recomendado)
   - Wipe > Advanced Wipe
   - Seleccionar: Dalvik, Cache, System, Data
   - Swipe to Wipe

2. **Instalar LineageOS**
   - Install > Seleccionar archivo zip de LineageOS
   - Swipe to Confirm Flash
   - Esperar a que termine

3. **Instalar GApps** (opcional)
   - Install > Seleccionar gapps zip
   - Swipe to Confirm Flash

4. **Reiniciar**
   - Reboot System
   - Primera vez puede tardar 5-10 minutos

### Desde PC (método alternativo):
```bash
# Reiniciar a recovery
adb reboot recovery

# Sideload LineageOS
adb sideload lineage-selene.zip

# Sideload GApps
adb sideload gapps-arm64-13.zip
```

---

## 🔧 PASO 5: Configuración Inicial

### 5.1 Wizard de Inicio
- Seleccionar idioma
- Conectar a WiFi
- Iniciar sesión con Google (si instalaste GApps)
- Configurar PIN/huella

### 5.2 Verificar Instalación
```
Settings > About phone
- Debe mostrar LineageOS 20
- Android 13
- Security patch actual
```

### 5.3 Configurar para Gaming
```
Settings > Battery
- Battery saver: OFF
- Adaptive battery: OFF

Settings > Developer options
- Window animation scale: 0.5x
- Transition animation scale: 0.5x
- Animator duration scale: 0.5x
- Background process limit: 2
```

---

## 🔧 PASO 6: Root con Magisk (Opcional)

### 6.1 Preparar
```bash
# Extraer boot.img de LineageOS
unzip lineage-selene.zip boot.img
```

### 6.2 Transferir al Teléfono
```bash
adb push boot.img /sdcard/
adb push magisk.apk /sdcard/
```

### 6.3 En el Teléfono
1. Instalar Magisk APK
2. Abrir Magisk
3. Seleccionar "Install" > "Select and Patch a File"
4. Seleccionar boot.img
5. Magisk creará magisk_patched.img

### 6.4 Flash Magisk
```bash
# Copiar archivo parchado
adb pull /sdcard/Download/magisk_patched_*.img ~/redmi-selene/

# Reiniciar a bootloader
adb reboot bootloader

# Flash
fastboot flash boot_a magisk_patched_*.img
fastboot flash boot_b magisk_patched_*.img
fastboot reboot
```

---

## 🔧 SOLUCIÓN DE PROBLEMAS

### No arranca después de flash
```
1. Reiniciar a TWRP (Vol+ + Power)
2. Flash el boot.img original de MIUI
3. Reiniciar
```

### WiFi/Bluetooth no funciona
```
1. Reiniciar a TWRP
2. Flash kernel custom (Yukina Stamine)
3. Reiniciar
```

### Pantalla negra
```
1. Reiniciar a TWRP
2. Wipe > Format Data
3. Flash LineageOS de nuevo
4. Reiniciar
```

### Bootloop en logo
```
1. Reiniciar a TWRP
2. Wipe > Dalvik/Cache/System/Data
3. Flash LineageOS + GApps
4. Reiniciar
```

---

## 📚 Recursos

| Recurso | Link |
|---------|------|
| Guía GitHub | github.com/jzadl/selenerom |
| Telegram Community | t.me/Redmi10_Community |
| XDA Forums | xdaforums.com/tags/selene/ |
| TWRP selene | halabtech.com (Redmi 10 2022) |
| LineageOS Downloads | sourceforge.net/projects/redmi-10-selene/ |

---

## ✅ Verificación Final

Después de instalar, verifica:
- [ ] LineageOS arranca correctamente
- [ ] WiFi funciona
- [ ] Bluetooth funciona
- [ ] Cámaras funcionan
- [ ] GPS funciona
- [ ] Sensores funcionan
- [ ] Juegos funcionan (COD Mobile)
- [ ] No hay bootloops

---

## 🎮 Optimización para Gaming

Una vez instalado LineageOS:

```bash
# Ejecutar optimizador desde PC
./optimizar-lineageos.sh
```

### Configuración en COD Mobile:
1. Graphics Quality: **LOW**
2. Frame Rate: **HIGH**
3. Depth of Field: **OFF**
4. Real-Time Shadows: **OFF**
5. Anti-Aliasing: **OFF**

---

## 📞 Soporte

Si tienes problemas:
1. Busca en XDA Forums: xdaforums.com/tags/selene/
2. Pregunta en Telegram: t.me/Redmi10_Community
3. Busca errores específicos en Google

---

## 🔄 Volver a MIUI (si es necesario)

Si algo sale mal y quieres volver a MIUI:

```bash
# Descargar MIUI Global ROM para selene
wget -O miui-selene.zip "https://xiaomirom.com/en/download/redmi-10-10-2022-10-prime-selene-stable-V13.0.16.0.SKUMIXM/"

# Reiniciar a recovery
adb reboot recovery

# Flash MIUI
adb sideload miui-selene.zip

# O usar SP Flash Tool con Fastboot ROM
```

---

**¡Buena suerte! 🎉**
