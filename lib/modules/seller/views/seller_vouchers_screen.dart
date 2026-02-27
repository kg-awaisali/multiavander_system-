import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/seller_voucher_controller.dart';
import '../../../core/theme.dart';

class SellerVouchersScreen extends StatelessWidget {
  const SellerVouchersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerVoucherController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vouchers', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateVoucherDialog(context, controller),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.vouchers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_offer, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('No vouchers yet'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _showCreateVoucherDialog(context, controller),
                  child: const Text('Create First Voucher'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: controller.vouchers.length,
          itemBuilder: (context, index) {
            final voucher = controller.vouchers[index];
            return _buildVoucherCard(voucher, controller, context);
          },
        );
      }),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher, SellerVoucherController controller, BuildContext context) {
    final isActive = voucher['is_active'] == true || voucher['is_active'] == 1;
    final type = voucher['type']?.toString() ?? 'percentage';
    final value = voucher['value']?.toString() ?? '0';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    voucher['code'] ?? 'CODE',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type == 'percentage' ? '$value% OFF' : 'Rs. $value OFF',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (voucher['min_purchase'] != null && voucher['min_purchase'] > 0)
                        Text('Min purchase: Rs. ${voucher['min_purchase']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (v) => controller.toggleVoucher(voucher['id']),
                  activeColor: Colors.green,
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Used: ${voucher['used_count'] ?? 0}${voucher['usage_limit'] != null ? '/${voucher['usage_limit']}' : ''}',
                    style: TextStyle(color: Colors.grey.shade600)),
                Row(
                  children: [
                    if (voucher['end_date'] != null)
                      Text('Expires: ${voucher['end_date'].toString().split('T')[0]}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => controller.deleteVoucher(voucher['id']),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateVoucherDialog(BuildContext context, SellerVoucherController controller) {
    final codeController = TextEditingController();
    final valueController = TextEditingController();
    final minPurchaseController = TextEditingController();
    final maxDiscountController = TextEditingController();
    final usageLimitController = TextEditingController();
    String type = 'percentage';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Create Voucher', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: codeController,
                        decoration: const InputDecoration(labelText: 'Voucher Code (optional)', border: OutlineInputBorder(), hintText: 'Auto-generated if empty'),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: type,
                        decoration: const InputDecoration(labelText: 'Discount Type', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                          DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount (Rs.)')),
                        ],
                        onChanged: (v) => setState(() => type = v!),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: valueController,
                        decoration: InputDecoration(
                          labelText: type == 'percentage' ? 'Discount Percentage' : 'Discount Amount',
                          border: const OutlineInputBorder(),
                          suffixText: type == 'percentage' ? '%' : 'Rs.',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: minPurchaseController,
                        decoration: const InputDecoration(labelText: 'Minimum Purchase (Rs.)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      if (type == 'percentage')
                        Column(
                          children: [
                            TextField(
                              controller: maxDiscountController,
                              decoration: const InputDecoration(labelText: 'Maximum Discount (Rs.)', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      TextField(
                        controller: usageLimitController,
                        decoration: const InputDecoration(labelText: 'Usage Limit (optional)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16)),
                          onPressed: () async {
                            final success = await controller.createVoucher({
                              if (codeController.text.isNotEmpty) 'code': codeController.text,
                              'type': type,
                              'value': double.tryParse(valueController.text) ?? 0,
                              'min_purchase': double.tryParse(minPurchaseController.text) ?? 0,
                              if (maxDiscountController.text.isNotEmpty) 'max_discount': double.tryParse(maxDiscountController.text),
                              if (usageLimitController.text.isNotEmpty) 'usage_limit': int.tryParse(usageLimitController.text),
                            });
                            if (success) Navigator.pop(context);
                          },
                          child: const Text('Create Voucher', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
