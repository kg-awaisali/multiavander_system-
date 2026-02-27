import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme.dart';
import '../views/admin_dashboard_screen.dart';
import '../views/admin_sellers_screen.dart'; // Will create next
import '../views/admin_products_screen.dart'; // Will create next
import '../views/admin_category_screen.dart';
import '../views/admin_orders_screen.dart';
import '../views/admin_payouts_screen.dart';
import '../views/admin_marketing_screen.dart';
import '../views/admin_flash_sale_hub.dart';
import '../views/admin_settings_screen.dart';
import '../views/admin_attributes_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/views/login_screen.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // SECURITY GUARD: Direct check on every drawer render
    final auth = Get.find<AuthController>();
    if (auth.user.value?.role != 1) { // 1 = Admin
       // Double check Logic if user is null (reload scenario)
       // For now, if role mismatch, kick out.
       Future.delayed(Duration.zero, () {
          if(auth.user.value != null && auth.user.value!.role != 1) {
             Get.snackbar('Unauthorized', 'Access Denied');
             Get.offAllNamed('/login');
          }
       });
    }

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(25), bottomRight: Radius.circular(25))),
      child: Column(
        children: [
          // 1. Premium Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryColor, Color(0xFF2575FC)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                    child: Image.network("https://cdn-icons-png.flaticon.com/512/2942/2942813.png", width: 35),
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Admin Panel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("control@zbardast.com", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // 2. Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              children: [
                _buildDrawerItem(Icons.dashboard_rounded, "Dashboard", () => Get.off(() => const AdminDashboardScreen()), Get.currentRoute == '/AdminDashboardScreen'),
                _buildDrawerItem(Icons.storefront_rounded, "Sellers Management", () => Get.off(() => const AdminSellersScreen()), Get.currentRoute == '/AdminSellersScreen'), 
                _buildDrawerItem(Icons.inventory_2_rounded, "Products", () => Get.off(() => const AdminProductsScreen()), Get.currentRoute == '/AdminProductsScreen'),
                _buildDrawerItem(Icons.category_rounded, "Categories", () => Get.off(() => const AdminCategoryScreen()), Get.currentRoute == '/AdminCategoryScreen'),
                _buildDrawerItem(Icons.shopping_cart_rounded, "Orders", () => Get.off(() => const AdminOrdersScreen()), Get.currentRoute == '/AdminOrdersScreen'), 
                _buildDrawerItem(Icons.payments_rounded, "Payouts", () => Get.off(() => const AdminPayoutsScreen()), Get.currentRoute == '/AdminPayoutsScreen'),
                _buildDrawerItem(Icons.campaign_rounded, "Marketing & Banners", () => Get.off(() => const AdminMarketingScreen()), Get.currentRoute == '/AdminMarketingScreen'),
                _buildDrawerItem(Icons.flash_on_rounded, "Flash Sale Hub", () => Get.to(() => const AdminFlashSaleHub()), Get.currentRoute == '/AdminFlashSaleHub'),
                _buildDrawerItem(Icons.list_alt_rounded, "Global Attributes", () => Get.off(() => const AdminAttributesScreen()), Get.currentRoute == '/AdminAttributesScreen'),

                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Divider(),
                ),
                
                _buildDrawerItem(Icons.settings_suggest_rounded, "Settings", () => Get.off(() => const AdminSettingsScreen()), Get.currentRoute == '/AdminSettingsScreen'),
                _buildDrawerItem(Icons.logout_rounded, "Logout", () {
                   Get.find<AuthController>().logout();
                }, false, isLogout: true),
              ],
            ),
          ),
          
          // 3. Version Info
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text("Zbardast Admin v1.0.2", style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, bool isSelected, {bool isLogout = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
        leading: Icon(
          icon, 
          color: isLogout ? Colors.red : (isSelected ? AppTheme.primaryColor : Colors.grey.shade600),
          size: 22,
        ),
        title: Text(
          title, 
          style: TextStyle(
            color: isLogout ? Colors.red : (isSelected ? AppTheme.primaryColor : Colors.grey.shade800),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
