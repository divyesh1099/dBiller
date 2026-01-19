import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import 'auth_controller.dart';
import '../../../../core/device_utils.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _licenseController = TextEditingController(); // New
  final _storeNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  Uint8List? _logoBytes;
  String? _logoName;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _licenseController.dispose();
    _storeNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (res != null && res.files.isNotEmpty && res.files.single.bytes != null) {
      setState(() {
        _logoBytes = res.files.single.bytes;
        _logoName = res.files.single.name;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final deviceId = await DeviceUtils.getDeviceID();
        await ref.read(authProvider.notifier).register(
          _usernameController.text,
          _passwordController.text,
          deviceId,
          _licenseController.text, // Pass license
          _emailController.text,
          storeName: _storeNameController.text,
          logoBytes: _logoBytes,
          logoName: _logoName,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Successful! Please Login.')));
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              Row(
                children: [
                  IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios)),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'License Activation',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 36),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Activate Your Account',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your license key to set up your organization and begin billing.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _licenseController,
                decoration: const InputDecoration(
                  labelText: 'License Key',
                  hintText: 'XXXX-XXXX-XXXX-XXXX',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required to join' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _storeNameController,
                decoration: const InputDecoration(labelText: 'Organization Name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickLogo,
                    child: CircleAvatar(
                      radius: 26,
                      backgroundImage: _logoBytes != null ? MemoryImage(_logoBytes!) : null,
                      child: _logoBytes == null ? const Icon(Icons.camera_alt) : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Add Logo (optional)'),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Admin Email'),
                validator: (v) => v == null || v.isEmpty ? 'Admin email is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => v != null && v.length < 6 ? 'Min 6 chars' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Activate Organization'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
