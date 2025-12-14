import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dashboard/store_repository.dart';

final storeProvider = FutureProvider<StoreData?>((ref) async {
  return ref.read(storeRepositoryProvider).fetchStore();
});

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _storeNameController = TextEditingController();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  bool _savingStore = false;
  bool _changingPass = false;
  Uint8List? _logoBytes;
  String? _logoName;

  @override
  void dispose() {
    _storeNameController.dispose();
    _oldPassController.dispose();
    _newPassController.dispose();
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

  Future<void> _saveStore() async {
    setState(() => _savingStore = true);
    try {
      await ref.read(storeRepositoryProvider).updateStore(
            name: _storeNameController.text.isEmpty ? null : _storeNameController.text,
            logoBytes: _logoBytes,
            logoFilename: _logoName,
          );
      ref.refresh(storeProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store updated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _savingStore = false);
    }
  }

  Future<void> _changePassword() async {
    setState(() => _changingPass = true);
    try {
      await ref.read(storeRepositoryProvider).changePassword(_oldPassController.text, _newPassController.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _changingPass = false);
    }
  }

  Future<void> _cancelSubscription() async {
    try {
      await ref.read(storeRepositoryProvider).cancelSubscription();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription cancellation requested')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeAsync = ref.watch(storeProvider);
    storeAsync.whenData((store) {
      if (store != null && _storeNameController.text.isEmpty) {
        _storeNameController.text = store.name;
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('My Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Store', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            storeAsync.when(
              data: (store) => Row(
                children: [
                  GestureDetector(
                    onTap: _pickLogo,
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: _logoBytes != null
                          ? MemoryImage(_logoBytes!)
                          : (store?.logoUrl != null ? NetworkImage(store!.logoUrl!) as ImageProvider : null),
                      child: (_logoBytes == null && (store?.logoUrl == null))
                          ? const Icon(Icons.camera_alt)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _storeNameController,
                      decoration: const InputDecoration(labelText: 'Store name'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _savingStore ? null : _saveStore,
                    child: _savingStore ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
                  )
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error loading store: $e'),
            ),
            const SizedBox(height: 24),
            Text('Password', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _oldPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Old password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _changingPass ? null : _changePassword,
              child: _changingPass ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Change password'),
            ),
            const SizedBox(height: 24),
            Text('Subscription', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _cancelSubscription,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cancel subscription'),
            ),
          ],
        ),
      ),
    );
  }
}
