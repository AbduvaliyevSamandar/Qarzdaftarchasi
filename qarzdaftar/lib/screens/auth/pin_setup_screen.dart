import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _firstCtrl = TextEditingController();
  final _secondCtrl = TextEditingController();
  bool _confirmStep = false;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _secondCtrl.dispose();
    super.dispose();
  }

  Future<void> _onFirstComplete(String value) async {
    if (value.length != 4) return;
    setState(() {
      _confirmStep = true;
      _error = null;
    });
  }

  Future<void> _onSecondComplete(String value) async {
    if (value.length != 4) return;
    if (value != _firstCtrl.text) {
      setState(() {
        _error = 'PIN-kodlar mos kelmadi. Qaytadan kiriting.';
        _confirmStep = false;
        _firstCtrl.clear();
        _secondCtrl.clear();
      });
      return;
    }
    setState(() => _saving = true);
    await ref.read(authControllerProvider.notifier).setupPin(value);
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
              const SizedBox(height: 40),
              const Icon(Icons.lock_outline, size: 64, color: AppTheme.primary),
              const SizedBox(height: 24),
              Text(
                _confirmStep ? 'PIN-kodni qaytaring' : 'PIN-kod o\'rnating',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _confirmStep
                    ? 'Xavfsizlik uchun PIN-kodni yana bir bor kiriting'
                    : '4 raqamli PIN o\'ylab toping. Bu sizga ilovaga kirish uchun kerak.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 40),
              Center(
                child: _confirmStep
                    ? Pinput(
                        key: const ValueKey('second'),
                        controller: _secondCtrl,
                        length: 4,
                        obscureText: true,
                        autofocus: true,
                        defaultPinTheme: defaultTheme,
                        onCompleted: _onSecondComplete,
                      )
                    : Pinput(
                        key: const ValueKey('first'),
                        controller: _firstCtrl,
                        length: 4,
                        obscureText: true,
                        autofocus: true,
                        defaultPinTheme: defaultTheme,
                        onCompleted: _onFirstComplete,
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
              const Spacer(),
              if (_confirmStep && !_saving)
                TextButton(
                  onPressed: () => setState(() {
                    _confirmStep = false;
                    _firstCtrl.clear();
                    _secondCtrl.clear();
                    _error = null;
                  }),
                  child: const Text('Boshqa PIN tanlash'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
