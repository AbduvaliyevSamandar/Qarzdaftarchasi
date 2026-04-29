import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    super.key,
    required this.phone,
    required this.verificationId,
  });

  final String phone;
  final String verificationId;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _ctrl = TextEditingController();
  bool _verifying = false;
  String? _error;

  Future<void> _verify() async {
    if (_ctrl.text.length < 6) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await AuthService.instance.verifyOtp(
        verificationId: widget.verificationId,
        smsCode: _ctrl.text,
      );
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = 'Kod noto\'g\'ri';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tasdiqlash kodi',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.phone} raqamiga yuborilgan 6 raqamli kodni kiriting',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),
              Center(
                child: Pinput(
                  controller: _ctrl,
                  length: 6,
                  onCompleted: (_) => _verify(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(_error!, style: const TextStyle(color: AppTheme.danger)),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _verifying ? null : _verify,
                child: _verifying
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Tasdiqlash'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
