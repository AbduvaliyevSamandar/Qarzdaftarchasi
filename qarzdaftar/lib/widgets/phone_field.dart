import 'package:flutter/material.dart';

import '../utils/input_formatters.dart';

class PhoneField extends StatefulWidget {
  const PhoneField({
    super.key,
    this.controller,
    this.label = 'Telefon raqam',
    this.required = false,
    this.initialValue,
    this.onChanged,
  });

  final TextEditingController? controller;
  final String label;
  final bool required;
  final String? initialValue;
  final ValueChanged<String?>? onChanged;

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  late final TextEditingController _ctrl;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _ctrl = widget.controller!;
    } else {
      _ctrl = TextEditingController();
      _ownsController = true;
    }
    final initial = widget.initialValue ?? _ctrl.text;
    _ctrl.text = UzbPhoneInputFormatter.fromE164(initial);
  }

  @override
  void dispose() {
    if (_ownsController) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _ctrl,
      keyboardType: TextInputType.phone,
      inputFormatters: [UzbPhoneInputFormatter()],
      decoration: InputDecoration(
        labelText: widget.required ? '${widget.label} *' : widget.label,
        prefixIcon: const Icon(Icons.phone_outlined),
        hintText: '+998 XX XXX XX XX',
      ),
      onChanged: widget.onChanged,
      validator: (value) {
        if (!widget.required) {
          if (value == null || value.trim() == UzbPhoneInputFormatter.prefix.trim()) {
            return null;
          }
          final digits = (value).replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.isNotEmpty && digits.length != 12) {
            return 'Telefon raqami to\'liq emas';
          }
          return null;
        }
        final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length != 12) {
          return 'Telefon raqamini to\'liq kiriting';
        }
        return null;
      },
    );
  }
}
