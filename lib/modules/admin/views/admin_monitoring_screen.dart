import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_campaign_controller.dart';
import '../../../core/theme.dart';

class AdminMonitoringScreen extends StatelessWidget {
  const AdminMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminCampaignController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Sale Monitoring", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        if (controller.monitorSales.isEmpty) return const Center(child: Text("No live sales to monitor."));

        return ListView.builder(
          itemCount: controller.monitorSales.length,
          itemBuilder: (context, index) {
            final sale = controller.monitorSales[index];
            final product = sale.product;
            if (product == null) return const SizedBox.shrink();

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: Image.network(product.images.isNotEmpty ? product.images[0] : '', width: 50, height: 50, fit: BoxFit.cover),
                title: Text(product.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: sale.soldPercentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(sale.isSoldOut ? Colors.grey : AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 4),
                    Text("Sold: ${sale.soldCount} / ${sale.stockLimit} (${(sale.soldPercentage * 100).toStringAsFixed(1)}%)"),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                   IconButton(
                      icon: Icon(
                        sale.status == 'active' ? Icons.visibility : Icons.visibility_off,
                        color: sale.status == 'active' ? Colors.green : Colors.grey,
                      ),
                      onPressed: () => controller.toggleStatus(sale.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => controller.deleteSale(sale.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
