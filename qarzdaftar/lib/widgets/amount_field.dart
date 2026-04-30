import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/input_formatters.dart';
import 'calculator_dialog.dart';

class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.label = 'Summa (so\'m)',
    this.required = true,
    this.autofocus = false,
    this.showCalculator = true,
  });

  final TextEditingController controller;
  final String label;
  final bool required;
  final bool autofocus;
  final bool showCalculator;

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
        suffixIcon: showCalculator
            ? IconButton(
                icon: const Icon(Icons.calculate_outlined),
                tooltip: 'Kalkulyator',
                onPressed: () async {
                  final current = MoneyInputFormatter.parseAmount(controller.text);
                  final result = await CalculatorDialog.show(
                    context: context,
                    initialAmount: current,
                  );
                  if (result != null) {
                    controller.text =
                        MoneyInputFormatter.formatAmount(result.toInt());
                  }
                },
              )
            : null,
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
