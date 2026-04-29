import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  final _ctrl = TextEditingController();
  String? _error;
  bool _checking = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _verify(String pin) async {
    if (pin.length != 4) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    final ok = await ref.read(authControllerProvider.notifier).unlock(pin);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _checking = false;
        _error = 'PIN-kod noto\'g\'ri';
        _ctrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultTheme = PinTheme(
      width: 56,
      height: 64,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.book_rounded, size: 72, color: AppTheme.primary),
              const SizedBox(height: 16),
              const Text(
                'Qarz Daftarchasi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'PIN-kodni kiriting',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 48),
              Center(
                child: Pinput(
                  controller: _ctrl,
                  length: 4,
                  obscureText: true,
                  autofocus: true,
                  defaultPinTheme: defaultTheme,
                  onCompleted: _verify,
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
              if (_checking) ...[
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
