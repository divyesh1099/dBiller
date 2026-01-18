import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/app_colors.dart';
import 'pos_controller.dart';

class AiImageScannerScreen extends ConsumerWidget {
  const AiImageScannerScreen({super.key});

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    if (kIsWeb) {
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) ref.read(posProvider.notifier).recognizeImage(file);
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Open Camera'),
              onTap: () async {
                Navigator.pop(context);
                final file = await picker.pickImage(source: ImageSource.camera);
                if (file != null) ref.read(posProvider.notifier).recognizeImage(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Upload from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final file = await picker.pickImage(source: ImageSource.gallery);
                if (file != null) ref.read(posProvider.notifier).recognizeImage(file);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('AI Image Scanner')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.center_focus_strong, size: 64, color: AppColors.primary),
                  const SizedBox(height: 12),
                  const Text('Scan to Search', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                    'Upload a clear image of the product label or packaging.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.photo_camera, color: Colors.white),
                      label: const Text('Select Image', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            if (state.isLoading) const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
            if (state.error != null && state.error!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(state.error!, style: const TextStyle(color: Colors.redAccent)),
              ),
            if (state.recognizedProducts.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Recognized Items', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.recognizedProducts
                    .map(
                      (product) => Chip(
                        label: Text(product.name),
                        avatar: const Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.read(posProvider.notifier).clearRecognition(),
                child: const Text('Clear Results'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
