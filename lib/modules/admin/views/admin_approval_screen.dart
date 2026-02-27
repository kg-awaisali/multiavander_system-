import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_campaign_controller.dart';
import '../../../core/theme.dart';

class AdminApprovalScreen extends StatelessWidget {
  const AdminApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminCampaignController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Nominations", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        if (controller.pendingSales.isEmpty) return const Center(child: Text("No pending nominations."));

        return ListView.builder(
          itemCount: controller.pendingSales.length,
          itemBuilder: (context, index) {
            final sale = controller.pendingSales[index];
            final product = sale.product;
            if (product == null) return const SizedBox.shrink();

            return Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ListTile(
                      leading: Image.network(product.images.isNotEmpty ? product.images[0] : '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.flash_on)),
                      title: Text(product.name),
                      subtitle: Text("Rs. ${product.price} -> Flash: Rs. ${sale.flashPrice}"),
                    ),
                    const Divider(),
                    const Text("Campaign: ", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text(sale.campaignName ?? "No Campaign"),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => controller.rejectSale(sale.id),
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text("Reject", style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => controller.approveSale(sale.id),
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text("Approve"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ],
                    )
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
