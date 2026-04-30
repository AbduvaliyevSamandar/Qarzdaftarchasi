import 'package:flutter/material.dart';

import '../services/voice_input_service.dart';
import '../theme/app_theme.dart';

class NoteField extends StatefulWidget {
  const NoteField({
    super.key,
    required this.controller,
    this.label = 'Eslatma',
    this.maxLines = 3,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;

  @override
  State<NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<NoteField> {
  bool _listening = false;

  Future<void> _toggleListen() async {
    if (_listening) {
      await VoiceInputService.instance.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final ok = await VoiceInputService.instance.ensureAvailable();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mikrofon yoki ovozli yozish ishlamadi'),
        ),
      );
      return;
    }
    setState(() => _listening = true);
    await VoiceInputService.instance.start(
      onText: (text) {
        widget.controller.text = text;
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controller.text.length),
        );
      },
    );
  }

  @override
  void dispose() {
    if (_listening) {
      VoiceInputService.instance.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      maxLines: widget.maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.note_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            _listening ? Icons.mic : Icons.mic_none_outlined,
            color: _listening ? AppTheme.danger : null,
          ),
          tooltip: _listening ? 'To\'xtatish' : 'Ovozli yozish',
          onPressed: _toggleListen,
        ),
      ),
    );
  }
}
