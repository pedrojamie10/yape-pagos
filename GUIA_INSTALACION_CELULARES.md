# Guía Paso a Paso: Instalación en Celulares (Emisor y Receptores)

---

## 📱 PARTE 1: Instalación en Celulares Receptores (Cajeros / Pantallas)
*Compatible con cualquier celular: Android o iPhone.*

No necesitas compilar APKs ni configurar Android Studio en los celulares de tus empleados o cajeros. Se instala en **5 segundos**:

### Paso 1: Conectar al mismo Wi-Fi
Asegúrate de que el celular del cajero esté conectado a la misma red Wi-Fi que la computadora donde corre el Hub (o tu servidor en la nube).

### Paso 2: Abrir el enlace o escanear el QR
En el celular del receptor abre Chrome o Safari e ingresa a:
> **`http://192.168.0.168:3000/mobile.html`**
*(O escanea el código QR que aparece en la pantalla de tu computadora en `http://localhost:3000`)*.

### Paso 3: Instalar como App Nativa
* **En Android (Google Chrome):**
  1. Toca los 3 puntos verticales arriba a la derecha.
  2. Selecciona **"Instalar aplicación"** o **"Agregar a la pantalla principal"**.
* **En iPhone (Safari):**
  1. Toca el botón de Compartir (el ícono del cuadrado con flecha hacia arriba).
  2. Selecciona **"Agregar al inicio"**.

### ¡Listo!
Aparecerá el ícono de **Yape Receptor** en el menú de aplicaciones de ese celular. Al abrirlo:
* Funciona a pantalla completa como una app nativa.
* Suena y muestra el Toast gigante cada vez que entra un pago.
* Permite activar el botón **"Mantener Pantalla Encendida"** para dejarlo fijo en el mostrador de caja.

---

## 📲 PARTE 2: Instalación en el Celular Emisor (El Android con Yape)
*El celular donde recibes los pagos de Yape debe ser Android para permitir la lectura de notificaciones.*

Tienes **3 opciones** para tenerlo funcionando:

### Opción A (Recomendada si usas GitHub - Sin instalar nada en tu PC):
Ya dejamos configurado el archivo [`.github/workflows/build-apk.yml`](file:///d:/sistemas/yape/.github/workflows/build-apk.yml).
1. Si subes esta carpeta a un repositorio de GitHub (puede ser privado).
2. GitHub compilará el APK en la nube de forma gratuita en 2 minutos.
3. En la pestaña **Actions** descargas el archivo **`app-release.apk`**, lo envías a tu celular (por WhatsApp o cable) y lo instalas.

---

### Opción B (Compilar localmente en tu PC con Flutter):
Si prefieres generar el `.apk` directamente en tu computadora:
1. Instala Flutter en Windows abriendo PowerShell como Administrador:
   ```powershell
   winget install Flutter.Flutter
   ```
2. Cierra y vuelve a abrir PowerShell. Ve a la carpeta de la app:
   ```powershell
   cd d:\sistemas\yape\flutter_app
   flutter pub get
   flutter build apk --release
   ```
3. El archivo listo para instalar estará en:
   `d:\sistemas\yape\flutter_app\build\app\outputs\flutter-apk\app-release.apk`
4. Cópialo a tu celular e instálalo.

---

### Opción C (Probar de inmediato HOY en 2 minutos sin compilar nada):
Si quieres probar con tu Yape real **en este instante** sin esperar a compilar el APK de Flutter:
1. En tu celular Android con Yape, instala la app gratuita **MacroDroid** desde la Google Play Store.
2. Creas una macro simple de 2 pasos:
   * **Disparador (Trigger):** Notificación > Notificación Recibida > Seleccionar app: **Yape**.
   * **Acción:** Conectividad > Solicitud HTTP > Método: **POST** > URL:
     `http://192.168.0.168:3000/api/payments`
     Contenido del body (JSON):
     ```json
     {
       "rawTitle": "[not_title]",
       "rawText": "[not_body]",
       "channel": "tienda_principal"
     }
     ```
3. Cada vez que Yape emita una notificación, MacroDroid la reenviará automáticamente al Hub en milisegundos y saltará el Toast en tus otros celulares y sistemas.

---

### Configuración requerida en el Celular Emisor tras instalar:
1. Abre la app en el celular con Yape.
2. Presiona **"ACTIVAR"** en *Acceso a Notificaciones* y concede el permiso a la app.
3. Desactiva el *Ahorro de Batería* para esa app (para que Android no la suspenda cuando apagues la pantalla).
4. Configura la IP de tu servidor: `http://192.168.0.168:3000` y el canal: `tienda_principal`.
