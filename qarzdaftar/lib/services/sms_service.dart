import 'package:url_launcher/url_launcher.dart';

class SmsService {
  static Future<bool> sendReminder({
    required String phone,
    required String customerName,
    required double remainingAmount,
    required String shopName,
  }) async {
    final body = Uri.encodeComponent(
      'Hurmatli $customerName, $shopName do\'konida qarzingiz '
      '${remainingAmount.toStringAsFixed(0)} so\'m. Iltimos, qaytarib qo\'ying. Rahmat.',
    );
    final uri = Uri.parse('sms:$phone?body=$body');
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }

  static Future<bool> call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }
}
