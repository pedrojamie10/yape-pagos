# Sistema de Notificaciones Yape en Tiempo Real (Hub + Flutter + Windows Toasts)

Este proyecto permite capturar notificaciones de **Yape** (y **Plin**) desde un teléfono celular Android emisor y retransmitirlas en **milisegundos** a:
1. **Otros celulares (Android / iOS):** Mediante la app móvil o el panel web responsive con sonido.
2. **Computadoras Windows (Caja / Facturación):** Mediante **Toasts nativos de Windows 10/11** en la esquina de la pantalla sobre cualquier software que uses.
3. **Cualquier sistema web existente:** Mediante una sola línea de código JavaScript.

---

## 📁 Estructura del Proyecto

```
d:\sistemas\yape\
├── server/                 # Hub central (Node.js + WebSockets + Dashboard)
│   ├── src/
│   │   ├── index.js        # Servidor HTTP y WebSockets
│   │   └── parser.js       # Parser inteligente de notificaciones
│   ├── public/
│   │   ├── index.html      # Dashboard en vivo + Simulador interactivo
│   │   ├── yape-toast.js   # Script universal para inyectar Toasts en cualquier web
│   │   └── test-integration.html # Ejemplo de POS integrado con Toast
│   └── tests/
│       └── test-hub.js     # Pruebas automatizadas de parsing
├── windows_client/         # Cliente de escritorio para Windows (Toast nativo)
│   ├── client.js           # Escucha WebSockets y lanza Toasts
│   ├── show-toast.ps1      # Disparador nativo de Windows Runtime Toast
│   └── iniciar_notificador_windows.bat
├── flutter_app/            # App móvil para el celular emisor (Android)
│   ├── lib/                # Código Flutter (Material 3)
│   └── android/            # Servicio nativo Kotlin (NotificationListenerService)
├── iniciar_servidor_hub.bat
└── iniciar_receptor_windows.bat
```

---

## 🚀 Inicio Rápido (En 3 Pasos)

### Paso 1: Iniciar el Servidor Hub
Haz doble clic en `iniciar_servidor_hub.bat` (o ejecuta en terminal):
```bash
cd d:\sistemas\yape\server
npm start
```
El servidor abrirá en:
* **Dashboard y Monitor en vivo:** `http://localhost:3000`
* **Ejemplo de integración POS:** `http://localhost:3000/test-integration.html`

### Paso 2: Iniciar el Notificador Toast en tu PC con Windows
Haz doble clic en `iniciar_receptor_windows.bat` (o ejecuta en terminal):
```bash
cd d:\sistemas\yape\windows_client
node client.js
```
*Cada vez que entre un Yape, Windows mostrará la notificación oficial en la esquina inferior derecha con sonido de caja, sin interrumpir lo que estés haciendo.*

### Paso 3: Probar el flujo instantáneo
Entra a `http://localhost:3000` en tu navegador y haz clic en **"⚡ Emitir Pago Instantáneo"**.
Verás:
1. El Toast nativo de Windows en tu pantalla.
2. El Toast flotante web en el dashboard.
3. El sonido de cobro exitoso.
4. El contador de total del día incrementándose en tiempo real.

---

## 📱 Celular Emisor (App Flutter + Android Nativo)

La app móvil en `flutter_app/` contiene el servicio en segundo plano `YapeNotificationListenerService.kt`:
1. Instala el APK en el celular donde recibes los Yapes.
2. Al abrir la app por primera vez, presiona **"ACTIVAR"** para otorgar el permiso de lectura de notificaciones en Ajustes de Android.
3. Ingresa la IP de tu computadora/servidor (ej. `http://192.168.1.50:3000`) o tu URL en la nube.
4. ¡Listo! Cualquier notificación de Yape recibida será leída y distribuida automáticamente a todos tus dispositivos.

---

## 🌐 ¿Cómo integrar el Toast en cualquier sistema que ya tengas?

Pega esta única línea en el HTML de tu sistema de ventas, facturación o software web:
```html
<script src="http://IP_DE_TU_SERVIDOR:3000/yape-toast.js" data-channel="tienda_principal" data-sound="true"></script>
```

Si deseas que tu sistema ejecute alguna acción automática (como marcar una orden como pagada):
```javascript
window.addEventListener('yape:payment', function(event) {
  const pago = event.detail;
  console.log("Monto:", pago.amount);
  console.log("Cliente:", pago.sender);
  console.log("Hora:", pago.timestamp);
});
```
