import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/transaction.dart';
import '../../providers/transactions_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key, required this.customerId});

  final String customerId;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  TxnType _type = TxnType.debt;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _productCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);
    try {
      await ref.read(addTransactionControllerProvider).add(
            customerId: widget.customerId,
            type: _type,
            amount: amount,
            productName: _productCtrl.text,
            note: _noteCtrl.text,
            dueDate: _type == TxnType.debt ? _dueDate : null,
          );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDebt = _type == TxnType.debt;
    return Scaffold(
      appBar: AppBar(title: const Text('Yangi yozuv')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<TxnType>(
                segments: const [
                  ButtonSegment(
                    value: TxnType.debt,
                    label: Text('Qarz berdim'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: TxnType.payment,
                    label: Text('To\'lov oldim'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Summa (so\'m) *',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'To\'g\'ri summa kiriting';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (isDebt)
                TextFormField(
                  controller: _productCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mahsulot nomi',
                    prefixIcon: Icon(Icons.shopping_basket_outlined),
                  ),
                ),
              if (isDebt) const SizedBox(height: 12),
              if (isDebt)
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.event_outlined),
                    title: const Text('Qaytarish muddati'),
                    subtitle: Text(
                      _dueDate == null
                          ? 'Tanlanmagan'
                          : Formatters.date(_dueDate!),
                      style: TextStyle(
                        color: _dueDate == null
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    trailing: _dueDate != null
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _dueDate = null),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _pickDueDate,
                  ),
                ),
              if (isDebt) const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Eslatma',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Saqlash'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
