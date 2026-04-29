import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SmsService {
  static String _normalize(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s()-]'), '');
    return cleaned;
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

  static Future<SmsResult> sendReminder({
    required String phone,
    required String customerName,
    required double remainingAmount,
    required String shopName,
    String? ownerPhone,
  }) async {
    final cleanedPhone = _normalize(phone);
    if (cleanedPhone.isEmpty) {
      return SmsResult.error('Telefon raqami bo\'sh');
    }

    final body = buildReminderText(
      customerName: customerName,
      remainingAmount: remainingAmount,
      shopName: shopName,
      ownerPhone: ownerPhone,
    );

    for (final scheme in const ['smsto', 'sms']) {
      final uri = Uri(
        scheme: scheme,
        path: cleanedPhone,
        queryParameters: {'body': body},
      );
      try {
        final ok = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (ok) return SmsResult.success();
      } catch (_) {
        continue;
      }
    }

    return SmsResult.error(
      'SMS ilovasi ochilmadi. Iltimos, telefon raqamini va SMS ilovangizni tekshiring.',
    );
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
