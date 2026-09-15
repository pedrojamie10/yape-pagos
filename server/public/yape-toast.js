/**
 * YapeToast - Conexión Directa a Firebase Realtime Database
 * Funciona en CUALQUIER celular o red (4G/5G/Wi-Fi) sin servidores propios.
 */
(function () {
  if (window.__YAPE_TOAST_INITIALIZED__) return;
  window.__YAPE_TOAST_INITIALIZED__ = true;

  const currentScript = document.currentScript || document.querySelector('script[src*="yape-toast.js"]');
  const firebaseUrl = (currentScript && currentScript.getAttribute('data-firebase')) || 
                      'https://yape-pagos-td-default-rtdb.firebaseio.com';
  const position = (currentScript && currentScript.getAttribute('data-position')) || 'bottom-right';
  const enableSound = (currentScript && currentScript.getAttribute('data-sound')) !== 'false';
  
  const channel = (currentScript && currentScript.getAttribute('data-channel')) || 'mi_tienda_01';
  const filterClienteId = (currentScript && currentScript.getAttribute('data-cliente-id')) || null;
  const filterUsuarioId = (currentScript && currentScript.getAttribute('data-usuario-id')) || null;

  // Limpiar URL base y apuntar al canal del negocio
  const cleanBaseUrl = firebaseUrl.replace(/\/+$/, '').replace(/\.json$/, '');
  const sseUrl = `${cleanBaseUrl}/negocios/${channel}/pagos.json`;

  // Estilos CSS
  const styleEl = document.createElement('style');
  styleEl.textContent = `
    #yape-toast-container {
      position: fixed;
      z-index: 9999999;
      display: flex;
      flex-direction: column;
      gap: 14px;
      pointer-events: none;
      max-width: 400px;
      width: calc(100vw - 32px);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    }
    #yape-toast-container.bottom-right { bottom: 24px; right: 24px; }
    #yape-toast-container.bottom-left { bottom: 24px; left: 24px; }
    #yape-toast-container.top-right { top: 24px; right: 24px; }
    #yape-toast-container.top-left { top: 24px; left: 24px; }

    .yape-toast-card {
      pointer-events: auto;
      background: linear-gradient(145deg, #241433 0%, #150c20 100%);
      color: #ffffff;
      border-radius: 18px;
      padding: 16px 18px 12px 18px;
      box-shadow: 0 16px 40px rgba(0, 0, 0, 0.4), 0 0 0 1px rgba(116, 34, 132, 0.35);
      border: 1px solid rgba(255, 255, 255, 0.08);
      display: flex;
      flex-direction: column;
      gap: 12px;
      animation: yapeSlideIn 0.35s cubic-bezier(0.16, 1, 0.3, 1) forwards;
      transition: transform 0.2s ease, opacity 0.2s ease;
      position: relative;
      overflow: hidden;
    }
    .yape-toast-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 20px 48px rgba(0, 0, 0, 0.5), 0 0 0 1.5px rgba(0, 208, 156, 0.5);
    }
    .yape-toast-card.plin {
      background: linear-gradient(145deg, #0f2438 0%, #07121c 100%);
      box-shadow: 0 16px 40px rgba(0, 0, 0, 0.4), 0 0 0 1px rgba(0, 163, 224, 0.35);
    }
    .yape-toast-card.closing {
      animation: yapeSlideOut 0.3s ease forwards;
    }

    .yape-toast-body {
      display: flex;
      align-items: center;
      gap: 14px;
    }

    .yape-toast-icon {
      width: 48px;
      height: 48px;
      border-radius: 14px;
      background: linear-gradient(135deg, #742284, #9B30B4);
      color: #fff;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      font-weight: 800;
      font-size: 22px;
      box-shadow: 0 6px 16px rgba(116, 34, 132, 0.45);
    }
    .yape-toast-card.plin .yape-toast-icon {
      background: linear-gradient(135deg, #00A3E0, #0077A3);
      box-shadow: 0 6px 16px rgba(0, 163, 224, 0.45);
    }

    .yape-toast-info {
      flex: 1;
      min-width: 0;
    }
    .yape-toast-meta {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 2px;
    }
    .yape-toast-badge {
      font-size: 11px;
      font-weight: 800;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      background: #00D09C;
      color: #063124;
      padding: 2px 8px;
      border-radius: 6px;
    }
    .yape-toast-time {
      font-size: 11px;
      color: rgba(255, 255, 255, 0.5);
    }
    .yape-toast-amount {
      font-size: 26px;
      font-weight: 900;
      letter-spacing: -0.5px;
      color: #00FFBE;
      line-height: 1.15;
    }
    .yape-toast-sender {
      font-size: 13px;
      color: rgba(255, 255, 255, 0.88);
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      margin-top: 2px;
    }

    .yape-toast-close {
      background: transparent;
      border: none;
      color: rgba(255, 255, 255, 0.4);
      font-size: 20px;
      line-height: 1;
      padding: 4px 8px;
      cursor: pointer;
      position: absolute;
      top: 10px;
      right: 10px;
      border-radius: 6px;
    }
    .yape-toast-close:hover {
      color: #ffffff;
      background: rgba(255, 255, 255, 0.1);
    }

    .yape-toast-progress {
      position: absolute;
      bottom: 0;
      left: 0;
      height: 3px;
      background: #00D09C;
      width: 100%;
      transform-origin: left;
      animation: yapeProgress 9s linear forwards;
    }

    @keyframes yapeProgress {
      from { transform: scaleX(1); }
      to { transform: scaleX(0); }
    }
    @keyframes yapeSlideIn {
      from { opacity: 0; transform: translateY(24px) scale(0.92); }
      to { opacity: 1; transform: translateY(0) scale(1); }
    }
    @keyframes yapeSlideOut {
      from { opacity: 1; transform: translateY(0) scale(1); }
      to { opacity: 0; transform: translateY(16px) scale(0.92); }
    }
  `;
  document.head.appendChild(styleEl);

  let container = document.getElementById('yape-toast-container');
  if (!container) {
    container = document.createElement('div');
    container.id = 'yape-toast-container';
    container.className = position;
    document.body.appendChild(container);
  }

  function playCashSound() {
    if (!enableSound) return;
    try {
      const AudioContext = window.AudioContext || window.webkitAudioContext;
      if (!AudioContext) return;
      const ctx = new AudioContext();
      const now = ctx.currentTime;
      const osc1 = ctx.createOscillator();
      const osc2 = ctx.createOscillator();
      const gain = ctx.createGain();

      osc1.type = 'sine';
      osc1.frequency.setValueAtTime(587.33, now);
      osc1.frequency.exponentialRampToValueAtTime(880, now + 0.08);

      osc2.type = 'triangle';
      osc2.frequency.setValueAtTime(1174.66, now + 0.06);

      gain.gain.setValueAtTime(0.25, now);
      gain.gain.exponentialRampToValueAtTime(0.01, now + 0.5);

      osc1.connect(gain);
      osc2.connect(gain);
      gain.connect(ctx.destination);

      osc1.start(now);
      osc2.start(now + 0.06);
      osc1.stop(now + 0.5);
      osc2.stop(now + 0.5);
    } catch (e) {}
  }

  function showToast(payment) {
    if (filterClienteId && payment.clienteId && payment.clienteId !== filterClienteId) return;
    if (filterUsuarioId && payment.usuarioId && payment.usuarioId !== filterUsuarioId) return;

    playCashSound();

    const card = document.createElement('div');
    const isPlin = (payment.app || '').toLowerCase().includes('plin');
    card.className = `yape-toast-card ${isPlin ? 'plin' : ''}`;

    const timeStr = new Date(payment.timestamp || Date.now()).toLocaleTimeString([], { 
      hour: '2-digit', 
      minute: '2-digit', 
      hour12: true 
    });

    const formatted = payment.formattedAmount || `S/ ${(parseFloat(payment.amount) || 0).toFixed(2)}`;

    card.innerHTML = `
      <div class="yape-toast-body">
        <div class="yape-toast-icon">${isPlin ? 'P' : 'Y'}</div>
        <div class="yape-toast-info">
          <div class="yape-toast-meta">
            <span class="yape-toast-badge">¡${payment.app || 'Yape'} Confirmado!</span>
            <span class="yape-toast-time">${timeStr}</span>
          </div>
          <div class="yape-toast-amount">${formatted}</div>
          <div class="yape-toast-sender">De: <strong>${payment.sender || 'Cliente'}</strong></div>
        </div>
      </div>
      <button class="yape-toast-close" title="Cerrar">&times;</button>
      <div class="yape-toast-progress"></div>
    `;

    const closeBtn = card.querySelector('.yape-toast-close');
    closeBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      dismissCard(card);
    });

    const timeout = setTimeout(() => dismissCard(card), 9000);

    card.addEventListener('mouseenter', () => {
      const p = card.querySelector('.yape-toast-progress');
      if (p) p.style.animationPlayState = 'paused';
    });

    card.addEventListener('mouseleave', () => {
      const p = card.querySelector('.yape-toast-progress');
      if (p) p.style.animationPlayState = 'running';
    });

    container.appendChild(card);
    window.dispatchEvent(new CustomEvent('yape:payment', { detail: payment }));
  }

  function dismissCard(card) {
    if (card.classList.contains('closing')) return;
    card.classList.add('closing');
    setTimeout(() => {
      if (card.parentElement) card.parentElement.removeChild(card);
    }, 300);
  }

  // Conexión nativa a Firebase Realtime Database mediante Server-Sent Events (SSE)
  let eventSource = null;
  let isInitialLoad = true;

  function connectFirebase() {
    try {
      eventSource = new EventSource(sseUrl);

      eventSource.addEventListener('put', function (e) {
        try {
          const res = JSON.parse(e.data);
          // Si es la carga inicial de toda la base de datos
          if (res.path === '/') {
            isInitialLoad = false;
            return;
          }
          // Si es un nuevo pago agregado
          if (res.data && (res.data.amount || res.data.rawText)) {
            let payment = res.data;
            if (!payment.formattedAmount && payment.amount) {
              payment.formattedAmount = `S/ ${(parseFloat(payment.amount) || 0).toFixed(2)}`;
            }
            showToast(payment);
          }
        } catch (err) {
          console.error('[YapeToast Firebase] Error procesando evento:', err);
        }
      });

      eventSource.onopen = function () {
        console.log('[YapeToast] Conectado a Firebase Realtime Database en tiempo real.');
        window.dispatchEvent(new CustomEvent('yape:firebase_connected'));
      };

      eventSource.onerror = function () {
        // EventSource de navegadores reintenta automáticamente la conexión
      };
    } catch (e) {
      console.error('[YapeToast] Error inicializando EventSource Firebase:', e);
    }
  }

  connectFirebase();

  // API pública
  window.YapeToast = {
    show: showToast,
    simulate: async function (amount = 25.0, sender = 'Juan Perez') {
      const paymentData = {
        app: 'Yape',
        amount: parseFloat(amount),
        formattedAmount: `S/ ${parseFloat(amount).toFixed(2)}`,
        sender: sender,
        timestamp: new Date().toISOString()
      };
      // Enviar directamente a Firebase en la sala del negocio
      try {
        await fetch(`${cleanBaseUrl}/negocios/${channel}/pagos.json`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(paymentData)
        });
      } catch(e) {
        showToast(paymentData);
      }
    }
  };
})();
