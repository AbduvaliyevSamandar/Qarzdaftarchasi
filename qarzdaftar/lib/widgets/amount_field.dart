import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/input_formatters.dart';

class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.label = 'Summa (so\'m)',
    this.required = true,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final bool required;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        MoneyInputFormatter(),
      ],
      autofocus: autofocus,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: const Icon(Icons.payments_outlined),
        suffixText: 'so\'m',
      ),
      validator: required
          ? (v) {
              final amount = MoneyInputFormatter.parseAmount(v ?? '');
              if (amount == null || amount <= 0) return 'To\'g\'ri summa kiriting';
              return null;
            }
          : null,
    );
  }
}
