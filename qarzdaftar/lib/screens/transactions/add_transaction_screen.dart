import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product.dart';
import '../../models/transaction.dart';
import '../../providers/customers_provider.dart';
import '../../providers/products_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../services/sms_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/input_formatters.dart';
import '../../widgets/amount_field.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confetti_overlay.dart';
import '../../widgets/note_field.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({
    super.key,
    required this.customerId,
    this.existing,
  });

  final String customerId;
  final Txn? existing;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  TxnType _type = TxnType.debt;
  DateTime? _dueDate;
  Product? _selectedProduct;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      _type = t.type;
      _amountCtrl.text = MoneyInputFormatter.formatAmount(t.amount.toInt());
      _productCtrl.text = t.productName ?? '';
      _noteCtrl.text = t.note ?? '';
      _dueDate = t.dueDate;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _productCtrl.dispose();
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year - 1),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickProduct() async {
    final products = ref.read(productsProvider).valueOrNull ?? const [];
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mahsulot ro\'yxati bo\'sh. "Mahsulotlar" bo\'limida qo\'shing.',
          ),
        ),
      );
      return;
    }
    final p = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductPickerSheet(products: products),
    );
    if (p != null) {
      setState(() {
        _selectedProduct = p;
        _productCtrl.text = p.name;
        _qtyCtrl.text = '1';
        _amountCtrl.text = MoneyInputFormatter.formatAmount(p.price.toInt());
      });
    }
  }

  void _onQtyChanged() {
    final p = _selectedProduct;
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    if (p != null && qty > 0) {
      final total = (p.price * qty).toInt();
      _amountCtrl.text = MoneyInputFormatter.formatAmount(total);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = MoneyInputFormatter.parseAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        final updated = Txn(
          id: widget.existing!.id,
          customerId: widget.customerId,
          type: _type,
          amount: amount,
          productName: _productCtrl.text.trim().isEmpty
              ? null
              : _productCtrl.text.trim(),
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          occurredAt: widget.existing!.occurredAt,
          dueDate: _type == TxnType.debt ? _dueDate : null,
          createdAt: widget.existing!.createdAt,
        );
        await ref.read(addTransactionControllerProvider).update(updated);
      } else {
        await ref.read(addTransactionControllerProvider).add(
              customerId: widget.customerId,
              type: _type,
              amount: amount,
              productName: _productCtrl.text,
              note: _noteCtrl.text,
              dueDate: _type == TxnType.debt ? _dueDate : null,
            );
      }
      if (!mounted) return;

      if (!_isEdit && _type == TxnType.payment) {
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

    if (!mounted) return;

    HapticFeedback.heavyImpact();
    ConfettiOverlay.show(context);

    final phone = cb.customer.phone;
    if (phone == null || phone.trim().isEmpty) return;

    final shop = ref.read(shopProfileProvider).valueOrNull;
    final shopName = (shop?.name.isNotEmpty ?? false) ? shop!.name : 'do\'kon';
    final message = SmsService.buildThankYouText(
      customerName: cb.customer.name,
      shopName: shopName,
      ownerPhone: shop?.ownerPhone,
    );

    final send = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Qarz to\'liq to\'landi'),
        content: const Text('Mijozga "rahmat" SMS yuboramizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: const Text('Yo\'q'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(_, true),
            child: const Text('Ha, yuborish'),
          ),
        ],
      ),
    );
    if (send == true) {
      await SmsService.sendViaDefaultApp(phone: phone, message: message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDebt = _type == TxnType.debt;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Yozuvni tahrirlash' : 'Yangi yozuv'),
      ),
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
                onSelectionChanged: _isEdit
                    ? null
                    : (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 20),
              if (isDebt) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _productCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Mahsulot',
                          prefixIcon: const Icon(Icons.shopping_basket_outlined),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.list_alt),
                            tooltip: 'Ro\'yxatdan tanlash',
                            onPressed: _pickProduct,
                          ),
                        ),
                      ),
                    ),
                    if (_selectedProduct != null) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: _qtyCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: 'Soni',
                          ),
                          onChanged: (_) => _onQtyChanged(),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
              ],
              AmountField(controller: _amountCtrl, autofocus: !isDebt),
              if (isDebt) ...[
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.event_outlined),
                    title: const Text('Qaytarish muddati'),
                    subtitle: Text(
                      _dueDate == null
                          ? 'Tanlanmagan'
                          : Formatters.date(_dueDate!),
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
              ],
              const SizedBox(height: 12),
              NoteField(controller: _noteCtrl),
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
                    : Text(_isEdit ? 'Saqlash' : 'Qo\'shish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  const _ProductPickerSheet({required this.products});
  final List<Product> products;

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.products
        : widget.products
            .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: const InputDecoration(
                  hintText: 'Qidirish...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                itemBuilder: (context, i) {
                  final p = filtered[i];
                  return ListTile(
                    leading: const Icon(Icons.shopping_basket_outlined),
                    title: Text(p.name),
                    trailing: Text(
                      Formatters.money(p.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
