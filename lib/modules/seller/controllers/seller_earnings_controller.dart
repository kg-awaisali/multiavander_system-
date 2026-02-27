import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/api_client.dart';

class SellerEarningsController extends GetxController {
  var isLoading = false.obs;
  var walletBalance = 0.0.obs;
  var totalEarnings = 0.0.obs;
  var pendingPayouts = 0.0.obs;
  var completedPayouts = 0.0.obs;
  var payoutHistory = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchEarnings();
    fetchPayoutHistory();
  }

  Future<void> fetchEarnings() async {
    isLoading.value = true;
    try {
      final response = await ApiClient.get('/seller/earnings');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        walletBalance.value = double.tryParse(data['wallet_balance'].toString()) ?? 0.0;
        totalEarnings.value = double.tryParse(data['total_earnings'].toString()) ?? 0.0;
        pendingPayouts.value = double.tryParse(data['pending_payouts'].toString()) ?? 0.0;
        completedPayouts.value = double.tryParse(data['completed_payouts'].toString()) ?? 0.0;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load earnings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPayoutHistory() async {
    try {
      final response = await ApiClient.get('/seller/payouts');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        payoutHistory.assignAll(List<Map<String, dynamic>>.from(data['data'] ?? []));
      }
    } catch (e) {
      print('Payout history error: $e');
    }
  }

  Future<bool> requestPayout(double amount, String paymentMethod) async {
    try {
      final response = await ApiClient.post('/seller/payouts', {
        'amount': amount,
        'payment_method': paymentMethod,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar('Success', 'Payout request submitted', backgroundColor: Colors.green.shade100);
        fetchEarnings();
        fetchPayoutHistory();
        return true;
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar('Error', data['message'] ?? 'Failed to request payout', backgroundColor: Colors.red.shade100);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Network error: $e', backgroundColor: Colors.red.shade100);
      return false;
    }
  }

  Future<bool> cancelPayout(int payoutId) async {
    try {
      final response = await ApiClient.post('/seller/payouts/$payoutId/cancel', {});
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Payout cancelled', backgroundColor: Colors.green.shade100);
        fetchPayoutHistory();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
