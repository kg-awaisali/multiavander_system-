import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/wallet_controller.dart';
import '../../../core/theme.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WalletController());

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('My Wallet', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: controller.fetchStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              _buildBalanceCard(controller),
              
              const SizedBox(height: 24),
              const Text('Recent Payouts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              // Payouts List
              Obx(() {
                if (controller.isLoading.value && controller.recentPayouts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (controller.recentPayouts.isEmpty) {
                  return _buildEmptyHistory();
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.recentPayouts.length,
                  itemBuilder: (context, index) {
                    final payout = controller.recentPayouts[index];
                    return _buildPayoutTile(payout);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(WalletController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFFE65100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const Icon(Icons.account_balance_wallet, color: Colors.white54),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() => Text(
            'Rs. ${controller.balance.value.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          )),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Pending: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Obx(() => Text(
                'Rs. ${controller.pendingPayouts.value.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              )),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showWithdrawDialog(controller),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('WITHDRAW MONEY', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutTile(PayoutRecord payout) {
    Color statusColor;
    switch (payout.status) {
      case 'paid': statusColor = Colors.green; break;
      case 'approved': statusColor = Colors.blue; break;
      case 'rejected': statusColor = Colors.red; break;
      default: statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rs. ${payout.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '${payout.method.toUpperCase()} • ${DateFormat.yMMMd().format(payout.createdAt)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              payout.status.toUpperCase(),
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.history, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No payout history found', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog(WalletController controller) {
    final amountController = TextEditingController();
    final detailsController = TextEditingController();
    String selectedMethod = 'bank_transfer';

    Get.dialog(
      AlertDialog(
        title: const Text('Withdraw Funds'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (Rs)', hintText: 'Min 100'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                items: const [
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'jazzcash', child: Text('JazzCash')),
                  DropdownMenuItem(value: 'easypaisa', child: Text('EasyPaisa')),
                ],
                onChanged: (val) => selectedMethod = val!,
                decoration: const InputDecoration(labelText: 'Payment Method'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: detailsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Account Details',
                  hintText: 'Acc Title, Number, Bank Name, IBAN etc.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount < 100) {
                Get.snackbar('Invalid Amount', 'Minimum withdrawal is Rs. 100');
                return;
              }
              controller.requestPayout(amount, selectedMethod, detailsController.text);
            },
            child: const Text('SUBMIT REQUEST'),
          ),
        ],
      ),
    );
  }
}
