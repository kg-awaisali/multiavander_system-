import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/views/login_screen.dart';
import '../../seller/views/seller_dashboard_screen.dart';
import '../../cart/views/my_orders_screen.dart';
import '../../admin/views/admin_dashboard_screen.dart';
import '../../../core/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('My Account', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Obx(() {
        final user = authController.user.value;
        if (user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_circle_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('Please login to view your account', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Get.to(() => LoginScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Login / Signup', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
            children: [
              // User Info Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        user.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(user.email, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    
                    // Wallet Balance Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Z-Pay Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text('Rs. ${user.walletBalance.toStringAsFixed(2)}', 
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: () => authController.fetchProfile(),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.role == 1 ? 'Administrator' : (user.role == 2 ? 'Seller' : 'Customer'),
                        style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Account Options
              _buildSection(
                title: 'General',
                items: [
                  _buildItem(Icons.shopping_bag_outlined, 'My Orders', onTap: () => Get.to(() => const MyOrdersScreen())),
                  _buildItem(Icons.favorite_border, 'Wishlist', onTap: () {}),
                  _buildItem(Icons.location_on_outlined, 'Shipping Address', onTap: () {}),
                ],
              ),
              const SizedBox(height: 12),

              if (user.role == 1 || user.role == 2)
                _buildSection(
                  title: 'Management',
                  items: [
                    if (user.role == 1)
                      _buildItem(Icons.admin_panel_settings_outlined, 'Admin Dashboard', onTap: () => Get.to(() => const AdminDashboardScreen())),
                    if (user.role == 2)
                      _buildItem(Icons.dashboard_customize_outlined, 'Seller Dashboard', onTap: () => Get.to(() => const SellerDashboardScreen())),
                  ],
                ),
              
              const SizedBox(height: 12),
              _buildSection(
                title: 'Support',
                items: [
                  _buildItem(Icons.help_outline, 'Help Center', onTap: () {}),
                  _buildItem(Icons.privacy_tip_outlined, 'Privacy Policy', onTap: () {}),
                ],
              ),
              const SizedBox(height: 24),
              
              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => authController.logout(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ));
      }),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String title, {required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
