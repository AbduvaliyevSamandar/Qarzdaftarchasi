import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart';
import '../../theme/app_theme.dart';
import '../shop/shop_setup_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(shopProfileProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Do\'kon ma\'lumotlari'),
            subtitle: shop != null
                ? Text(shop.name +
                    (shop.ownerPhone != null && shop.ownerPhone!.isNotEmpty
                        ? '  •  ${shop.ownerPhone}'
                        : ''))
                : const Text('Kiritilmagan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShopSetupScreen(initial: shop, editMode: true),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_reset_outlined),
            title: const Text('PIN-kodni o\'zgartirish'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openChangePin(context, ref),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.danger),
            title: const Text(
              'Chiqish (qulflash)',
              style: TextStyle(color: AppTheme.danger),
            ),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).lock();
              if (context.mounted) {
                Navigator.of(context).popUntil((r) => r.isFirst);
              }
            },
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Versiya'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  void _openChangePin(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _ChangePinScreen()),
    );
  }
}

class _ChangePinScreen extends ConsumerStatefulWidget {
  const _ChangePinScreen();

  @override
  ConsumerState<_ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<_ChangePinScreen> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  int _step = 0; // 0=old, 1=new, 2=confirm
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onComplete(String value) async {
    if (value.length != 4) return;
    setState(() => _error = null);

    if (_step == 0) {
      setState(() => _step = 1);
    } else if (_step == 1) {
      setState(() => _step = 2);
    } else {
      if (value != _newCtrl.text) {
        setState(() {
          _error = 'PIN-kodlar mos kelmadi';
          _confirmCtrl.clear();
        });
        return;
      }
      setState(() => _saving = true);
      final ok = await ref
          .read(authControllerProvider.notifier)
          .changePin(_oldCtrl.text, _newCtrl.text);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _saving = false;
          _step = 0;
          _oldCtrl.clear();
          _newCtrl.clear();
          _confirmCtrl.clear();
          _error = 'Eski PIN noto\'g\'ri';
        });
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN-kod yangilandi')),
      );
      Navigator.pop(context);
    }
  }

  String get _title {
    switch (_step) {
      case 0:
        return 'Eski PIN-kodni kiriting';
      case 1:
        return 'Yangi PIN-kod';
      default:
        return 'Yangi PIN-kodni qaytaring';
    }
  }

  TextEditingController get _activeCtrl {
    switch (_step) {
      case 0:
        return _oldCtrl;
      case 1:
        return _newCtrl;
      default:
        return _confirmCtrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = PinTheme(
      width: 56,
      height: 64,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('PIN-kodni o\'zgartirish')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                _title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 32),
              Center(
                child: Pinput(
                  key: ValueKey('step_$_step'),
                  controller: _activeCtrl,
                  length: 4,
                  obscureText: true,
                  autofocus: true,
                  defaultPinTheme: theme,
                  onCompleted: _onComplete,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppTheme.danger),
                  ),
                ),
              ],
              if (_saving) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
