import 'package:flutter/material.dart';

import '../services/sms_service.dart';
import '../theme/app_theme.dart';

class SmsDialog extends StatefulWidget {
  const SmsDialog({
    super.key,
    required this.phone,
    required this.initialMessage,
    required this.recipientName,
  });

  final String phone;
  final String initialMessage;
  final String recipientName;

  static Future<void> show({
    required BuildContext context,
    required String phone,
    required String initialMessage,
    required String recipientName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SmsDialog(
        phone: phone,
        initialMessage: initialMessage,
        recipientName: recipientName,
      ),
    );
  }

  @override
  State<SmsDialog> createState() => _SmsDialogState();
}

class _SmsDialogState extends State<SmsDialog> {
  late final TextEditingController _textCtrl;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.initialMessage);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final result = await SmsService.sendDirect(
      phone: widget.phone,
      message: _textCtrl.text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (result.ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SMS yuborildi'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'SMS yuborilmadi'),
          backgroundColor: AppTheme.danger,
          action: SnackBarAction(
            label: 'SMS ilovasi orqali',
            textColor: Colors.white,
            onPressed: () async {
              await SmsService.sendViaDefaultApp(
                phone: widget.phone,
                message: _textCtrl.text,
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.sms_outlined, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SMS yuborish',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 18, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.recipientName}  •  ${widget.phone}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textCtrl,
              maxLines: 6,
              minLines: 4,
              decoration: InputDecoration(
                hintText: 'Xabar matni',
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sending
                        ? null
                        : () async {
                            await SmsService.copyTextToClipboard(_textCtrl.text);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Matn nusxalandi')),
                            );
                          },
                    icon: const Icon(Icons.copy),
                    label: const Text('Nusxalash'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(_sending ? 'Yuborilmoqda…' : 'Yuborish'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
