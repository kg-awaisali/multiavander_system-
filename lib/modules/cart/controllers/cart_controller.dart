import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants.dart';
import '../../../data/models/product_model.dart';
import '../../../core/api_client.dart';
import '../../auth/views/login_screen.dart';

class CartItem {
  final ProductModel product;
  final ProductVariationModel? variation; // Selected variation
  int quantity;

  CartItem({required this.product, this.variation, this.quantity = 1});

  String get uniqueId => variation != null ? '${product.id}_${variation!.id}' : '${product.id}';

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'variation': variation?.toJson(),
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    product: ProductModel.fromJson(json['product']),
    variation: json['variation'] != null ? ProductVariationModel.fromJson(json['variation']) : null,
    quantity: json['quantity'] ?? 1,
  );
}

class CartController extends GetxController {
  var cartItems = <CartItem>[].obs;
  var unavailableItems = <CartItem>[].obs;
  var selectedItems = <String>{}.obs; // Set of uniqueIds
  final _storage = GetStorage();
  final String _storageKey = 'cart_items';

  @override
  void onInit() {
    super.onInit();
    _loadCart();
    // Default select all on load
    if (selectedItems.isEmpty && cartItems.isNotEmpty) {
      selectedItems.assignAll(cartItems.map((e) => e.uniqueId));
    }
    // Fetch from server if logged in
    fetchCartFromServer();
  }

  void toggleSelection(String uniqueId) {
    if (selectedItems.contains(uniqueId)) {
      selectedItems.remove(uniqueId);
    } else {
      selectedItems.add(uniqueId);
    }
  }

  void toggleAll(bool select) {
    if (select) {
      selectedItems.assignAll(cartItems.map((e) => e.uniqueId));
    } else {
      selectedItems.clear();
    }
  }

  bool get isAllSelected => cartItems.isNotEmpty && selectedItems.length == cartItems.length;

