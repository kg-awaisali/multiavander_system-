import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/seller_earnings_controller.dart';
import '../../../core/theme.dart';

class SellerEarningsScreen extends StatelessWidget {
  const SellerEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerEarningsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings & Payouts', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.fetchEarnings();
            await controller.fetchPayoutHistory();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wallet Balance Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          Icon(Icons.account_balance_wallet, color: Colors.white.withOpacity(0.5), size: 32),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rs. ${controller.walletBalance.value.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showPayoutDialog(context, controller),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Request Payout'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stats Row
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Total Earnings', controller.totalEarnings.value, Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Pending Payouts', controller.pendingPayouts.value, Colors.orange)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Completed Payouts', controller.completedPayouts.value, Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: Container()), // Placeholder for balance
                  ],
                ),
                const SizedBox(height: 24),

                // Payout History
                const Text('Payout History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                if (controller.payoutHistory.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text('No payout history', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                else
                  ...controller.payoutHistory.map((payout) => _buildPayoutCard(payout, controller)).toList(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatCard(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 4),
          Text('Rs. ${value.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        ],
      ),
    );
  }

  Widget _buildPayoutCard(Map<String, dynamic> payout, SellerEarningsController controller) {
    final status = payout['status']?.toString() ?? 'pending';
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(_getStatusIcon(status), color: statusColor, size: 20),
        ),
        title: Text('Rs. ${payout['amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(payout['payment_method']?.toString().replaceAll('_', ' ').capitalizeFirst ?? 'Bank Transfer'),
            Text(payout['requested_at']?.toString().split('T')[0] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            if (status == 'pending')
              TextButton(
                onPressed: () => controller.cancelPayout(payout['id']),
                child: const Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'processing': return Colors.blue;
      case 'completed': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.hourglass_empty;
      case 'processing': return Icons.sync;
      case 'completed': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      default: return Icons.payment;
    }
  }

  void _showPayoutDialog(BuildContext context, SellerEarningsController controller) {
    final amountController = TextEditingController();
    String selectedMethod = 'bank_transfer';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: 'Rs. ',
                border: const OutlineInputBorder(),
                helperText: 'Min: Rs. 100 | Available: Rs. ${controller.walletBalance.value.toStringAsFixed(0)}',
              ),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) => DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'jazzcash', child: Text('JazzCash')),
                  DropdownMenuItem(value: 'easypaisa', child: Text('EasyPaisa')),
                ],
                onChanged: (v) => setState(() => selectedMethod = v!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount >= 100) {
                Navigator.pop(context);
                await controller.requestPayout(amount, selectedMethod);
              } else {
                Get.snackbar('Error', 'Minimum payout is Rs. 100');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
