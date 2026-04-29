import 'package:flutter/services.dart';

class UzbPhoneInputFormatter extends TextInputFormatter {
  static const String prefix = '+998 ';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var raw = newValue.text;
    if (raw.startsWith(prefix)) {
      raw = raw.substring(prefix.length);
    } else if (raw.startsWith('+998')) {
      raw = raw.substring(4);
    } else if (raw.startsWith('998')) {
      raw = raw.substring(3);
    }

    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final clipped = digits.length > 9 ? digits.substring(0, 9) : digits;

    final buf = StringBuffer();
    for (var i = 0; i < clipped.length; i++) {
      if (i == 2 || i == 5 || i == 7) buf.write(' ');
      buf.write(clipped[i]);
    }
    final formatted = '$prefix${buf.toString()}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String? toE164(String formatted) {
    final digits = formatted.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 12) return null;
    return '+$digits';
  }

  static String fromE164(String? phone) {
    if (phone == null || phone.isEmpty) return prefix;
    var raw = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.startsWith('998')) raw = raw.substring(3);
    final clipped = raw.length > 9 ? raw.substring(0, 9) : raw;
    final buf = StringBuffer();
    for (var i = 0; i < clipped.length; i++) {
      if (i == 2 || i == 5 || i == 7) buf.write(' ');
      buf.write(clipped[i]);
    }
    return '$prefix${buf.toString()}';
  }
}

class MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = _groupThousands(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _groupThousands(String digits) {
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      if (i > 0 && fromEnd % 3 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  static double? parseAmount(String formatted) {
    final digits = formatted.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }

  static String formatAmount(num value) {
    final digits = value.toInt().toString();
    return _groupThousands(digits);
  }
}
