import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/customers_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/products_provider.dart';
import '../../providers/shop_provider.dart';
import '../../services/backup_service.dart';
import '../../theme/app_theme.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  Future<void> _create() async {
    setState(() => _busy = true);
    final result = await BackupService.instance.createBackup();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!result.ok || result.file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Xatolik')),
      );
      return;
    }
    final s = result.summary!;
    final share = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Zaxira yaratildi'),
        content: Text(
          'Mijozlar: ${s.customers}\n'
          'Tranzaksiyalar: ${s.transactions}\n'
          'Mahsulotlar: ${s.products}\n\n'
          'Faylni Telegram yoki email orqali o\'zingizga yuborib qo\'ying.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: const Text('Yopish'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(_, true),
            icon: const Icon(Icons.share),
            label: const Text('Ulashish'),
          ),
        ],
      ),
    );
    if (share == true) {
      await BackupService.instance.shareBackup(result.file!);
    }
  }

  Future<void> _restore() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );
    if (picked == null || picked.files.single.path == null) return;
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Joriy ma\'lumotlar o\'chiriladi'),
        content: const Text(
          'Qaytarish hozirgi mijozlar, tranzaksiyalar va mahsulotlarni '
          'o\'chirib, faylda saqlanganlarini joylashtiradi. '
          'Davom etishni xohlaysizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(_, true),
            child: const Text('Qaytarish'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    final file = File(picked.files.single.path!);
    final result = await BackupService.instance.restore(file);
    if (!mounted) return;
    setState(() => _busy = false);

    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Xatolik')),
      );
      return;
    }
    ref.invalidate(customersProvider);
    ref.invalidate(productsProvider);
    ref.invalidate(shopProfileProvider);

    final s = result.summary!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Tiklandi: ${s.customers} mijoz, ${s.transactions} tranzaksiya',
        ),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr.backupRestore)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Nima uchun zaxira?',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr.backupHelp,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            tileColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.upload_file, color: AppTheme.primary),
            ),
            title: Text(tr.exportBackup),
            subtitle: const Text('JSON fayl yaratiladi va ulashish dialogi ochiladi'),
            trailing: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _busy ? null : _create,
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.download, color: AppTheme.warning),
            ),
            title: Text(tr.importBackup),
            subtitle: const Text(
              'Saqlangan faylni tanlang. Joriy ma\'lumotlar almashtiriladi.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : _restore,
          ),
        ],
      ),
    );
  }
}
