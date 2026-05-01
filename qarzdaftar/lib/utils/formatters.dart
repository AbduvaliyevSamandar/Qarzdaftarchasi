import 'package:intl/intl.dart';

import 'input_formatters.dart';

class Formatters {
  static final _date = DateFormat('dd.MM.yyyy');
  static final _dateTime = DateFormat('dd.MM.yyyy HH:mm');
  static final _timeOnly = DateFormat('HH:mm');

  static String money(num value) =>
      '${MoneyInputFormatter.formatAmount(value)} so\'m';
  static String date(DateTime d) => _date.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d);

  /// "Bugun 14:30", "Kecha 09:15", "3 kun oldin", "30.04.2026"
  static String humanDateTime(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;
    final time = _timeOnly.format(d);

    if (diff == 0) {
      final mins = now.difference(d).inMinutes;
      if (mins >= 0 && mins < 5) return 'Hozir';
      if (mins > 0 && mins < 60) return '$mins daqiqa oldin';
      final hours = now.difference(d).inHours;
      if (hours > 0 && hours < 6) return '$hours soat oldin';
      return 'Bugun $time';
    }
    if (diff == -1) return 'Kecha $time';
    if (diff == 1) return 'Ertaga $time';
    if (diff > -7 && diff < 0) return '${-diff} kun oldin';
    if (diff > 0 && diff < 7) return '$diff kundan keyin';
    return _dateTime.format(d);
  }

  static String humanDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Bugun';
    if (diff == -1) return 'Kecha';
    if (diff == 1) return 'Ertaga';
    if (diff > -7 && diff < 0) return '${-diff} kun oldin';
    if (diff > 0 && diff < 7) return '$diff kundan keyin';
    return _date.format(d);
  }

  static String relativeDays(DateTime d) => humanDate(d);
}
