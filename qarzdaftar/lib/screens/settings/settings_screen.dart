import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pinput/pinput.dart';

import '../../l10n/app_locale.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customers_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auto_reminder_service.dart';
import '../../services/export_service.dart';
import '../../services/shop_service.dart';
import '../../theme/app_theme.dart';
import '../backup/backup_screen.dart';
import '../products/products_screen.dart';
import '../shop/shop_setup_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _autoSms;

  @override
  void initState() {
    super.initState();
    _loadAutoSms();
  }

  Future<void> _loadAutoSms() async {
    final v = await ShopService.instance.isAutoSmsEnabled();
    if (mounted) setState(() => _autoSms = v);
  }

  Future<void> _toggleAutoSms(bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      if (!mounted) return;
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bildirishnoma uchun ruxsat kerak'),
            backgroundColor: AppTheme.danger,
          ),
        );
        return;
      }
    }
    await AutoReminderService.applySettings(value);
    if (mounted) setState(() => _autoSms = value);
  }

  Future<void> _exportExcel() async {
    final shop = ref.read(shopProfileProvider).valueOrNull;
    if (shop == null) return;
    final list = await ref.read(customersProvider.future);
    if (!mounted) return;
    try {
      final file = await ExportService.instance.exportToExcel(
        shop: shop,
        customers: list,
      );
      await ExportService.instance.shareFile(
        file,
        text: '${shop.name} — qarzdorlar ro\'yxati',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e')),
      );
    }
  }

  Future<void> _exportPdf() async {
    final shop = ref.read(shopProfileProvider).valueOrNull;
    if (shop == null) return;
    final list = await ref.read(customersProvider.future);
    if (!mounted) return;
    try {
      final file = await ExportService.instance.exportToPdf(
        shop: shop,
        customers: list,
      );
      await ExportService.instance.shareFile(
        file,
        text: '${shop.name} — qarz daftari',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = ref.watch(shopProfileProvider).valueOrNull;
    final themeMode =
        ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;
    final locale = ref.watch(localeProvider).valueOrNull ?? AppLocale.uzLatin;
    final tr = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr.tabSettings,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Text(tr.shopInfo),
            subtitle: shop != null
                ? Text(shop.name +
                    (shop.ownerPhone != null && shop.ownerPhone!.isNotEmpty
                        ? '  •  ${shop.ownerPhone}'
                        : ''))
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ShopSetupScreen(initial: shop, editMode: true),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(tr.productsAndPrices),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductsScreen()),
              );
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: Text(tr.autoReminderTitle),
            value: _autoSms ?? false,
            onChanged: _autoSms == null ? null : _toggleAutoSms,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(tr.languageMenu),
            subtitle: Text(locale.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageSheet(context, locale),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: Text(tr.themeMenu),
            subtitle: Text(_themeLabel(themeMode, tr)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeSheet(context, themeMode, tr),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: Text(tr.backupRestore),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: Text(tr.exportExcel),
            trailing: const Icon(Icons.share_outlined),
            onTap: _exportExcel,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: Text(tr.exportPdf),
            trailing: const Icon(Icons.share_outlined),
            onTap: _exportPdf,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_reset_outlined),
            title: Text(tr.changePin),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _ChangePinScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.danger),
            title: Text(
              tr.logout,
              style: const TextStyle(color: AppTheme.danger),
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

  String _themeLabel(ThemeMode m, dynamic tr) => switch (m) {
        ThemeMode.dark => tr.themeDark as String,
        ThemeMode.light => tr.themeLight as String,
        ThemeMode.system => tr.themeSystem as String,
      };

  Future<void> _showThemeSheet(
    BuildContext context,
    ThemeMode current,
    dynamic tr,
  ) async {
    final picked = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              tr.themeMenu as String,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final m in ThemeMode.values)
              ListTile(
                leading: Icon(m == current
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked),
                title: Text(_themeLabel(m, tr)),
                onTap: () => Navigator.pop(_, m),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(themeModeProvider.notifier).setMode(picked);
    }
  }

  Future<void> _showLanguageSheet(BuildContext context, AppLocale current) async {
    final picked = await showModalBottomSheet<AppLocale>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            for (final l in AppLocale.values)
              ListTile(
                leading: Icon(l == current
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked),
                title: Text(l.label),
                onTap: () => Navigator.pop(_, l),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(localeProvider.notifier).setLocale(picked);
    }
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
  int _step = 0;
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
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
