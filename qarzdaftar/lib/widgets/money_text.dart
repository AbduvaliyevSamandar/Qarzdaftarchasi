import 'package:flutter/material.dart';

import '../utils/input_formatters.dart';

class MoneyText extends StatelessWidget {
  const MoneyText({
    super.key,
    required this.amount,
    this.currency = 'so\'m',
    this.size = 16,
    this.color,
    this.bold = true,
    this.signed = false,
    this.signPositive = '+',
    this.signNegative = '−',
  });

  final num amount;
  final String currency;
  final double size;
  final Color? color;
  final bool bold;
  final bool signed;
  final String signPositive;
  final String signNegative;

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? DefaultTextStyle.of(context).style.color;
    final value = amount.toInt().abs();
    final formatted = MoneyInputFormatter.formatAmount(value);
    final sign = signed
        ? (amount >= 0 ? signPositive : signNegative)
        : '';

    return RichText(
      text: TextSpan(
        children: [
          if (sign.isNotEmpty)
            TextSpan(
              text: sign,
              style: TextStyle(
                color: defaultColor,
                fontSize: size,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                height: 1.1,
              ),
            ),
          TextSpan(
            text: formatted,
            style: TextStyle(
              color: defaultColor,
              fontSize: size,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              height: 1.1,
              letterSpacing: -0.3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          TextSpan(
            text: ' $currency',
            style: TextStyle(
              color: defaultColor?.withValues(alpha: 0.65),
              fontSize: size * 0.6,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
