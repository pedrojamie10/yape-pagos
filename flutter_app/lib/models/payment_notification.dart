class PaymentNotification {
  final String id;
  final String app;
  final double amount;
  final String formattedAmount;
  final String sender;
  final String rawTitle;
  final String rawText;
  final DateTime timestamp;
  final bool isSynced;

  PaymentNotification({
    required this.id,
    required this.app,
    required this.amount,
    required this.formattedAmount,
    required this.sender,
    required this.rawTitle,
    required this.rawText,
    required this.timestamp,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson({String? channel}) {
    return {
      'id': id,
      'app': app,
      'amount': amount,
      'formattedAmount': formattedAmount,
      'sender': sender,
      'rawTitle': rawTitle,
      'rawText': rawText,
      'timestamp': timestamp.toIso8601String(),
      if (channel != null) 'channel': channel,
    };
  }

  factory PaymentNotification.fromJson(Map<String, dynamic> json) {
    return PaymentNotification(
      id: json['id'] ?? '',
      app: json['app'] ?? 'Yape',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      formattedAmount: json['formattedAmount'] ?? 'S/ 0.00',
      sender: json['sender'] ?? 'Cliente',
      rawTitle: json['rawTitle'] ?? '',
      rawText: json['rawText'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      isSynced: json['isSynced'] ?? false,
    );
  }

  PaymentNotification copyWith({bool? isSynced}) {
    return PaymentNotification(
      id: id,
      app: app,
      amount: amount,
      formattedAmount: formattedAmount,
      sender: sender,
      rawTitle: rawTitle,
      rawText: rawText,
      timestamp: timestamp,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
