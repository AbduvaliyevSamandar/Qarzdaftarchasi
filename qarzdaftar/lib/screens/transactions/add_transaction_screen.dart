import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/transaction.dart';
import '../../providers/customers_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../services/sms_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/input_formatters.dart';
import '../../widgets/amount_field.dart';

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
    final amount = MoneyInputFormatter.parseAmount(_amountCtrl.text);
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

      if (_type == TxnType.payment) {
        await _maybeSendThankYou();
      }

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

  Future<void> _maybeSendThankYou() async {
    ref.invalidate(customersProvider);
    final list = await ref.read(customersProvider.future);
    final cb = list.where((b) => b.customer.id == widget.customerId).firstOrNull;
    if (cb == null) return;
    if (cb.remaining > 0) return;
    if (cb.totalDebt <= 0) return;
    final phone = cb.customer.phone;
    if (phone == null || phone.trim().isEmpty) return;

    final shop = ref.read(shopProfileProvider).valueOrNull;
    final shopName = (shop?.name.isNotEmpty ?? false) ? shop!.name : 'do\'kon';
    final message = SmsService.buildThankYouText(
      customerName: cb.customer.name,
      shopName: shopName,
      ownerPhone: shop?.ownerPhone,
    );

    final granted = await SmsService.ensureSmsPermission();
    if (!mounted) return;
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rahmat SMS uchun ruxsat yo\'q')),
      );
      return;
    }

    final result = await SmsService.sendInBackground(
      phone: phone,
      message: message,
    );
    if (!mounted) return;
    if (result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mijozga "rahmat" SMS yuborildi'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDebt = _type == TxnType.debt;
    final productNames = ref.watch(productNamesProvider).valueOrNull ?? const [];

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
              AmountField(controller: _amountCtrl, autofocus: true),
              const SizedBox(height: 12),
              if (isDebt) ...[
                _ProductAutocomplete(
                  controller: _productCtrl,
                  options: productNames,
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
              ],
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

class _ProductAutocomplete extends StatelessWidget {
  const _ProductAutocomplete({
    required this.controller,
    required this.options,
  });

  final TextEditingController controller;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (TextEditingValue value) {
        final query = value.text.toLowerCase().trim();
        if (query.isEmpty) {
          return options.take(20);
        }
        return options
            .where((o) => o.toLowerCase().contains(query))
            .take(20);
      },
      onSelected: (value) => controller.text = value,
      fieldViewBuilder: (context, fieldCtrl, focusNode, onFieldSubmitted) {
        fieldCtrl.text = controller.text;
        fieldCtrl.addListener(() => controller.text = fieldCtrl.text);
        return TextFormField(
          controller: fieldCtrl,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Mahsulot nomi',
            hintText: 'Masalan: non, sut, qand',
            prefixIcon: Icon(Icons.shopping_basket_outlined),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, items) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final option = items.elementAt(i);
                  return ListTile(
                    dense: true,
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
