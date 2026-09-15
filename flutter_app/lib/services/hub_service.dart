import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_notification.dart';

class HubService {
  static const String keyHubUrl = 'firebase_url';
  static const String keyChannel = 'channel_name';

  // URL directa de Firebase Realtime Database
  static const String defaultFirebaseUrl = 'https://yape-pagos-td-default-rtdb.firebaseio.com';
  static const String defaultChannel = 'tienda_principal';

  String firebaseUrl = defaultFirebaseUrl;
  String channel = defaultChannel;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    firebaseUrl = prefs.getString(keyHubUrl) ?? defaultFirebaseUrl;
    channel = prefs.getString(keyChannel) ?? defaultChannel;
  }

  Future<void> updateConfig({required String newUrl, required String newChannel}) async {
    firebaseUrl = newUrl.trim().replaceAll(RegExp(r'/+$'), '').replaceAll('/pagos.json', '');
    channel = newChannel.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyHubUrl, firebaseUrl);
    await prefs.setString(keyChannel, channel);
  }

  /// Envía un pago directo a Firebase Realtime Database (Vía 4G/5G/Wi-Fi mundial)
  Future<bool> sendPayment(PaymentNotification payment) async {
    final cleanBase = firebaseUrl.replaceAll(RegExp(r'/+$'), '');
    final endpoint = Uri.parse('$cleanBase/pagos.json');

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
