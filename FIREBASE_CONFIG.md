# Configuración Firebase Realtime Database para Yape

Tu base de datos en tiempo real de Firebase ya está **100% activa y vinculada**:
* **URL de la Base de Datos:** `https://yape-pagos-td-default-rtdb.firebaseio.com`
* **Colección de Pagos:** `https://yape-pagos-td-default-rtdb.firebaseio.com/pagos.json`

---

## 📲 1. Celular Emisor (El Android con Yape)

Cada vez que recibes un Yape, la app envía un HTTP POST directamente a Google Firebase. Funciona con datos móviles 4G/5G de Claro, Movistar, Entel o cualquier Wi-Fi.

### Método Rápido con MacroDroid (Sin compilar nada):
1. Instala **MacroDroid** desde Google Play Store.
2. Crea una Macro con:
   * **Disparador:** *Notificación* > *Notificación recibida* > App: **Yape**.
   * **Acción:** *Conectividad* > *Solicitud HTTP*
     - Método: **POST**
     - URL: `https://yape-pagos-td-default-rtdb.firebaseio.com/pagos.json`
     - Tipo de contenido: `application/json`
     - Cuerpo del mensaje:
       ```json
       {
         "app": "Yape",
         "rawTitle": "[not_title]",
         "rawText": "[not_body]",
         "timestamp": "[year]-[month_digit]-[day_digit]T[hour_24]:[minute]:[second]Z"
       }
       ```

---

## 📱 2. Celulares Receptores (Cajeros con sus propios datos móviles)

Cualquier celular en cualquier red abre el archivo `mobile.html`:
* Se conecta en tiempo real a Firebase.
* Al recibir el pago, reproduce sonido de caja o voz ("Yape recibido de S/ ...") y muestra el Toast gigante.

---

## 🛒 3. Integración en tu Sistema (In-App Toast)

En cualquier sistema web que tengas, pega:
```html
<script src="/yape-toast.js" data-firebase="https://yape-pagos-td-default-rtdb.firebaseio.com"></script>
```
Cada vez que entre un Yape, se dibujará un Toast flotante directamente en la pantalla de tu sistema.
