import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'models/payment_notification.dart';
import 'services/yape_parser.dart';
import 'services/hub_service.dart';
import 'services/native_bridge.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const YapeApp());
}

class YapeApp extends StatelessWidget {
  const YapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yape Sync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF742284),
          brightness: Brightness.light,
          primary: const Color(0xFF742284),
          secondary: const Color(0xFF00D09C),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0E17),
        cardColor: const Color(0xFF1B1926),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9B30B4),
          secondary: Color(0xFF00D09C),
          surface: Color(0xFF1B1926),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}

enum AppRole { emisor, receptor }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final HubService _hubService = HubService();
  AppRole _currentRole = AppRole.emisor;
  
  bool _hasNotificationPermission = false;
  bool _isFirebaseConnected = false;
  final List<PaymentNotification> _payments = [];
  Timer? _receiverPollingTimer;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  @override
  void dispose() {
    _receiverPollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initApp() async {
    await _hubService.init();
    await _checkStatus();

    // Configurar listener para cuando este teléfono actúa de EMISOR
    NativeBridge.setNotificationHandler((data) async {
      if (_currentRole != AppRole.emisor) return;

      final title = data['title']?.toString() ?? '';
      final text = data['text']?.toString() ?? '';
      final pkg = data['package']?.toString() ?? 'com.bcp.innovacxion.yapeapp';

      final payment = YapeParser.parse(
        title: title,
        text: text,
        packageName: pkg,
      );

      if (payment != null) {
        final synced = await _hubService.sendPayment(payment);
        setState(() {
          _payments.insert(0, payment.copyWith(isSynced: synced));
        });
        if (synced) {
          HapticFeedback.mediumImpact();
        }
      }
    });

    // Iniciar escucha en tiempo real de Firebase si es RECEPTOR
    _startReceiverSync();
  }

  Future<void> _checkStatus() async {
    final permission = await NativeBridge.isNotificationListenerEnabled();
    final connected = await _hubService.checkConnection();
    setState(() {
      _hasNotificationPermission = permission;
      _isFirebaseConnected = connected;
    });
  }

  // Sincronizador en tiempo real con Firebase para el modo Receptor
  void _startReceiverSync() {
    _receiverPollingTimer?.cancel();
    // Consulta periódica ligera a Firebase para actualizar nuevos cobros
    _receiverPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_currentRole != AppRole.receptor) return;
      await _fetchFirebasePayments();
    });
  }

  Future<void> _fetchFirebasePayments() async {
    try {
      final cleanBase = _hubService.firebaseUrl.replaceAll(RegExp(r'/+$'), '');
      final res = await http.get(
        Uri.parse('$cleanBase/pagos.json?orderBy="\$key"&limitToLast=10'),
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200 && res.body != 'null') {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final List<PaymentNotification> remotePayments = [];

        data.forEach((key, val) {
          if (val is Map<String, dynamic>) {
            final payment = PaymentNotification.fromJson(val);
            remotePayments.add(payment);
          }
        });

        // Detectar si hay pagos nuevos que no teníamos
        for (final p in remotePayments.reversed) {
          final alreadyExists = _payments.any((item) => item.id == p.id || (item.amount == p.amount && item.sender == p.sender));
          if (!alreadyExists) {
            setState(() {
              _payments.insert(0, p.copyWith(isSynced: true));
            });
            // Alerta sensorial en el receptor
            HapticFeedback.heavyImpact();
            _showIncomingPaymentAlert(p);
          }
        }
      }
    } catch (_) {}
  }

  void _showIncomingPaymentAlert(PaymentNotification p) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: const Color(0xFF00D09C),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF0D3B2F)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡${p.app} Recibido! ${p.formattedAmount} de ${p.sender}',
                style: const TextStyle(color: Color(0xFF0D3B2F), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _simulatePayment() async {
    final payment = PaymentNotification(
      id: 'sim_${DateTime.now().millisecondsSinceEpoch}',
      app: 'Yape',
      amount: 30.00,
      formattedAmount: 'S/ 30.00',
      sender: 'Carlos Rodriguez',
      rawTitle: '¡Te yapearon!',
      rawText: 'S/ 30.00 de Carlos Rodriguez',
      timestamp: DateTime.now(),
    );

    final synced = await _hubService.sendPayment(payment);
    setState(() {
      _payments.insert(0, payment.copyWith(isSynced: synced));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(synced 
          ? '✅ Pago guardado en Firebase en la nube' 
          : '⚠️ Error enviando a Firebase (Revisar conexión a internet)'),
        backgroundColor: synced ? const Color(0xFF00D09C) : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _payments.fold(0.0, (acc, item) => acc + item.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFF742284),
              radius: 16,
              child: Text('Y', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            SizedBox(width: 10),
            Text('Yape Sync', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkStatus();
              if (_currentRole == AppRole.receptor) _fetchFirebasePayments();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Selector de Rol (Emisor vs Receptor)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                    onTap: () => setState(() => _currentRole = AppRole.emisor),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentRole == AppRole.emisor ? const Color(0xFF742284) : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                      ),
                      child: Center(
                        child: Text(
                          '📲 Celular Emisor\n(Tiene Yape)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _currentRole == AppRole.emisor ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
                    onTap: () {
                      setState(() => _currentRole = AppRole.receptor);
                      _fetchFirebasePayments();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentRole == AppRole.receptor ? const Color(0xFF00D09C) : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
                      ),
                      child: Center(
                        child: Text(
                          '🔔 Celular Receptor\n(Cajero / Pantalla)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _currentRole == AppRole.receptor ? const Color(0xFF0D3B2F) : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Estado del Emisor o Receptor
          if (_currentRole == AppRole.emisor)
            _buildEmisorCard()
          else
            _buildReceptorCard(),

          const SizedBox(height: 16),

          // Tarjeta de Resumen
          _buildSummaryCard(totalAmount),
          const SizedBox(height: 16),

          // Botón de Prueba
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF742284),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _simulatePayment,
            icon: const Icon(Icons.send_rounded),
            label: const Text('Probar Notificación de Pago', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),

          // Lista de Cobros
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentRole == AppRole.emisor ? 'Cobros Leídos de Yape' : 'Cobros Recibidos en Vivo',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text('${_payments.length} registros', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),

          if (_payments.isEmpty)
            Container(
              padding: const EdgeInsets.all(36),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _currentRole == AppRole.emisor
                    ? 'Esperando que llegue un Yape a este celular...\nCualquier notificación se enviará automáticamente a Firebase.'
                    : 'Modo Receptor Activo.\nCualquier pago que entre en el celular con Yape sonará aquí en tiempo real.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, height: 1.4),
              ),
            )
          else
            ..._payments.map((p) => _buildPaymentItem(p)),
        ],
      ),
    );
  }

  Widget _buildEmisorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _hasNotificationPermission ? Icons.check_circle : Icons.warning_amber_rounded,
                color: _hasNotificationPermission ? const Color(0xFF00D09C) : Colors.amber,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _hasNotificationPermission 
                    ? 'Lector de Yape: ACTIVO' 
                    : 'Permiso de Notificaciones: PENDIENTE',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              if (!_hasNotificationPermission)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D09C),
                    foregroundColor: const Color(0xFF0D3B2F),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: NativeBridge.openNotificationListenerSettings,
                  child: const Text('ACTIVAR', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const Divider(height: 20, color: Colors.white10),
          Row(
            children: [
              const Icon(Icons.cloud_done, color: Color(0xFF00D09C)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Conectado a Firebase en la Nube (4G/5G/Wi-Fi)',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceptorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00D09C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00D09C).withOpacity(0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.notifications_active, color: Color(0xFF00D09C), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo Cajero / Receptor Activo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF00D09C)),
                ),
                Text(
                  'Escuchando pagos de Yape en tiempo real desde la nube.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF742284), Color(0xFF4D1259)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Recaudado', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            'S/ ${total.toStringAsFixed(2)}',
            style: const TextStyle(color: Color(0xFF00D09C), fontSize: 32, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(PaymentNotification payment) {
    final timeStr = DateFormat('hh:mm a').format(payment.timestamp);
    final isPlin = payment.app.toLowerCase().contains('plin');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isPlin ? const Color(0xFF00A3E0) : const Color(0xFF742284),
            radius: 20,
            child: Text(isPlin ? 'P' : 'Y', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.sender, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${payment.app} • $timeStr', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                payment.formattedAmount,
                style: const TextStyle(color: Color(0xFF00D09C), fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 2),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_done, size: 13, color: Color(0xFF00D09C)),
                  SizedBox(width: 4),
                  Text('Firebase', style: TextStyle(fontSize: 10, color: Color(0xFF00D09C))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
