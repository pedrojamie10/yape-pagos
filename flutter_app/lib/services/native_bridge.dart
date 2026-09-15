import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.yape.sync/notifications');

  /// Verifica si el permiso de NotificationListenerService está concedido
  static Future<bool> isNotificationListenerEnabled() async {
    try {
      final bool? enabled = await _channel.invokeMethod('isNotificationListenerEnabled');
      return enabled ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Abre la pantalla de Ajustes de Android para activar el acceso a notificaciones
  static Future<void> openNotificationListenerSettings() async {
    try {
      await _channel.invokeMethod('openNotificationListenerSettings');
    } on PlatformException catch (e) {
      print("Error abriendo ajustes: ${e.message}");
    }
  }

  /// Abre la pantalla de configuración de batería para ignorar optimizaciones
  static Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } on PlatformException catch (e) {
      print("Error solicitando optimización de batería: ${e.message}");
    }
  }

  /// Establece el listener de notificaciones entrantes desde Android Kotlin hacia Flutter
  static void setNotificationHandler(Function(Map<String, dynamic>) handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNotificationReceived') {
        final Map<String, dynamic> data = Map<String, dynamic>.from(call.arguments);
        handler(data);
      }
    });
  }
}
