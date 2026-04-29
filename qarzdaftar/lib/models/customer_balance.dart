import 'customer.dart';

class CustomerBalance {
  final Customer customer;
  final double totalDebt;
  final double totalPaid;
  final DateTime? lastTxnAt;
  final DateTime? earliestOverdueDueDate;

  const CustomerBalance({
    required this.customer,
    required this.totalDebt,
    required this.totalPaid,
    this.lastTxnAt,
    this.earliestOverdueDueDate,
  });

  double get remaining => totalDebt - totalPaid;
  bool get hasOverdue => earliestOverdueDueDate != null;
}
