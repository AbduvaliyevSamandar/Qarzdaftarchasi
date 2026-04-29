import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'otp_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _completePhone = '';
  bool _sending = false;
  String? _error;

  Future<void> _sendOtp() async {
    if (_completePhone.isEmpty) {
      setState(() => _error = 'Telefon raqamini kiriting');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });

    await AuthService.instance.sendOtp(
      phoneE164: _completePhone,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() => _sending = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              phone: _completePhone,
              verificationId: verificationId,
            ),
          ),
        );
      },
      onError: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() {
          _sending = false;
          _error = e.message ?? 'OTP yuborishda xatolik';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.book_rounded, size: 72, color: AppTheme.primary),
              const SizedBox(height: 24),
              const Text(
                'Qarz Daftarchasi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Magazin qarzlarini oson boshqaring',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 48),
              IntlPhoneField(
                initialCountryCode: 'UZ',
                decoration: const InputDecoration(labelText: 'Telefon raqamingiz'),
                onChanged: (phone) => _completePhone = phone.completeNumber,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppTheme.danger)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _sending ? null : _sendOtp,
                child: _sending
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Kodni yuborish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
