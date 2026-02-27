import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/seller_dashboard_controller.dart';
import '../../../core/theme.dart';
import 'seller_products_screen.dart';
import 'seller_orders_screen.dart';
import 'seller_earnings_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../vouchers/views/voucher_list_screen.dart';
import '../../notifications/views/notification_screen.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../chat/views/chat_list_screen.dart';
import '../../chat/controllers/chat_controller.dart';

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerDashboardController());
    Get.put(NotificationController()); // Initialize notification controller

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          'Welcome, ${controller.shop['name'] ?? 'Seller'}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        )),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.fetchDashboard,
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () => Get.to(() => const NotificationScreen()),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Obx(() {
                  final nController = Get.find<NotificationController>();
                  if (nController.unreadCount.value == 0) return const SizedBox();
                  return Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${nController.unreadCount.value}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.shopStatus.value != 'approved') {
          return _buildRestrictionView(controller);
        }

        return RefreshIndicator(
          onRefresh: controller.fetchDashboard,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Text(
                  'Dashboard Overview',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),

                // Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    _buildStatCard('Products', controller.stats['total_products']?.toString() ?? '0', Icons.inventory_2, Colors.blue),
                    _buildStatCard('Orders', controller.stats['total_orders']?.toString() ?? '0', Icons.shopping_bag, Colors.orange),
                    _buildStatCard('Pending', controller.stats['pending_orders']?.toString() ?? '0', Icons.hourglass_empty, Colors.red),
                    _buildStatCard('Delivered', controller.stats['delivered_orders']?.toString() ?? '0', Icons.check_circle, Colors.green),
                  ],
                ),
                const SizedBox(height: 20),

                // Wallet Balance Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.green.shade400],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        'Rs. ${controller.stats['wallet_balance'] ?? controller.shop['wallet_balance'] ?? '0'}',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('Total Earnings: Rs. ${controller.stats['total_earnings'] ?? '0'}',
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Quick Actions
                const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton('Add Product', Icons.add_box, () {
                        Get.to(() => const SellerProductsScreen());
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton('View Orders', Icons.list_alt, () {
                        Get.to(() => const SellerOrdersScreen());
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton('Earnings', Icons.account_balance_wallet, () {
                        Get.to(() => const SellerEarningsScreen());
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton('Vouchers', Icons.local_offer, () {
                        Get.to(() => const VoucherListScreen());
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton('History', Icons.history, () {
                        // View history logic
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton('Inventory', Icons.warning_amber, () {
                        controller.fetchInventoryAlerts();
                        _showInventoryAlerts(context, controller);
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                       child: Obx(() {
                          final chatController = Get.put(ChatController());
                          return _buildActionButton(
                             'Messages', 
                             Icons.chat, 
                             () => Get.to(() => const ChatListScreen()),
                             badgeCount: chatController.totalUnreadCount.value
                          );
                       }),
                    ),
                    const SizedBox(width: 12),
                    const Spacer(), // Placeholder for even grid
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ),
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap, {int badgeCount = 0}) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppTheme.primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Icon(Icons.storefront, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text('Seller Dashboard', style: TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Get.back(),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('Products'),
            onTap: () {
              Get.back();
              Get.to(() => const SellerProductsScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Orders'),
            onTap: () {
              Get.back();
              Get.to(() => const SellerOrdersScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Earnings'),
            onTap: () {
              Get.back();
              Get.to(() => const SellerEarningsScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_offer),
            title: const Text('Vouchers'),
            onTap: () {
              Get.back();
              Get.to(() => const VoucherListScreen());
            },
          ),
            ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Get.back();
              Get.to(() => const NotificationScreen());
            },
          ),
          Obx(() {
             final chatController = Get.put(ChatController());
             return ListTile(
               leading: const Icon(Icons.chat_bubble_outline),
               title: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   const Text('Messages'),
                   if (chatController.totalUnreadCount.value > 0)
                     Container(
                       padding: const EdgeInsets.all(6),
                       decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                       child: Text(
                         '${chatController.totalUnreadCount.value}',
                         style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                       ),
                     ),
                 ],
               ),
               onTap: () {
                  Get.back();
                  Get.to(() => const ChatListScreen()); 
               },
             );
          }),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Get.find<AuthController>().logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictionView(SellerDashboardController controller) {
    bool isRejected = controller.shopStatus.value == 'rejected';
    bool isBlocked = controller.shopStatus.value == 'blocked';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRejected ? Icons.cancel : (isBlocked ? Icons.block : Icons.hourglass_top),
              size: 80,
              color: isRejected || isBlocked ? Colors.red : Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              isRejected ? 'Application Rejected' : (isBlocked ? 'Account Blocked' : 'Approval Pending'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              controller.blockMessage.value,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (isRejected && controller.rejectionReason.value.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    const Text('Reason for Rejection:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 8),
                    Text(controller.rejectionReason.value, style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: controller.fetchDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInventoryAlerts(BuildContext context, SellerDashboardController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Low Stock Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.inventoryAlerts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No low stock items! 🎉'),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: controller.inventoryAlerts.length,
                itemBuilder: (context, index) {
                  final alert = controller.inventoryAlerts[index];
                  return ListTile(
                    leading: const Icon(Icons.warning, color: Colors.orange),
                    title: Text(alert['product_name'] ?? ''),
                    subtitle: Text('${(alert['low_stock_variations'] as List?)?.length ?? 0} variations low on stock'),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
