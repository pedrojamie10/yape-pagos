/**
 * Cliente de Escritorio para Windows - Yape Realtime Toaster
 * Conecta con el Hub WebSocket y despliega Toasts nativos en la pantalla de Windows.
 */
const WebSocket = require('ws');
const { execFile } = require('child_process');
const path = require('path');

const HUB_URL = process.env.HUB_WS_URL || 'ws://localhost:3000/ws';
const CHANNEL = process.env.CHANNEL || 'tienda_principal';
const PS_SCRIPT = path.join(__dirname, 'show-toast.ps1');

console.clear();
console.log('===========================================================');
console.log('   🔔 RECEPTOR WINDOWS TOAST - NOTIFICACIONES YAPE/PLIN   ');
console.log('===========================================================');
console.log(`Conectando a: ${HUB_URL}`);
console.log(`Canal de Tienda: ${CHANNEL}`);
console.log('Esperando pagos en tiempo real...');
console.log('Minimiza esta ventana y sigue trabajando en tu sistema POS.');
console.log('-----------------------------------------------------------');

function showWindowsToast(payment) {
  const title = `¡${payment.app || 'Yape'} Recibido! ${payment.formattedAmount || ('S/ ' + payment.amount)}`;
  const sender = payment.sender || 'Cliente';
  const app = payment.app || 'Yape';

  execFile('powershell', [
    '-ExecutionPolicy', 'Bypass',
    '-File', PS_SCRIPT,
    '-Title', title,
    '-Sender', sender,
    '-App', app
  ], (err, stdout, stderr) => {
    if (err) {
      console.error('[Error al mostrar Toast de Windows]:', err.message);
    } else {
      console.log(`[TOAST MOSTRADO] ${title} de ${sender}`);
    }
  });
}

let ws = null;
let reconnectTimer = null;

function connect() {
  const fullUrl = `${HUB_URL}?channel=${encodeURIComponent(CHANNEL)}&type=windows-desktop`;
  ws = new WebSocket(fullUrl);

  ws.on('open', () => {
    console.log(`\n🟢 [EN VIVO] Conectado al Hub. Las alertas aparecerán como Toasts en tu pantalla.`);
  });

  ws.on('message', (data) => {
    try {
      const msg = JSON.parse(data);
      if (msg.type === 'PAYMENT_RECEIVED' && msg.payment) {
        console.log(`\n💰 ¡PAGO DETECTADO! ${msg.payment.formattedAmount} de ${msg.payment.sender} (${msg.payment.app})`);
        showWindowsToast(msg.payment);
      }
    } catch (e) {
      // Ignorar mensajes no JSON
    }
  });

  ws.on('close', () => {
    console.log(`\n🔴 Conexión cerrada con el servidor. Reintentando en 3 segundos...`);
    clearTimeout(reconnectTimer);
    reconnectTimer = setTimeout(connect, 3000);
  });

  ws.on('error', (err) => {
    console.log(`⚠️ Error de red (${err.code || err.message}). Reintentando...`);
  });
}

connect();
