class TransactionModel {
  final String id;
  final dynamic userId; // Map<String, dynamic> if populated, else String
  final String collegeId;
  final String orderId;
  final String paymentId;
  final double amount;
  final String currency;
  final String plan;
  final DateTime premiumUntil;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.collegeId,
    required this.orderId,
    required this.paymentId,
    required this.amount,
    required this.currency,
    required this.plan,
    required this.premiumUntil,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is String) return DateTime.parse(value);
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return TransactionModel(
      id: json['_id'] ?? '',
      userId: json['userId'],
      collegeId: json['collegeId'] ?? '',
      orderId: json['orderId'] ?? '',
      paymentId: json['paymentId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
      plan: json['plan'] ?? '',
      premiumUntil: parseDate(json['premiumUntil']),
      status: json['status'] ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'collegeId': collegeId,
      'orderId': orderId,
      'paymentId': paymentId,
      'amount': amount,
      'currency': currency,
      'plan': plan,
      'premiumUntil': premiumUntil.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get userName {
    if (userId is Map<String, dynamic>) {
      return (userId as Map<String, dynamic>)['fullName'] ?? 'Unknown User';
    }
    return 'User ID: $userId';
  }

  String get userEmail {
    if (userId is Map<String, dynamic>) {
      return (userId as Map<String, dynamic>)['email'] ?? '';
    }
    return '';
  }
}
