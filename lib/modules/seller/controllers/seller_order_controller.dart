import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/api_client.dart';

class SellerOrderController extends GetxController {
  var isLoading = false.obs;
  var orders = <Map<String, dynamic>>[].obs;
  var orderStats = <String, dynamic>{}.obs;
  var selectedStatus = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
    fetchOrderStats();
  }

  Future<void> fetchOrders({String? status}) async {
    isLoading.value = true;
    try {
      String url = '/seller/orders';
      if (status != null && status != 'all') {
        url += '?status=$status';
      }
      
      final response = await ApiClient.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        orders.assignAll(List<Map<String, dynamic>>.from(data['data'] ?? []));
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load orders: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchOrderStats() async {
    try {
      final response = await ApiClient.get('/seller/order-stats');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        orderStats.value = Map<String, dynamic>.from(data['stats'] ?? {});
      }
    } catch (e) {
      print('Order stats error: $e');
    }
  }

  Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await ApiClient.post('/seller/orders/$orderId/status', {'status': status});
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Order status updated to $status', backgroundColor: Colors.green.shade100);
        fetchOrders(status: selectedStatus.value);
        fetchOrderStats();
        return true;
      } else {
        Get.snackbar('Error', 'Failed to update status', backgroundColor: Colors.red.shade100);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Network error: $e', backgroundColor: Colors.red.shade100);
      return false;
    }
  }

  void filterByStatus(String status) {
    selectedStatus.value = status;
    fetchOrders(status: status);
  }
}
