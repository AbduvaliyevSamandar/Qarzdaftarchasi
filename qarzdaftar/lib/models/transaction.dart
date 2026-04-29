enum TxnType { debt, payment }

class Txn {
  final String id;
  final String customerId;
  final TxnType type;
  final double amount;
  final String? productName;
  final String? note;
  final DateTime occurredAt;
  final DateTime? dueDate;
  final DateTime createdAt;

  const Txn({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    this.productName,
    this.note,
    required this.occurredAt,
    this.dueDate,
    required this.createdAt,
  });

  bool get isOverdue =>
      type == TxnType.debt &&
      dueDate != null &&
      DateTime.now().isAfter(dueDate!);

  Map<String, dynamic> toMap() => {
        'id': id,
        'customer_id': customerId,
        'type': type.name,
        'amount': amount,
        'product_name': productName,
        'note': note,
        'occurred_at': occurredAt.toIso8601String(),
        'due_date': dueDate?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory Txn.fromMap(Map<String, dynamic> m) => Txn(
        id: m['id'] as String,
        customerId: m['customer_id'] as String,
        type: TxnType.values.firstWhere((e) => e.name == m['type']),
        amount: (m['amount'] as num).toDouble(),
        productName: m['product_name'] as String?,
        note: m['note'] as String?,
        occurredAt: DateTime.parse(m['occurred_at'] as String),
        dueDate: m['due_date'] != null
            ? DateTime.parse(m['due_date'] as String)
            : null,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
