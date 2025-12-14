import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/billing_repository.dart';
import '../../inventory/data/product.dart';
import 'package:image_picker/image_picker.dart';

final posProvider = StateNotifierProvider<POSNotifier, POSState>((ref) {
  return POSNotifier(ref.read(billingRepositoryProvider));
});

class POSState {
  final List<CartItem> cart;
  final bool isLoading;
  final String? error;
  final List<Product> recognizedProducts; // Products found from image

  POSState({
    this.cart = const [],
    this.isLoading = false,
    this.error,
    this.recognizedProducts = const [],
  });

  POSState copyWith({
    List<CartItem>? cart,
    bool? isLoading,
    String? error,
    List<Product>? recognizedProducts,
  }) {
    return POSState(
      cart: cart ?? this.cart,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Reset error if null passed? Or specific logic. passing null clears it here.
      recognizedProducts: recognizedProducts ?? this.recognizedProducts,
    );
  }
  
  double get total => cart.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
}

class POSNotifier extends StateNotifier<POSState> {
  final BillingRepository _repository;

  POSNotifier(this._repository) : super(POSState());

  void addToCart(Product product) {
    print('Adding to cart: ${product.name}');
    final existingIndex = state.cart.indexWhere((i) => i.product.id == product.id);
    List<CartItem> newCart = List.from(state.cart);

    if (existingIndex >= 0) {
      newCart[existingIndex].quantity++;
    } else {
      newCart.add(CartItem(product: product));
    }
    state = state.copyWith(cart: newCart);
  }

  void removeFromCart(Product product) {
    state = state.copyWith(cart: state.cart.where((i) => i.product.id != product.id).toList());
  }

  void clearCart() {
    state = state.copyWith(cart: []);
  }

  Future<void> checkout(String paymentMethod) async {
    if (state.cart.isEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      await _repository.createBill(state.cart, paymentMethod);
      clearCart();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> recognizeImage(XFile imageFile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.recognizeProducts(imageFile);
      if (kDebugMode && result.debug != null) {
        debugPrint('OCR debug: ${result.debug}');
      }
      state = state.copyWith(
        isLoading: false,
        recognizedProducts: result.products,
        error: result.products.isEmpty ? 'No items recognized. Try a clearer, well-lit photo.' : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString(), recognizedProducts: []);
    }
  }
  void clearRecognition() {
    state = state.copyWith(recognizedProducts: []);
  }
}
