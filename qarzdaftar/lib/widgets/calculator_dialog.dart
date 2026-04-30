import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/input_formatters.dart';

class CalculatorDialog extends StatefulWidget {
  const CalculatorDialog({super.key, this.initialAmount});

  final double? initialAmount;

  static Future<double?> show({
    required BuildContext context,
    double? initialAmount,
  }) {
    return showDialog<double>(
      context: context,
      builder: (_) => CalculatorDialog(initialAmount: initialAmount),
    );
  }

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _expression = '';
  double? _result;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _expression = widget.initialAmount!.toInt().toString();
      _result = widget.initialAmount;
    }
  }

  void _press(String token) {
    setState(() {
      if (token == 'C') {
        _expression = '';
        _result = null;
        return;
      }
      if (token == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
        _evaluate();
        return;
      }
      if (token == '=') {
        _evaluate();
        return;
      }
      if ('+-×÷'.contains(token)) {
        if (_expression.isEmpty) return;
        final last = _expression.characters.last;
        if ('+-×÷'.contains(last)) {
          _expression = _expression.substring(0, _expression.length - 1) + token;
        } else {
          _expression += token;
        }
      } else {
        _expression += token;
      }
      _evaluate();
    });
  }

  void _evaluate() {
    if (_expression.isEmpty) {
      _result = null;
      return;
    }
    try {
      final cleaned = _expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/');
      final r = _evaluateSimple(cleaned);
      _result = r;
    } catch (_) {
      _result = null;
    }
  }

  // Simple left-to-right evaluator with precedence: * /, then + -.
  double? _evaluateSimple(String expr) {
    final tokens = <String>[];
    final buf = StringBuffer();
    for (var i = 0; i < expr.length; i++) {
      final c = expr[i];
      if ('+-*/'.contains(c)) {
        if (buf.isEmpty) return null;
        tokens.add(buf.toString());
        tokens.add(c);
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    if (buf.isEmpty) return null;
    tokens.add(buf.toString());

    // Pass 1: * and /
    for (var i = 1; i < tokens.length - 1;) {
      if (tokens[i] == '*' || tokens[i] == '/') {
        final a = double.tryParse(tokens[i - 1]) ?? 0;
        final b = double.tryParse(tokens[i + 1]) ?? 0;
        final r = tokens[i] == '*' ? a * b : (b == 0 ? 0 : a / b);
        tokens.replaceRange(i - 1, i + 2, [r.toString()]);
      } else {
        i += 2;
      }
    }
    // Pass 2: + and -
    var acc = double.tryParse(tokens.first) ?? 0;
    for (var i = 1; i < tokens.length - 1; i += 2) {
      final op = tokens[i];
      final b = double.tryParse(tokens[i + 1]) ?? 0;
      acc = op == '+' ? acc + b : acc - b;
    }
    return acc;
  }

  String _displayedExpression() {
    if (_expression.isEmpty) return '0';
    return MoneyInputFormatter.formatAmount(0).isEmpty
        ? _expression
        : _formatExpression(_expression);
  }

  String _formatExpression(String e) {
    final out = StringBuffer();
    final buf = StringBuffer();
    void flush() {
      if (buf.isEmpty) return;
      final n = int.tryParse(buf.toString());
      if (n != null) {
        out.write(MoneyInputFormatter.formatAmount(n));
      } else {
        out.write(buf.toString());
      }
      buf.clear();
    }

    for (var i = 0; i < e.length; i++) {
      final c = e[i];
      if ('+-×÷'.contains(c)) {
        flush();
        out.write(' $c ');
      } else {
        buf.write(c);
      }
    }
    flush();
    return out.toString();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _displayedExpression(),
                    style: const TextStyle(fontSize: 18, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result != null
                        ? MoneyInputFormatter.formatAmount(result.toInt())
                        : '0',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildKeypad(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Bekor qilish'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: result == null
                        ? null
                        : () => Navigator.pop(context, result),
                    child: const Text('Qabul qilish'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final rows = [
      ['7', '8', '9', '÷'],
      ['4', '5', '6', '×'],
      ['1', '2', '3', '-'],
      ['C', '0', '⌫', '+'],
    ];
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                for (final t in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _Key(label: t, onTap: () => _press(t)),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  bool get _isOperator => '+-×÷'.contains(label);
  bool get _isControl => label == 'C' || label == '⌫';

  @override
  Widget build(BuildContext context) {
    final bg = _isOperator
        ? AppTheme.primary.withValues(alpha: 0.1)
        : _isControl
            ? Colors.red.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.surfaceContainer;
    final color = _isOperator
        ? AppTheme.primary
        : _isControl
            ? AppTheme.danger
            : null;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
