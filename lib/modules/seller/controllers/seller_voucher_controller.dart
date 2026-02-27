import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/api_client.dart';

class SellerVoucherController extends GetxController {
  var isLoading = false.obs;
  var vouchers = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchVouchers();
  }

  Future<void> fetchVouchers() async {
    isLoading.value = true;
    try {
      final response = await ApiClient.get('/seller/vouchers');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        vouchers.assignAll(List<Map<String, dynamic>>.from(data['data'] ?? []));
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load vouchers');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createVoucher(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.post('/seller/vouchers', data);
      if (response.statusCode == 201) {
        Get.snackbar('Success', 'Voucher created!', backgroundColor: Colors.green.shade100);
        fetchVouchers();
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar('Error', 'Failed to create voucher');
      return false;
    }
  }

  Future<void> toggleVoucher(int id) async {
    try {
      await ApiClient.post('/seller/vouchers/$id/toggle', {});
      fetchVouchers();
    } catch (e) {
      Get.snackbar('Error', 'Failed to toggle voucher');
    }
  }

  Future<void> deleteVoucher(int id) async {
    try {
      await ApiClient.delete('/seller/vouchers/$id');
      fetchVouchers();
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete voucher');
    }
  }
}
