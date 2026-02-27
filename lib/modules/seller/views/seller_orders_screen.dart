import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/seller_order_controller.dart';
import '../../../core/theme.dart';

class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerOrderController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Order Stats Bar
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', controller.orderStats['total']?.toString() ?? '0', Colors.blue),
                _buildStatItem('Pending', controller.orderStats['pending']?.toString() ?? '0', Colors.orange),
                _buildStatItem('Shipped', controller.orderStats['shipped']?.toString() ?? '0', Colors.purple),
                _buildStatItem('Delivered', controller.orderStats['delivered']?.toString() ?? '0', Colors.green),
              ],
            ),
          )),

          // Filter Tabs
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['all', 'pending', 'confirmed', 'shipped', 'delivered', 'cancelled'].map((status) {
                  final isSelected = controller.selectedStatus.value == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(status.capitalizeFirst!),
                      selected: isSelected,
                      onSelected: (v) => controller.filterByStatus(status),
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                    ),
                  );
                }).toList(),
              ),
            ),
          )),

          // Orders List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('No orders yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.fetchOrders(status: controller.selectedStatus.value),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.orders.length,
                  itemBuilder: (context, index) {
                    final order = controller.orders[index];
                    return _buildOrderCard(order, controller, context);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, SellerOrderController controller, BuildContext context) {
    final status = order['status']?.toString() ?? 'pending';
    final statusColor = _getStatusColor(status);
    final items = order['items'] as List? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#ORD-${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(),

            // Customer Info
            Text('Customer: ${order['user']?['name'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('Date: ${order['created_at']?.toString().split('T')[0] ?? 'N/A'}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 8),

            // Items
            ...items.take(3).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text('• ${item['product']?['name'] ?? 'Item'}', style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    Text('x${item['quantity']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
            if (items.length > 3)
              Text('+ ${items.length - 3} more items...', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),

            const Divider(),

            // Total & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: Rs. ${order['total_amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: _buildActionButtons(order, controller, context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(Map<String, dynamic> order, SellerOrderController controller, BuildContext context) {
    final status = order['status']?.toString() ?? 'pending';
    final orderId = order['id'];

    switch (status) {
      case 'pending':
        return [
          _actionButton('Confirm', Colors.blue, () => controller.updateOrderStatus(orderId, 'confirmed')),
          const SizedBox(width: 8),
          _actionButton('Cancel', Colors.red, () => controller.updateOrderStatus(orderId, 'cancelled')),
        ];
      case 'confirmed':
        return [
          _actionButton('Ship', Colors.purple, () => controller.updateOrderStatus(orderId, 'shipped')),
        ];
      case 'shipped':
        return [
          _actionButton('Delivered', Colors.green, () => controller.updateOrderStatus(orderId, 'delivered')),
        ];
      default:
        return [];
    }
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}