  void _loadCart() {
    try {
      final stored = _storage.read<String>(_storageKey);
      if (stored != null) {
        final List decodedData = jsonDecode(stored);
        cartItems.assignAll(decodedData.map((e) => CartItem.fromJson(e)).toList());
        // Auto select all loaded items initially
        selectedItems.assignAll(cartItems.map((e) => e.uniqueId));
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  Future<void> fetchCartFromServer() async {
    try {
      final response = await ApiClient.get('/cart');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List serverItems = data['data'] ?? [];
        
        if (serverItems.isNotEmpty) {
          cartItems.assignAll(serverItems.map((e) {
            // Check if product exists in response
            if (e['product'] == null) return null;
            
            return CartItem(
              product: ProductModel.fromJson(e['product']),
              variation: e['variation_id'] != null ? 
                e['product']['variations']?.firstWhereOrNull((v) => v['id'].toString() == e['variation_id'].toString()) != null ?
                ProductVariationModel.fromJson(e['product']['variations'].firstWhere((v) => v['id'].toString() == e['variation_id'].toString())) : null : null,
              quantity: int.tryParse(e['quantity'].toString()) ?? 1
            );
          }).whereType<CartItem>().toList());
          
          // Auto select all items from server
          selectedItems.assignAll(cartItems.map((e) => e.uniqueId));
          _saveCart();
          
          debugPrint("✅ Cart synchronized from server: ${cartItems.length} items");
        }
      }
    } catch (e) {
      print('Fetch cart server error: $e');
    }
  }

  Future<void> syncLocalCartToServer() async {
    if (cartItems.isEmpty) return;
    try {
      final items = cartItems.map((e) => {
        'product_id': e.product.id,
        'quantity': e.quantity
      }).toList();
      
      await ApiClient.post('/cart/sync', {'items': items});
    } catch (e) {
       print('Sync cart error: $e');
    }
  }

  void _saveCart() {
    try {
      final encoded = jsonEncode(cartItems.map((e) => e.toJson()).toList());
      _storage.write(_storageKey, encoded);
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  // Group items by shop id
  Map<int, List<CartItem>> get groupedByVendor {
    Map<int, List<CartItem>> grouped = {};
    for (var item in cartItems) {
      if (!grouped.containsKey(item.product.shopId)) {
        grouped[item.product.shopId] = [];
      }
      grouped[item.product.shopId]!.add(item);
    }
    return grouped;
  }

  double get totalAmount {
    double total = 0;
    for (var item in cartItems) {
      if (selectedItems.contains(item.uniqueId)) {
        total += item.product.price * item.quantity;
      }
    }
    return total;
  }
  
  // Get ONLY selected items for checkout
  List<CartItem> get checkoutItems {
    return cartItems.where((item) => selectedItems.contains(item.uniqueId)).toList();
  }

  int get totalItems {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  Future<void> addToCart(ProductModel product, {ProductVariationModel? variation, int qty = 1}) async {
    final String uniqueId = variation != null ? '${product.id}_${variation.id}' : '${product.id}';
    int index = cartItems.indexWhere((item) => item.uniqueId == uniqueId);
    
    int newQuantity = qty;
    
    // Optimistic Update
    if (index != -1) {
      cartItems[index].quantity += qty;
      newQuantity = cartItems[index].quantity;
    } else {
      final newItem = CartItem(product: product, variation: variation, quantity: qty);
      cartItems.add(newItem);
      selectedItems.add(newItem.uniqueId); // Auto select new item
    }
    cartItems.refresh();
    _saveCart(); // Save locally immediately
    
    // Sync with server if logged in
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    
    if (token != null && token.isNotEmpty) {
       try {
         final response = await ApiClient.post('/cart/add', {
            'product_id': product.id,
            'variation_id': variation?.id,
            'quantity': newQuantity,
         });

         if (response.statusCode == 200 || response.statusCode == 201) {
           debugPrint("✅ Cart item synced to server");
           Get.snackbar(
             'Sync Success', 
             '${product.name} saved to your account',
             snackPosition: SnackPosition.TOP,
             backgroundColor: Colors.green.withOpacity(0.8),
             colorText: Colors.white,
             duration: const Duration(seconds: 1),
           );
         } else {
           debugPrint("❌ Failed to sync cart item: ${response.body}");
           Get.snackbar(
             'Sync Warning', 
             'Saved locally, but failed to sync with your account',
             snackPosition: SnackPosition.TOP,
             backgroundColor: Colors.orange.withOpacity(0.8),
             colorText: Colors.white,
           );
         }
       } catch (e) {
         debugPrint("❌ Exception syncing cart item: $e");
       }
    } else {
       // Not logged in
       Get.snackbar(
         'Local Cart', 
         'Item saved on this device. Login to sync with your account.',
         snackPosition: SnackPosition.TOP,
         backgroundColor: Colors.blue.withOpacity(0.8),
         colorText: Colors.white,
       );
    }

    Get.snackbar(
      'Cart', 
      '${product.name}${variation != null ? ' (Variant)' : ''} added to cart', 
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
    );
  }


  void removeFromCart(int productId) {
    cartItems.removeWhere((item) {
        if (item.product.id == productId) {
            selectedItems.remove(item.uniqueId);
            return true;
        }
        return false;
    });
    _saveCart();
    // Sync with server
    ApiClient.delete('/cart/remove/$productId');
  }

  void updateQuantity(int productId, int delta) {
    int index = cartItems.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      cartItems[index].quantity += delta;
      int finalQty = cartItems[index].quantity;
      if (finalQty <= 0) {
        selectedItems.remove(cartItems[index].uniqueId);
        cartItems.removeAt(index);
        ApiClient.delete('/cart/remove/$productId');
      } else {
        // Sync with server
        ApiClient.post('/cart/add', {
          'product_id': productId,
          'quantity': finalQty,
        });
      }
      cartItems.refresh();
      _saveCart();
    }
  }

  void clearCart() {
    cartItems.clear();
    selectedItems.clear();
    _storage.remove(_storageKey);
  }

  // Live stock validation
  Future<void> validateStock() async {
    if (cartItems.isEmpty) return;

    try {
      final ids = cartItems.map((item) => item.product.id).join(',');
      final response = await ApiClient.get('/products?ids=$ids');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List productsJson = data['data'] ?? [];
        
        final Map<int, ProductModel> latestProducts = {
          for (var p in productsJson) p['id']: ProductModel.fromJson(p)
        };

        bool changeDetected = false;
        List<CartItem> newActive = [];
        List<CartItem> newUnavailable = [];

        for (var item in cartItems) {
          final latestp = latestProducts[item.product.id];
          
          if (latestp == null || latestp.stock <= 0) {
            // Moved to unavailable
            newUnavailable.add(item); // Keep old item data for display reference
            selectedItems.remove(item.uniqueId); // Unselect if unavailable
            changeDetected = true;
          } else {
             // Product exists and has stock
             // Update quantity cap
             int validQty = item.quantity;
             if (latestp.stock < validQty) {
                validQty = latestp.stock;
                Get.snackbar('Stock Update', '${latestp.name} quantity adjusted to $validQty');
                changeDetected = true;
             }
             
             newActive.add(CartItem(
               product: latestp,
               quantity: validQty
             ));
          }
        }
        
        if (changeDetected) {
          cartItems.assignAll(newActive);
          unavailableItems.assignAll(newUnavailable);
          _saveCart();
          Get.snackbar(
             'Availability Update', 
             'Some items were moved to unavailable section due to stock changes',
             backgroundColor: Colors.orange.withOpacity(0.9),
             colorText: Colors.white
          );
        }
      }
    } catch (e) {
      print('Stock validation error: $e');
    }
  }
}
