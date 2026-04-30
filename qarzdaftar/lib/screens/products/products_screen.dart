import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product.dart';
import '../../providers/products_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/input_formatters.dart';
import '../../widgets/amount_field.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mahsulotlar')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xatolik: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'Mahsulot ro\'yxati bo\'sh',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tez-tez qarzga olinadigan mahsulotlarni qo\'shing.\nKeyin tranzaksiya yozayotganda tezroq tanlaysiz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
            itemBuilder: (context, i) {
              final p = list[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.shopping_basket_outlined,
                    color: AppTheme.primary,
                  ),
                ),
                title: Text(
                  p.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${Formatters.money(p.price)}${p.unit != null ? ' / ${p.unit}' : ''}',
                ),
                trailing: PopupMenuButton<String>(
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Tahrirlash')),
                    PopupMenuItem(value: 'delete', child: Text('O\'chirish')),
                  ],
                  onSelected: (v) async {
                    if (v == 'edit') {
                      _editProduct(context, ref, p);
                    } else if (v == 'delete') {
                      final ok = await _confirmDelete(context, p.name);
                      if (ok == true) {
                        await ref.read(productsProvider.notifier).remove(p.id);
                      }
                    }
                  },
                ),
                onTap: () => _editProduct(context, ref, p),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editProduct(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Mahsulot qo\'shish'),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('O\'chirilsinmi?'),
        content: Text('"$name" mahsuloti ro\'yxatdan o\'chiriladi'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(_, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
  }

  void _editProduct(BuildContext context, WidgetRef ref, Product? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductEditor(existing: existing),
    );
  }
}

class _ProductEditor extends ConsumerStatefulWidget {
  const _ProductEditor({this.existing});
  final Product? existing;

  @override
  ConsumerState<_ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends ConsumerState<_ProductEditor> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _unitCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _priceCtrl = TextEditingController(
      text: widget.existing != null
          ? MoneyInputFormatter.formatAmount(widget.existing!.price)
          : '',
    );
    _unitCtrl = TextEditingController(text: widget.existing?.unit ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = MoneyInputFormatter.parseAmount(_priceCtrl.text);
    if (name.isEmpty || price == null || price <= 0) return;
    setState(() => _saving = true);
    if (widget.existing == null) {
      await ref.read(productsProvider.notifier).create(
            name: name,
            price: price,
            unit: _unitCtrl.text,
          );
    } else {
      await ref.read(productsProvider.notifier).editProduct(
            widget.existing!.copyWith(
              name: name,
              price: price,
              unit: _unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim(),
            ),
          );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null ? 'Yangi mahsulot' : 'Mahsulotni tahrirlash',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nomi',
              prefixIcon: Icon(Icons.shopping_basket_outlined),
            ),
          ),
          const SizedBox(height: 12),
          AmountField(controller: _priceCtrl, label: 'Narx (so\'m)'),
          const SizedBox(height: 12),
          TextField(
            controller: _unitCtrl,
            decoration: const InputDecoration(
              labelText: 'O\'lchov birligi (dona, kg, litr...)',
              prefixIcon: Icon(Icons.straighten),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(widget.existing == null ? 'Qo\'shish' : 'Saqlash'),
          ),
        ],
      ),
    );
  }
}
