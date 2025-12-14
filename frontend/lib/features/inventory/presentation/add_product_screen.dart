import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../data/inventory_repository.dart';
import 'inventory_controller.dart';

import '../data/product.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final Product? initial;
  const AddProductScreen({super.key, this.initial});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _categoryController;
  late TextEditingController _imageUrlController;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? "");
    _priceController = TextEditingController(text: widget.initial?.price.toString() ?? "");
    _stockController = TextEditingController(text: widget.initial?.stock.toString() ?? "");
    _categoryController = TextEditingController(text: widget.initial?.category ?? "");
    _imageUrlController = TextEditingController(text: widget.initial?.imageUrl ?? "");
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (widget.initial == null) {
          await ref.read(inventoryRepositoryProvider).addProduct(
            name: _nameController.text,
            price: double.parse(_priceController.text),
            stock: int.parse(_stockController.text),
            category: _categoryController.text,
            imageFile: _imageFile,
            imageUrl: _imageUrlController.text,
          );
        } else {
          await ref.read(inventoryRepositoryProvider).updateProduct(
            id: widget.initial!.id,
            name: _nameController.text,
            price: double.parse(_priceController.text),
            stock: int.parse(_stockController.text),
            category: _categoryController.text,
            imageFile: _imageFile,
            imageUrl: _imageUrlController.text,
          );
        }
        ref.refresh(productsProvider); // Refresh list
        if (mounted) context.pop();
      } catch (e) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initial == null ? 'Add Product' : 'Edit Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: _imageBytes != null
                      ? Image.memory(
                          _imageBytes!,
                          fit: BoxFit.cover,
                        )
                      : ((widget.initial?.imageUrl != null || _imageUrlController.text.isNotEmpty)
                          ? Image.network(
                              widget.initial?.imageUrl ?? _imageUrlController.text,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                            )
                          : const Icon(Icons.add_a_photo, size: 50)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL (optional if uploading)'),
                onChanged: (_) => setState(() {}), // rebuild to update preview if no file selected
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category / Group (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Save Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
