import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/voucher_controller.dart';
import '../../../core/theme.dart';
import 'package:intl/intl.dart';

class VoucherListScreen extends StatelessWidget {
  const VoucherListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VoucherController());

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Manage Vouchers', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: () => _showAddVoucherDialog(context, controller),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsHeader(controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.vouchers.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.vouchers.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await controller.fetchVouchers();
                  await controller.fetchStats();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.vouchers.length,
                  itemBuilder: (context, index) {
                    final voucher = controller.vouchers[index];
                    return _buildVoucherCard(voucher, controller);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(VoucherController controller) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Total', controller.totalVouchers, Icons.local_offer_outlined),
          _statItem('Active', controller.activeVouchers, Icons.check_circle_outline, color: Colors.green),
          _statItem('Used', controller.totalUsed, Icons.shopping_bag_outlined, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _statItem(String label, RxInt value, IconData icon, {Color color = Colors.grey}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Obx(() => Text('${value.value}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildVoucherCard(VoucherModel voucher, VoucherController controller) {
    bool isExpired = voucher.endDate != null && voucher.endDate!.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Discount Badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        voucher.type == 'percentage' ? '${voucher.value.toInt()}%' : 'Rs',
                        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      if (voucher.type == 'fixed')
                        Text('${voucher.value.toInt()}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(voucher.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
                          const SizedBox(width: 8),
                          if (isExpired)
                            const Text('(Expired)', style: TextStyle(color: Colors.red, fontSize: 12))
                          else if (!voucher.isActive)
                            const Text('(Paused)', style: TextStyle(color: Colors.orange, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Min. Spend: Rs. ${voucher.minPurchase.toStringAsFixed(0)}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      if (voucher.endDate != null)
                        Text(
                          'Valid until: ${DateFormat.yMMMd().format(voucher.endDate!)}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                // Actions
                Column(
                  children: [
                    Switch(
                      value: voucher.isActive && !isExpired,
                      onChanged: isExpired ? null : (val) => controller.toggleStatus(voucher.id),
                      activeColor: AppTheme.primaryColor,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                      onPressed: () => _confirmDelete(voucher, controller),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Progress Bar (Usage)
          if (voucher.usageLimit != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Usage Status', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text('${voucher.usedCount}/${voucher.usageLimit}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: voucher.usedCount / voucher.usageLimit!,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        (voucher.usedCount / voucher.usageLimit!) > 0.9 ? Colors.red : AppTheme.primaryColor
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Create your first voucher!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Attract more customers with great discounts.', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  void _confirmDelete(VoucherModel voucher, VoucherController controller) {
    Get.defaultDialog(
      title: 'Delete Voucher?',
      middleText: 'Are you sure you want to delete ${voucher.code}?',
      textConfirm: 'DELETE',
      textCancel: 'CANCEL',
      confirmTextColor: Colors.white,
      onConfirm: () {
        controller.deleteVoucher(voucher.id);
        Get.back();
      },
    );
  }

  void _showAddVoucherDialog(BuildContext context, VoucherController controller) {
    final codeController = TextEditingController();
    final valueController = TextEditingController();
    final minSpendController = TextEditingController();
    final limitController = TextEditingController();
    String selectedType = 'percentage';
    
    Get.dialog(
      AlertDialog(
        title: const Text('Create New Voucher'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Voucher Code (Optional)', hintText: 'e.g. SUMMER20'),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                items: const [
                  DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                  DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount (Rs)')),
                ],
                onChanged: (val) => selectedType = val!,
                decoration: const InputDecoration(labelText: 'Voucher Type'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Discount Value'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: minSpendController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Minimum Purchase Amount (Rs)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: limitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Usage Limit (Optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (valueController.text.isEmpty) {
                Get.snackbar('Error', 'Please enter discount value');
                return;
              }
              
              final data = {
                'code': codeController.text.isNotEmpty ? codeController.text : null,
                'type': selectedType,
                'value': double.parse(valueController.text),
                'min_purchase': minSpendController.text.isNotEmpty ? double.parse(minSpendController.text) : 0,
                'usage_limit': limitController.text.isNotEmpty ? int.parse(limitController.text) : null,
                'start_date': DateTime.now().toIso8601String(),
                'end_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(), // Default 30 days
              };
              
              controller.createVoucher(data);
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }
}
