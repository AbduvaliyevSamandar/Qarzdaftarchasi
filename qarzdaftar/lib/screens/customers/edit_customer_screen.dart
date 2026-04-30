import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/customer.dart';
import '../../providers/customers_provider.dart';
import '../../services/photo_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/input_formatters.dart';
import '../../widgets/customer_avatar.dart';
import '../../widgets/note_field.dart';
import '../../widgets/phone_field.dart';

class EditCustomerScreen extends ConsumerStatefulWidget {
  const EditCustomerScreen({super.key, this.existing});

  final Customer? existing;

  @override
  ConsumerState<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends ConsumerState<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _noteCtrl;
  String? _photoPath;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _phoneCtrl = TextEditingController();
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _noteCtrl = TextEditingController(text: c?.note ?? '');
    _photoPath = c?.photoPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final path = await PhotoService.instance.pickAndStore(source: source);
    if (path != null && mounted) {
      setState(() => _photoPath = path);
    }
  }

  Future<void> _showPhotoOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kameradan'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galereyadan'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.danger),
                title: const Text(
                  'Suratni o\'chirish',
                  style: TextStyle(color: AppTheme.danger),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _photoPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final phone = UzbPhoneInputFormatter.toE164(_phoneCtrl.text);
      if (_isEdit) {
        final original = widget.existing!;
        if (original.photoPath != null && original.photoPath != _photoPath) {
          await PhotoService.instance.deleteIfExists(original.photoPath);
        }
        final updated = original.copyWith(
          name: _nameCtrl.text.trim(),
          phone: phone,
          address: _addressCtrl.text.trim(),
          note: _noteCtrl.text.trim(),
          photoPath: _photoPath,
          removePhoto: _photoPath == null,
        );
        await ref.read(customersProvider.notifier).updateCustomer(updated);
      } else {
        await ref.read(customersProvider.notifier).create(
              name: _nameCtrl.text,
              phone: phone,
              address: _addressCtrl.text,
              note: _noteCtrl.text,
              photoPath: _photoPath,
            );
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Mijozni tahrirlash' : 'Yangi mijoz'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showPhotoOptions,
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: _photoPath != null
                            ? ClipOval(
                                child: Image.file(
                                  File(_photoPath!),
                                  fit: BoxFit.cover,
                                  width: 96,
                                  height: 96,
                                ),
                              )
                            : CustomerAvatar(
                                name: _nameCtrl.text.isEmpty ? '?' : _nameCtrl.text,
                                size: 96,
                              ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: AppTheme.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _showPhotoOptions,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.photo_camera,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ism *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ismni kiriting'
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              PhoneField(
                controller: _phoneCtrl,
                initialValue: widget.existing?.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Manzil',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              NoteField(controller: _noteCtrl),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(_isEdit ? 'Saqlash' : 'Qo\'shish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
