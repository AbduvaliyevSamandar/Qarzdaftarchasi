import 'dart:async';

import 'package:another_telephony/telephony.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SmsService {
  static final Telephony _telephony = Telephony.instance;

  static String _normalize(String phone) {
    return phone.replaceAll(RegExp(r'[\s()-]'), '');
  }

  static String buildReminderText({
    required String customerName,
    required double remainingAmount,
    required String shopName,
    String? ownerPhone,
  }) {
    final amount = remainingAmount.toStringAsFixed(0);
    final contact = (ownerPhone != null && ownerPhone.trim().isNotEmpty)
        ? '\nAloqa: ${ownerPhone.trim()}'
        : '';
    return 'Hurmatli $customerName, "$shopName" do\'konida qarzingiz '
        '$amount so\'m. Iltimos, imkon topib qaytarib qo\'ying. Rahmat.$contact';
  }

  static String buildThankYouText({
    required String customerName,
    required String shopName,
    String? ownerPhone,
  }) {
    final contact = (ownerPhone != null && ownerPhone.trim().isNotEmpty)
        ? '\nAloqa: ${ownerPhone.trim()}'
        : '';
    return 'Hurmatli $customerName, "$shopName" do\'konidagi qarzingizni '
        'to\'liq qaytarganingiz uchun rahmat! Bizdan xizmat olishda davom eting.$contact';
  }

  static Future<bool> ensureSmsPermission() async {
    final granted = await _telephony.requestSmsPermissions;
    return granted ?? false;
  }

  static Future<bool> hasPermission() async {
    return (await _telephony.isSmsCapable) ?? false;
  }

  static Future<SmsResult> sendDirect({
    required String phone,
    required String message,
  }) async {
    final cleaned = _normalize(phone);
    if (cleaned.isEmpty) {
      return SmsResult.error('Telefon raqami bo\'sh');
    }
    try {
      final granted = await _telephony.requestSmsPermissions;
      if (granted != true) {
        return SmsResult.error(
          'SMS yuborish uchun ruxsat yo\'q. Telefon sozlamalaridan ruxsat bering.',
        );
      }
      return await _sendWithStatus(cleaned, message);
    } on PlatformException catch (e) {
      return SmsResult.error('SMS yuborilmadi: ${e.message ?? e.code}');
    } catch (e) {
      return SmsResult.error('Xatolik: $e');
    }
  }

  static Future<SmsResult> sendInBackground({
    required String phone,
    required String message,
  }) async {
    final cleaned = _normalize(phone);
    if (cleaned.isEmpty) {
      return SmsResult.error('Telefon raqami bo\'sh');
    }
    try {
      final granted = await _telephony.requestSmsPermissions;
      if (granted != true) {
        return SmsResult.error('SMS ruxsati yo\'q');
      }
      return await _sendWithStatus(cleaned, message);
    } catch (e) {
      return SmsResult.error('SMS xatolik: $e');
    }
  }

  static Future<SmsResult> _sendWithStatus(String phone, String message) async {
    final completer = Completer<SmsResult>();
    var notified = false;

    try {
      _telephony.sendSms(
        to: phone,
        message: message,
        isMultipart: message.length > 160,
        statusListener: (status) {
          if (notified) return;
          if (status == SendStatus.SENT) {
            notified = true;
            completer.complete(SmsResult.success());
          }
        },
      );
    } on PlatformException catch (e) {
      if (!completer.isCompleted) {
        completer.complete(
          SmsResult.error('SMS yuborilmadi: ${e.message ?? e.code}'),
        );
      }
      return completer.future;
    } catch (e) {
      if (!completer.isCompleted) {
        completer.complete(SmsResult.error('Xatolik: $e'));
      }
      return completer.future;
    }

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => SmsResult.error(
        'SMS yuborish kechikdi. Operator ulanishini tekshiring.',
      ),
    );
  }

  static Future<SmsResult> sendViaDefaultApp({
    required String phone,
    required String message,
  }) async {
    final cleaned = _normalize(phone);
    if (cleaned.isEmpty) return SmsResult.error('Telefon raqami bo\'sh');
    for (final scheme in const ['smsto', 'sms']) {
      final uri = Uri(
        scheme: scheme,
        path: cleaned,
        queryParameters: {'body': message},
      );
      try {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) return SmsResult.success();
      } catch (_) {}
    }
    return SmsResult.error('SMS ilovasi ochilmadi');
  }

  static Future<SmsResult> copyTextToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return SmsResult.success();
    } catch (e) {
      return SmsResult.error('Nusxalashda xatolik');
    }
  }

  static Future<SmsResult> call(String phone) async {
    final cleaned = _normalize(phone);
    if (cleaned.isEmpty) return SmsResult.error('Telefon raqami bo\'sh');

    final uri = Uri(scheme: 'tel', path: cleaned);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      return ok
          ? SmsResult.success()
          : SmsResult.error('Qo\'ng\'iroq ilovasi ochilmadi');
    } catch (e) {
      return SmsResult.error('Xatolik: $e');
    }
  }
}

class SmsResult {
  SmsResult._({required this.ok, this.error});
  factory SmsResult.success() => SmsResult._(ok: true);
  factory SmsResult.error(String message) => SmsResult._(ok: false, error: message);

  final bool ok;
  final String? error;
}
