import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'checkout_screen.dart';
import '../controllers/cart_controller.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../chat/views/chat_room_screen.dart';
import '../../product/views/product_detail_screen.dart';
import '../../auth/views/login_screen.dart';
import '../../auth/controllers/auth_controller.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CartController>();
    
    // Validate stock whenever the cart is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.validateStock();
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Shopping Cart', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: controller.clearCart,
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.cartItems.isEmpty && controller.unavailableItems.isEmpty) {
          return _buildEmptyCart();
        }

        final groupedItems = controller.groupedByVendor;

        return ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // Active Items
             ...groupedItems.entries.map((entry) {
              final items = entry.value;
              final shopName = items.first.product.shopName;
              return _buildStoreGroup(shopName, items, controller);
            }).toList(),
            
            // Unavailable Items
            if (controller.unavailableItems.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Unavailable Items', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: controller.unavailableItems.map((item) => _buildUnavailableItem(item, controller)).toList(),
                ),
              ),
            ]
          ],
        );
      }),
      bottomNavigationBar: _buildBottomBar(controller),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Icon(Icons.shopping_cart_outlined, size: 80, color: AppTheme.primaryColor.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          const Text('Your cart is empty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Looks like you haven\'t added anything yet.', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreGroup(String storeName, List<CartItem> items, CartController controller) {
    return Container(
      margin: const EdgeInsets.only(top: 12, left: 12, right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Store Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.storefront, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    storeName, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Chat with Store Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: InkWell(
                    onTap: () async {
                      final authController = Get.find<AuthController>();
                      if (authController.user.value == null) {
                        Get.to(() => LoginScreen());
                        return;
                      }
                      
                      final chatCtrl = Get.put(ChatController());
                      final firstProduct = items.first.product;

                      if (firstProduct.sellerId == 0) {
                        Get.snackbar("Error", "Invalid Seller Information");
                        return;
                      }

                      Get.showSnackbar(const GetSnackBar(
                        message: "Starting chat...", 
                        duration: Duration(seconds: 1),
                        snackPosition: SnackPosition.TOP,
                      ));

                      final roomId = await chatCtrl.startChat({
                        'id': firstProduct.sellerId,
                        'name': firstProduct.shopName,
                        'image': '', 
                        'email': '',
                      });
                      
                      if (roomId != null) {
                        Get.to(() => ChatRoomScreen(
                          roomId: roomId, 
                          otherUserName: firstProduct.shopName,
                          product: firstProduct,
                          initialProductId: firstProduct.id,
                        ));
                      } else {
                        Get.snackbar("Error", "Failed to start chat. Please try again.");
                      }
                    },
                    child: const Icon(Icons.chat_bubble_outline, size: 22, color: Colors.blue),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to store profile
                  },
                  child: const Text('Visit Store >', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Product List
          ...items.map((item) => _buildCartItem(item, controller)),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, CartController controller) {
    final product = item.product;
    return InkWell(
      onTap: () => Get.to(() => ProductDetailScreen(product: product)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Obx(() => SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: controller.selectedItems.contains(item.uniqueId),
                activeColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (val) {
                  controller.toggleSelection(item.uniqueId);
                },
              ),
            )),
            const SizedBox(width: 12),
            
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.images.isNotEmpty ? AppConstants.getImageUrl(product.images[0]) : '',
                width: 70, // Slightly reduced
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image)),
              ),
            ),
            const SizedBox(width: 12),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  
                  // Price and Quantity Row - Using Wrap or Expanded to prevent overflow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Rs. ${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Quantity Selector
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // Crucial for layout
                          children: [
                            _quantityBtn(Icons.remove, () => controller.updateQuantity(product.id, -1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8), // Reduced padding
                              child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            _quantityBtn(Icons.add, () => controller.updateQuantity(product.id, 1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Delete Button
            IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                onPressed: () => controller.removeFromCart(product.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(), // Min size
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantityBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 14, color: Colors.black87),
      ),
    );
  }

  Widget _buildBottomBar(CartController controller) {
    return Obx(() {
      if (controller.cartItems.isEmpty) return const SizedBox.shrink();
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Select All functionality could be here
               Checkbox(
                  value: controller.isAllSelected,
                  onChanged: (val) => controller.toggleAll(val ?? false),
               ),
              const Text("All", style: TextStyle(color: Colors.grey)),
              const Spacer(),
              
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    'Rs. ${controller.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: controller.selectedItems.isEmpty 
                    ? null 
                    : () => Get.to(() => const CheckoutScreen()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                    'Checkout (${controller.selectedItems.length})', 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildUnavailableItem(CartItem item, CartController controller) {
    final product = item.product;
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          Opacity(
            opacity: 0.5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.images.isNotEmpty ? AppConstants.getImageUrl(product.images[0]) : '',
                width: 60, height: 60, fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(color: Colors.grey), maxLines: 1),
                const SizedBox(height: 4),
                const Text('Out of stock', style: TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () => controller.unavailableItems.remove(item),
          ),
        ],
      ),
    );
  }
}
