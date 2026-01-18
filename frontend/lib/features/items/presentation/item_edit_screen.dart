import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/item.dart';
import 'item_form_screen.dart';
import 'items_controller.dart';

class ItemEditScreen extends ConsumerWidget {
  final int itemId;

  const ItemEditScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemProvider(itemId));
    return itemAsync.when(
      data: (item) => ItemFormScreen(initial: item),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
