import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../home/views/home_screen.dart';
import '../../admin/views/admin_dashboard_screen.dart';
import '../../seller/views/seller_dashboard_screen.dart';
import 'signup_screen.dart';
import '../../../core/theme.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient.withOpacity(0.2),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            child: const Icon(Icons.rocket_launch_outlined, size: 60, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Smart shop',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32, 
                              fontWeight: FontWeight.w900, 
                              letterSpacing: 2,
                              color: AppTheme.primaryColor
                            ),
                          ),
                          const Text(
                            'The Future of Shopping',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 24), // Reduced from 48
                          
                          _buildFuturisticField(
                            controller: emailController,
                            label: 'Email Address',
                            icon: Icons.alternate_email,
                          ),
                          const SizedBox(height: 16),
                          _buildFuturisticField(
                            controller: passwordController,
                            label: 'Secure Password',
                            icon: Icons.lock_open_rounded,
                            isPassword: true,
                          ),
                          
                          const SizedBox(height: 32),
                          Obx(() => Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: AppTheme.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: authController.isLoading.value 
                                ? null 
                                : () async {
                                    if (await authController.login(emailController.text, passwordController.text)) {
                                      final userRole = authController.user.value?.role;
                                      if (userRole == 1) {
                                        Get.offAll(() => const AdminDashboardScreen());
                                      } else if (userRole == 2) {
                                        Get.offAll(() => const SellerDashboardScreen());
                                      } else {
                                        // Customer Login: Sync Cart
                                        try {
                                           final cartCtrl = Get.find<CartController>();
                                           await cartCtrl.syncLocalCartToServer(); // 1. Push guest items
                                           await cartCtrl.fetchCartFromServer();   // 2. Pull server items (merged)
                                        } catch(e) {
                                           print("Cart sync failed: $e");
                                        }
                                        
                                        Get.offAll(() => const HomeScreen());
                                      }
                                    }
                                  },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: authController.isLoading.value 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('LAUNCH APP', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            ),
                          )),
                          
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("No account?", style: TextStyle(color: Colors.grey)),
                              TextButton(
                                onPressed: () => Get.to(() => SignupScreen()),
                                child: const Text("SIGNAL UP", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          
                          TextButton(
                            onPressed: () => Get.to(() => const HomeScreen()),
                            child: const Text('EXPLORE AS GUEST', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: AppTheme.textPrimaryColor, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor.withOpacity(0.8), size: 20),
          border: UnderlineInputBorder( // Professional look as requested
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
