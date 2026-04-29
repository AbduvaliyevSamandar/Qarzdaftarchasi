import 'package:intl/intl.dart';

import 'input_formatters.dart';

class Formatters {
  static final _date = DateFormat('dd.MM.yyyy');
  static final _dateTime = DateFormat('dd.MM.yyyy HH:mm');

  static String money(num value) =>
      '${MoneyInputFormatter.formatAmount(value)} so\'m';
  static String date(DateTime d) => _date.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d);

  static String relativeDays(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Bugun';
    if (diff == 1) return 'Ertaga';
    if (diff == -1) return 'Kecha';
    if (diff > 0) return '$diff kundan keyin';
    return '${-diff} kun oldin';
  }
}
