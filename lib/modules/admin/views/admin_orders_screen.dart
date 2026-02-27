import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_order_controller.dart';
import '../widgets/admin_drawer.dart';
import '../../../core/theme.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminOrderController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text("Order Control Hub", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor, Color(0xFF2575FC)],
            ),
          ),
        ),
      ),
      drawer: const AdminDrawer(),
      body: Obx(() {
        if (controller.isLoading.value) return Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));

        if (controller.orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text("No Orders Found", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.orders.length,
          itemBuilder: (context, index) {
            final order = controller.orders[index];
            final statusColor = _getStatusColor(order['status']);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ExpansionTile(
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.inventory_2_rounded, color: statusColor, size: 20),
                ),
                title: Text("#${order['id']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3436))),
                subtitle: Text("${order['user']} • ${order['date']}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(order['amount'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
                    Text("${order['items']} items", style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                  ],
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Management Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3436))),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (order['status'] != 'Pending')
                               _actionButton(controller, order['id'], "Pend", Colors.orange),
                            if (order['status'] != 'Shipped')
                               _actionButton(controller, order['id'], "Ship", Colors.blue),
                            if (order['status'] != 'Delivered')
                               _actionButton(controller, order['id'], "Deliver", Colors.green),
                            if (order['status'] != 'Cancelled')
                               _actionButton(controller, order['id'], "Cancel", Colors.red),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _actionButton(AdminOrderController controller, String id, String label, Color color) {
    return InkWell(
      onTap: () => controller.updateStatus(id, label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return const Color(0xFFFD9644);
      case 'Shipped': return const Color(0xFF45AAF2);
      case 'Delivered': return const Color(0xFF26DE81);
      case 'Cancelled': return const Color(0xFFEB3B5A);
      default: return Colors.grey;
    }
  }
}
