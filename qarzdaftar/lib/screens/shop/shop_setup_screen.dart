import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/shop_profile.dart';
import '../../providers/shop_provider.dart';
import '../../theme/app_theme.dart';

class ShopSetupScreen extends ConsumerStatefulWidget {
  const ShopSetupScreen({super.key, this.initial, this.editMode = false});

  final ShopProfile? initial;
  final bool editMode;

  @override
  ConsumerState<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends ConsumerState<ShopSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ownerNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _ownerNameCtrl = TextEditingController(text: widget.initial?.ownerName ?? '');
    _phoneCtrl = TextEditingController(text: widget.initial?.ownerPhone ?? '');
    _addressCtrl = TextEditingController(text: widget.initial?.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final profile = ShopProfile(
      name: _nameCtrl.text.trim(),
      ownerName: _ownerNameCtrl.text.trim(),
      ownerPhone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );
    await ref.read(shopProfileProvider.notifier).save(profile);
    if (!mounted) return;
    if (widget.editMode) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.editMode
          ? AppBar(title: const Text('Do\'kon ma\'lumotlari'))
          : null,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (!widget.editMode) ...[
                const SizedBox(height: 24),
                const Icon(Icons.storefront_outlined,
                    size: 64, color: AppTheme.primary),
                const SizedBox(height: 16),
                const Text(
                  'Do\'koningiz haqida',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bu ma\'lumotlar mijozlarga yuboriladigan SMS\'larda ko\'rsatiladi',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),
              ],
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Do\'kon nomi *',
                  prefixIcon: Icon(Icons.storefront_outlined),
                  hintText: 'Masalan: Salim do\'koni',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Do\'kon nomini kiriting'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Egasining ismi',
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'Masalan: Salim aka',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Telefon raqamingiz',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '+998 XX XXX XX XX',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Manzil',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  hintText: 'Masalan: Yangi ko\'cha 5',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),
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
                    : Text(widget.editMode ? 'Saqlash' : 'Davom etish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
