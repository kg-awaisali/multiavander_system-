import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../widgets/admin_drawer.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../../core/theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminDashboardController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Neutral modern background
      drawer: const AdminDrawer(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF57224)));
        }

        return CustomScrollView(
          slivers: [
            // 1. Premium Gradient Header
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text("Control Center", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primaryColor, Color(0xFF2575FC)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        top: -50,
                        child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.05)),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -30,
                        child: CircleAvatar(radius: 70, backgroundColor: Colors.white.withOpacity(0.03)),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              "PKR ${controller.totalRevenue.value}",
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                            Text(
                              "TOTAL REVENUE",
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: controller.fetchDashboardStats,
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none),
                      onPressed: () => Get.toNamed('/notifications'),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Obx(() {
                        if (!Get.isRegistered<NotificationController>()) return const SizedBox();
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

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Summary Stats Section
                    const Text("Quick Stats", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      childAspectRatio: 1.4,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _ZStatCard("Orders", "${controller.totalOrders.value}", Icons.shopping_basket_rounded, AppTheme.primaryColor),
                        _ZStatCard("Sellers", "${controller.totalSellers.value}", Icons.storefront_rounded, AppTheme.accentColor),
                        _ZStatCard("Buyers", "${controller.totalBuyers.value}", Icons.people_alt_rounded, AppTheme.deepGold),
                        _ZStatCard("Pending", "${controller.pendingSellers.value}", Icons.hourglass_empty_rounded, Colors.purple.shade300),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // 3. Pending Action Banner
                    if (controller.pendingSellers.value > 0)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade50, Colors.orange.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.notification_important_rounded, color: Colors.orange),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Action Required", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text("${controller.pendingSellers.value} seller requests await approval", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Get.toNamed('/admin/sellers'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text("View"),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 30),

                    // 4. Recent Activity Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Recent Orders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
                        TextButton(onPressed: () {}, child: const Text("See All")),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: controller.recentOrders.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
                        itemBuilder: (context, index) {
                          final order = controller.recentOrders[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryColor, size: 20),
                            ),
                            title: Text(order['user'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text("ID: ${order['id'].toString().length > 8 ? order['id'].toString().substring(0, 8) : order['id']}...", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(order['amount'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(order['status']).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    order['status'],
                                    style: TextStyle(color: _getStatusColor(order['status']), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'Pending') return const Color(0xFFFD9644);
    if (status == 'Delivered') return const Color(0xFF26DE81);
    return const Color(0xFF45AAF2);
  }
}

class _ZStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ZStatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, size: 60, color: color.withOpacity(0.05)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
