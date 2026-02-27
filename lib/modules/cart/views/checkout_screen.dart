import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cart_controller.dart';
import '../../home/views/home_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final cartController = Get.find<CartController>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();
  final areaController = TextEditingController();
  final addressController = TextEditingController();
  final isPlacingOrder = false.obs;
  String selectedPayment = 'cod'; // Default to COD for better visibility

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<AuthController>().fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Futuristic Checkout', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.white.withOpacity(0.5)),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(top: -50, right: -50, child: _glowCircle(Colors.blue, 200)),
          Positioned(bottom: 100, left: -50, child: _glowCircle(Colors.purple, 200)),
          
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _glassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Shipping Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 16),
                      _buildTextField(nameController, 'Full Name', Icons.person),
                      const SizedBox(height: 12),
                      _buildTextField(phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(cityController, 'City', Icons.location_city)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(areaController, 'Area', Icons.map)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(addressController, 'Detailed Address', Icons.home, maxLines: 2),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Privacy Glass List for Cart Items
                Text('Order Artifacts (${cartController.checkoutItems.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...cartController.checkoutItems.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: _glassCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(item.product.images.isNotEmpty 
                                ? AppConstants.getImageUrl(item.product.images[0]) 
                                : ''),
                              fit: BoxFit.cover,
                            )
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${item.quantity} x Rs. ${item.product.price}'),
                            ],
                          ),
                        ),
                        Text('Rs. ${(item.product.price * item.quantity).toStringAsFixed(0)}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      ],
                    ),
                  ),
                )),

                const SizedBox(height: 20),
                const Text('Payment Gateway', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                // Z-Pay Wallet Option
                GestureDetector(
                  onTap: () => setState(() => selectedPayment = 'z_pay'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: selectedPayment == 'z_pay' 
                        ? const LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent])
                        : null,
                      color: selectedPayment == 'z_pay' ? null : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: selectedPayment == 'z_pay' ? Colors.transparent : Colors.grey.withOpacity(0.3)),
                      boxShadow: selectedPayment == 'z_pay' 
                        ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))] 
                        : [],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Z-Pay Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Obx(() {
                                final balance = Get.find<AuthController>().user.value?.walletBalance ?? 0.0;
                                return Row(
                                  children: [
                                    Text('Balance: Rs. ${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => Get.find<AuthController>().fetchProfile(),
                                      child: const Icon(Icons.refresh, color: Colors.white70, size: 14),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                        if (selectedPayment == 'z_pay')
                          const Icon(Icons.check_circle, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // COD Option
                GestureDetector(
                  onTap: () => setState(() => selectedPayment = 'cod'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: selectedPayment == 'cod' 
                        ? const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF64DD17)])
                        : null,
                      color: selectedPayment == 'cod' ? null : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: selectedPayment == 'cod' ? Colors.transparent : Colors.grey.withOpacity(0.3)),
                      boxShadow: selectedPayment == 'cod' 
                        ? [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))] 
                        : [],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Cash on Delivery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        if (selectedPayment == 'cod')
                          const Icon(Icons.check_circle, color: Colors.white),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 100), // Spacing for bottom bar
              ],
            ),
          ),
          
          // Bottom Payment Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.5))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount', style: TextStyle(color: Colors.grey)),
                          Text('Rs. ${cartController.totalAmount}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Obx(() => SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isPlacingOrder.value ? null : _processPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 10,
                            shadowColor: Colors.black26,
                          ),
                          child: isPlacingOrder.value 
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                  const SizedBox(width: 12),
                                  Text(selectedPayment == 'z_pay' ? "Securing Transaction..." : "Placing Order...", style: const TextStyle(color: Colors.white)),
                                ],
                              )
                            : const Text("PAY NOW", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child, EdgeInsets? padding, Color? color, BoxBorder? border}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color ?? Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: border ?? Border.all(color: Colors.white.withOpacity(0.4)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 1)],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 13),
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 18),
      ),
    );
  }

  Widget _glowCircle(Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.3),
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 10)],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty || cityController.text.isEmpty || addressController.text.isEmpty) {
      Get.snackbar('Alert', 'Please fill all shipping details!', backgroundColor: Colors.red.withOpacity(0.8), colorText: Colors.white);
      return;
    }

    isPlacingOrder.value = true;

    try {
      // 1. Simulate "Securing connection" time for Z-Pay
      if (selectedPayment == 'z_pay') {
        await Future.delayed(const Duration(seconds: 2));
      }

      // 2. Create Order
      final orderData = {
        'full_name': nameController.text,
        'phone': phoneController.text,
        'city': cityController.text,
        'area': areaController.text,
        'shipping_address': addressController.text,
        'payment_method': selectedPayment,
        'shipping_address_id': null,
        'items': cartController.checkoutItems.map((item) => {
          'product_id': item.product.id,
          'quantity': item.quantity,
          'price': item.product.price,
          'shop_id': item.product.shopId,
        }).toList(),
      };

      final createRes = await ApiClient.post('/checkout', orderData);
      print('Checkout Response: ${createRes.body}');
      
      if (createRes.statusCode != 200 && createRes.statusCode != 201) {
        String errorMessage = "Order creation failed";
        try {
          final errorBody = jsonDecode(createRes.body);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = "Server Error (HTML). Check logs.";
        }
        throw errorMessage;
      }

      final createData = jsonDecode(createRes.body);
      final orderId = createData['data']['id'];
      final orderNumber = createData['data']['order_number'];

      // 3. If Z-Pay, Call Mock Pay
      if (selectedPayment == 'z_pay') {
        final payRes = await ApiClient.post('/order/mock-pay', {'order_id': orderId});
        print('MockPay Response: ${payRes.body}');
        if (payRes.statusCode != 200) {
          String payError = "Payment Gateway Error";
          try {
            final payBody = jsonDecode(payRes.body);
            payError = payBody['message'] ?? payError;
          } catch (_) {
            payError = "Payment Server Error (HTML).";
          }
          throw payError;
        }
      }

      // 4. Success Navigation
      cartController.clearCart();
      Get.offAll(() => OrderSuccessScreen(orderId: orderNumber));

    } catch (e) {
      String displayError = e.toString();
      // If it looks like HTML error, try to extract a snippet
      if (displayError.contains('unexpected token \'<\'')) {
         displayError = "Backend Server Error (500). Please check Laravel logs.";
      }
      Get.snackbar('Error', displayError, 
        backgroundColor: Colors.red.withOpacity(0.8), 
        colorText: Colors.white,
        duration: const Duration(seconds: 5)
      );
    } finally {
      isPlacingOrder.value = false;
    }
  }
}

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0, end: 1),
              curve: Curves.elasticOut,
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 50),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            const Text("Payment Successful!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Order ID: $orderId", style: const TextStyle(fontSize: 16, color: Colors.grey, letterSpacing: 1.2)),
            
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () => Get.offAll(() => const HomeScreen()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("CONTINUE SHOPPING", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
