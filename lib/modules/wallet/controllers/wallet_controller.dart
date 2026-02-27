import 'dart:convert';
import 'package:get/get.dart';
import '../../../core/api_client.dart';

class PayoutRecord {
  final int id;
  final double amount;
  final String status;
  final String method;
  final DateTime createdAt;
  final String? rejectionReason;

  PayoutRecord({
    required this.id,
    required this.amount,
    required this.status,
    required this.method,
    required this.createdAt,
    this.rejectionReason,
  });

  factory PayoutRecord.fromJson(Map<String, dynamic> json) {
    return PayoutRecord(
      id: json['id'],
      amount: double.parse(json['amount'].toString()),
      status: json['status'],
      method: json['payment_method'] ?? json['method'] ?? 'N/A',
      createdAt: DateTime.parse(json['requested_at'] ?? json['created_at']),
      rejectionReason: json['rejection_reason'],
    );
  }
}

class WalletController extends GetxController {
  var balance = 0.0.obs;
  var pendingPayouts = 0.0.obs;
  var recentPayouts = <PayoutRecord>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchStats();
  }

  Future<void> fetchStats() async {
    try {
      isLoading.value = true;
      final response = await ApiClient.get('/seller/wallet/stats'); // Or /seller/earnings
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stats = data['data'] ?? data; // handle different API structures
        
        balance.value = double.parse((stats['balance'] ?? stats['wallet_balance'] ?? 0).toString());
        pendingPayouts.value = double.parse((stats['pending_payouts'] ?? 0).toString());
        
        final List payoutsJson = stats['recent_payouts'] ?? stats['payouts']?['data'] ?? [];
        recentPayouts.assignAll(payoutsJson.map((e) => PayoutRecord.fromJson(e)).toList());
      }
    } catch (e) {
      print('Wallet stats error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> requestPayout(double amount, String method, String details) async {
    try {
      isLoading.value = true;
      final response = await ApiClient.post('/seller/wallet/payout', {
        'amount': amount,
        'method': method,
        'account_details': details,
      });

      if (response.statusCode == 200) {
        Get.back();
        Get.snackbar('Success', 'Payout request submitted', backgroundColor: Get.theme.primaryColor.withOpacity(0.1));
        fetchStats(); // Refresh
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar('Error', data['message'] ?? 'Failed to submit request');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred');
    } finally {
      isLoading.value = false;
    }
  }
}
