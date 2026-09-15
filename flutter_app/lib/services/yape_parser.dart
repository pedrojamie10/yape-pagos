import '../models/payment_notification.dart';

class YapeParser {
  /// Parsea el título y texto capturado de la notificación de Android
  static PaymentNotification? parse({
    required String title,
    required String text,
    String packageName = 'com.bcp.innovacxion.yapeapp',
  }) {
    final cleanTitle = title.replaceAll(RegExp(r'^(yape|plin|notificaci[oó]n|alerta)\s*[:\-]?\s*', caseSensitive: false), '').trim();
    final cleanText = text.replaceAll(RegExp(r'^(yape|plin|notificaci[oó]n|alerta)\s*[:\-]?\s*', caseSensitive: false), '').trim();
    final combined = '$cleanTitle $cleanText'.trim();

    // Regex para montos: S/ 10.00, S/10.00, S/. 10.00, Soles 10.00
    final amountRegex = RegExp(r'(?:S\/\.?\s*|Soles\s*)(\d+(?:[.,]\d{1,2})?)', caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(combined);

    double amount = 0.0;
    if (amountMatch != null) {
      final rawAmountStr = amountMatch.group(1)!.replaceAll(',', '.');
      amount = double.tryParse(rawAmountStr) ?? 0.0;
    }

    if (amount <= 0 && !combined.toLowerCase().contains('yape') && !combined.toLowerCase().contains('te yapearon')) {
      return null;
    }

    // Extracción de remitente
    String sender = 'Cliente';
    final senderPatterns = [
      RegExp(r'(?:de\s+)([A-ZÁÉÍÓÚÑa-záéíóúñ\s.]+?)(?:\s+(?:con|por|en|v[ií]a)|\s*$|\.|\!)', caseSensitive: false),
      RegExp(r'(?:^|\b)([A-ZÁÉÍÓÚÑa-záéíóúñ\s]{3,}?)\s+te\s+(?:envi[oó]|yape[oó])', caseSensitive: false),
      RegExp(r'(?:te\s+yape[oó]\s+)([A-ZÁÉÍÓÚÑa-záéíóúñ\s.]+?)(?:\s+S\/|\s*$)', caseSensitive: false),
    ];

    final targets = [cleanText, combined];
    bool found = false;

    for (final target in targets) {
      if (found) break;
      for (final pattern in senderPatterns) {
        final match = pattern.firstMatch(target);
        if (match != null && match.group(1) != null) {
          final candidate = match.group(1)!.trim();
          final lower = candidate.toLowerCase();
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

    String app = 'Yape';
    if (packageName.toLowerCase().contains('plin') || combined.toLowerCase().contains('plin')) {
      app = 'Plin';
    }

    return PaymentNotification(
      id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
      app: app,
      amount: amount,
      formattedAmount: 'S/ ${amount.toStringAsFixed(2)}',
      sender: sender,
      rawTitle: title,
      rawText: text,
      timestamp: DateTime.now(),
      isSynced: false,
    );
  }
}

extension StringUtils on String {
  bool includes(String query) => toLowerCase().contains(query.toLowerCase());
}
