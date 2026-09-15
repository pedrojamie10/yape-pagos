import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_notification.dart';

class HubService {
  static const String keyHubUrl = 'firebase_url';
  static const String keyChannel = 'channel_name';

  static const String defaultFirebaseUrl = 'https://yape-pagos-td-default-rtdb.firebaseio.com';
  static const String defaultChannel = 'mi_tienda_01';

  String firebaseUrl = defaultFirebaseUrl;
  String channel = defaultChannel;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    firebaseUrl = prefs.getString(keyHubUrl) ?? defaultFirebaseUrl;
    channel = prefs.getString(keyChannel) ?? defaultChannel;
  }

  Future<void> updateChannel(String newChannel) async {
    final clean = newChannel.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    channel = clean.isEmpty ? defaultChannel : clean;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyChannel, channel);
  }

  /// Envía un pago a la carpeta específica de este negocio en Firebase
  Future<bool> sendPayment(PaymentNotification payment) async {
    final cleanBase = firebaseUrl.replaceAll(RegExp(r'/+$'), '');
    final endpoint = Uri.parse('$cleanBase/negocios/$channel/pagos.json');

    try {
      final response = await http.post(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': payment.id,
          'app': payment.app,
          'amount': payment.amount,
          'formattedAmount': payment.formattedAmount,
          'sender': payment.sender,
          'rawTitle': payment.rawTitle,
          'rawText': payment.rawText,
          'channel': channel,
          'timestamp': payment.timestamp.toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene los últimos pagos del canal/negocio específico
  Future<List<PaymentNotification>> fetchPayments() async {
    final cleanBase = firebaseUrl.replaceAll(RegExp(r'/+$'), '');
    final endpoint = Uri.parse('$cleanBase/negocios/$channel/pagos.json?orderBy="\$key"&limitToLast=15');

    try {
      final res = await http.get(endpoint).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && res.body != 'null') {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final List<PaymentNotification> list = [];
        data.forEach((k, v) {
          if (v is Map<String, dynamic>) {
            list.add(PaymentNotification.fromJson(v));
          }
        });
        return list.reversed.toList();
      }
    } catch (_) {}
    return [];
  }

  /// Verifica si Firebase responde
  Future<bool> checkConnection() async {
    try {
      final cleanBase = firebaseUrl.replaceAll(RegExp(r'/+$'), '');
      final endpoint = Uri.parse('$cleanBase/.json?shallow=true');
      final response = await http.get(endpoint).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
