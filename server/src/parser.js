/**
 * Parser inteligente de notificaciones de Yape (y Plin opcional)
 */
function parseYapeNotification(title = '', text = '', packageName = '') {
  // Limpiar títulos genéricos para no ensuciar la extracción
  const cleanTitle = title.replace(/^(yape|plin|notificaci[oó]n|alerta)\s*[:\-]?\s*/i, '').trim();
  const cleanText = text.replace(/^(yape|plin|notificaci[oó]n|alerta)\s*[:\-]?\s*/i, '').trim();
  const combined = `${cleanTitle} ${cleanText}`.trim();
  
  // Expresión regular para capturar montos en soles: S/ 10.00, S/10.00, S/ 10, S/. 10.00
  const amountRegex = /(?:S\/\.?\s*|Soles\s*)(\d+(?:[.,]\d{1,2})?)/i;
  const amountMatch = combined.match(amountRegex);
  
  let amount = 0;
  let rawAmount = '';
  if (amountMatch) {
    rawAmount = amountMatch[1].replace(',', '.');
    amount = parseFloat(rawAmount);
  }

  // Extracción del remitente (nombre de quien pagó)
  let sender = 'Cliente';
  
  // Patrones comunes de Yape:
  // 1. "S/ 15.00 de Juan Perez" o "¡Te yapearon! S/ 15.00 de Juan Perez"
  // 2. "Juan Carlos Quispe te envió S/ 45.50"
  // 3. "Te yapeó Juan Perez S/ 20.00"
  // 4. "Recibiste S/ 30.00 de Maria Elena con Plin"
  const senderPatterns = [
    /(?:de\s+)([A-ZÁÉÍÓÚÑa-záéíóúñ\s.]+?)(?:\s+(?:con|por|en|v[ií]a)|\s*$|\.|\!)/i,
    /(?:^|\b)([A-ZÁÉÍÓÚÑa-záéíóúñ\s]{3,}?)\s+te\s+(?:envi[oó]|yape[oó])/i,
    /(?:te\s+yape[oó]\s+)([A-ZÁÉÍÓÚÑa-záéíóúñ\s.]+?)(?:\s+S\/|\s*$)/i
  ];

  // Probar primero en text, luego en combined
  const targets = [cleanText, combined];
  let found = false;

  for (const target of targets) {
    if (found) break;
    for (const pattern of senderPatterns) {
      const match = target.match(pattern);
      if (match && match[1]) {
        const candidate = match[1].trim();
        // Verificar que no sea palabra del sistema
        const lower = candidate.toLowerCase();
        if (!lower.includes('yape') && 
            !lower.includes('bcp') &&
            !lower.includes('plin') &&
            candidate.length >= 3) {
          sender = candidate;
          found = true;
          break;
        }
      }
    }
  }

  // Detección de origen de la app
  let app = 'Yape';
  if (packageName.toLowerCase().includes('plin') || 
      title.toLowerCase().includes('plin') || 
      text.toLowerCase().includes('plin')) {
    app = 'Plin';
  }

  const isPayment = amount > 0 || combined.toLowerCase().includes('yape') || combined.toLowerCase().includes('te yapearon');

  return {
    id: 'pay_' + Date.now() + '_' + Math.random().toString(36).substring(2, 7),
    app,
    amount,
    currency: 'PEN',
    formattedAmount: `S/ ${amount.toFixed(2)}`,
    sender,
    rawTitle: title,
    rawText: text,
    isPayment,
    timestamp: new Date().toISOString()
  };
}

module.exports = {
  parseYapeNotification
};
