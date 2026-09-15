const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const cors = require('cors');
const path = require('path');
const { parseYapeNotification } = require('./parser');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server, path: '/ws' });

const PORT = process.env.PORT || 3000;
const DEFAULT_CHANNEL = process.env.DEFAULT_CHANNEL || 'tienda_principal';

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, '../public')));

// Estado en memoria
const channels = new Map(); // channelName -> Set<WebSocket>
const paymentHistory = []; // Almacena los últimos 200 pagos
const MAX_HISTORY = 200;

// Helper para obtener o crear un canal
function getChannelClients(channelName) {
  if (!channels.has(channelName)) {
    channels.set(channelName, new Set());
  }
  return channels.get(channelName);
}

// Retransmisión WebSocket a un canal
function broadcastToChannel(channelName, data) {
  const clients = getChannelClients(channelName);
  const payload = JSON.stringify(data);
  let count = 0;
  for (const client of clients) {
    if (client.readyState === WebSocket.OPEN) {
      client.send(payload);
      count++;
    }
  }
  console.log(`[WebSocket] Transmitido a ${count} cliente(s) en canal "${channelName}":`, data.type);
  return count;
}

// WebSocket Connection Handler
wss.on('connection', (ws, req) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const channel = url.searchParams.get('channel') || DEFAULT_CHANNEL;
  const clientType = url.searchParams.get('type') || 'generic';

  ws.channel = channel;
  ws.clientType = clientType;

  const channelClients = getChannelClients(channel);
  channelClients.add(ws);

  console.log(`[WebSocket] Nuevo cliente conectado (${clientType}) en canal: "${channel}". Total en canal: ${channelClients.size}`);

  // Enviar mensaje de bienvenida con el estado inicial y los últimos 10 pagos del canal
  const channelHistory = paymentHistory
    .filter(p => p.channel === channel)
    .slice(-10);

  ws.send(JSON.stringify({
    type: 'CONNECTION_ESTABLISHED',
    channel,
    clientType,
    history: channelHistory,
    stats: getTodayStats(channel)
  }));

  ws.on('message', (message) => {
    try {
      const parsed = JSON.parse(message);
      if (parsed.type === 'PING') {
        ws.send(JSON.stringify({ type: 'PONG', timestamp: Date.now() }));
      }
    } catch (e) {
      // Mensaje no JSON, ignorar
    }
  });

  ws.on('close', () => {
    channelClients.delete(ws);
    console.log(`[WebSocket] Cliente desconectado de canal: "${channel}". Restantes: ${channelClients.size}`);
  });

  ws.on('error', (err) => {
    console.error('[WebSocket] Error en cliente:', err.message);
  });
});

// Estadísticas del día
function getTodayStats(channel) {
  const todayStr = new Date().toISOString().split('T')[0];
  const todayPayments = paymentHistory.filter(p => 
    (!channel || p.channel === channel) && 
    p.timestamp.startsWith(todayStr)
  );

  const totalAmount = todayPayments.reduce((acc, p) => acc + (p.amount || 0), 0);
  return {
    date: todayStr,
    count: todayPayments.length,
    totalAmount: Math.round(totalAmount * 100) / 100,
    formattedTotal: `S/ ${totalAmount.toFixed(2)}`
  };
}

// REST Endpoints
app.get('/health', (req, res) => {
  let totalClients = 0;
  channels.forEach(set => totalClients += set.size);
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    totalConnectedClients: totalClients,
    totalPaymentsLogged: paymentHistory.length
  });
});

// Registrar un pago (llamado por la app Flutter emisora o por el simulador)
app.post('/api/payments', (req, res) => {
  const channel = req.body.channel || DEFAULT_CHANNEL;
  let paymentData;

  // Si envía texto crudo de notificación (desde el NotificationListener de Android)
  if (req.body.rawTitle || req.body.rawText) {
    paymentData = parseYapeNotification(
      req.body.rawTitle || '',
      req.body.rawText || '',
      req.body.packageName || 'com.bcp.innovacxion.yapeapp'
    );
  } else {
    // Si envía los datos ya parseados
    paymentData = {
      id: req.body.id || ('pay_' + Date.now() + '_' + Math.random().toString(36).substring(2, 7)),
      app: req.body.app || 'Yape',
      amount: parseFloat(req.body.amount) || 0,
      currency: req.body.currency || 'PEN',
      formattedAmount: req.body.formattedAmount || `S/ ${(parseFloat(req.body.amount) || 0).toFixed(2)}`,
      sender: req.body.sender || 'Cliente',
      clienteId: req.body.clienteId || req.body.cliente_id || null,
      usuarioId: req.body.usuarioId || req.body.usuario_id || null,
      orderId: req.body.orderId || req.body.order_id || null,
      rawTitle: req.body.rawTitle || '¡Te yapearon!',
      rawText: req.body.rawText || `Te yapearon S/ ${req.body.amount} de ${req.body.sender}`,
      isPayment: true,
      timestamp: req.body.timestamp || new Date().toISOString()
    };
  }

  // Si vino en el body genérico
  if (req.body.clienteId || req.body.cliente_id) paymentData.clienteId = req.body.clienteId || req.body.cliente_id;
  if (req.body.usuarioId || req.body.usuario_id) paymentData.usuarioId = req.body.usuarioId || req.body.usuario_id;
  if (req.body.orderId || req.body.order_id) paymentData.orderId = req.body.orderId || req.body.order_id;

  paymentData.channel = channel;

  // Guardar en historial
  paymentHistory.push(paymentData);
  if (paymentHistory.length > MAX_HISTORY) {
    paymentHistory.shift();
  }

  console.log(`[PAGO RECIBIDO] Canal: ${channel} | Monto: ${paymentData.formattedAmount} | De: ${paymentData.sender} (${paymentData.app})`);

  // Retransmitir al instante por WebSockets a todos los clientes (Toasts, Móviles, PCs)
  const broadcastCount = broadcastToChannel(channel, {
    type: 'PAYMENT_RECEIVED',
    payment: paymentData,
    stats: getTodayStats(channel)
  });

  return res.status(201).json({
    success: true,
    message: 'Pago procesado y retransmitido en tiempo real',
    broadcastTo: broadcastCount,
    payment: paymentData
  });
});

// Obtener historial de pagos
app.get('/api/payments', (req, res) => {
  const channel = req.query.channel || DEFAULT_CHANNEL;
  const limit = parseInt(req.query.limit, 10) || 50;
  const filtered = paymentHistory
    .filter(p => !channel || p.channel === channel)
    .slice(-limit)
    .reverse();

  res.json({
    success: true,
    channel,
    stats: getTodayStats(channel),
    payments: filtered
  });
});

// Limpiar historial (para pruebas)
app.delete('/api/payments', (req, res) => {
  paymentHistory.length = 0;
  res.json({ success: true, message: 'Historial de pagos limpiado' });
});

// Iniciar servidor
server.listen(PORT, '0.0.0.0', () => {
  console.log(`====================================================`);
  console.log(`🚀 HUB DE NOTIFICACIONES YAPE EN TIEMPO REAL`);
  console.log(`📡 Servidor HTTP corriendo en: http://localhost:${PORT}`);
  console.log(`⚡ WebSocket escuchando en: ws://localhost:${PORT}/ws`);
  console.log(`🖥️  Dashboard web de pruebas: http://localhost:${PORT}/index.html`);
  console.log(`====================================================`);
});
