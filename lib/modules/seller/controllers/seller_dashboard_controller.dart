import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/api_client.dart';

import '../../notifications/controllers/notification_controller.dart';

class SellerDashboardController extends GetxController {
  var isLoading = false.obs;
  var stats = <String, dynamic>{}.obs;
  var shop = <String, dynamic>{}.obs;
  var salesData = <Map<String, dynamic>>[].obs;
  var inventoryAlerts = <Map<String, dynamic>>[].obs;
  
  var shopStatus = 'approved'.obs; // Default to approved so it doesn't flicker
  var blockMessage = ''.obs;
  var rejectionReason = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    isLoading.value = true;
    try {
      final response = await ApiClient.get('/seller/dashboard');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        stats.value = Map<String, dynamic>.from(data['stats'] ?? {});
        shop.value = Map<String, dynamic>.from(data['shop'] ?? {});
        shopStatus.value = 'approved';
        
        // Refresh notifications too
        if (Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>().fetchNotifications();
        }
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        shopStatus.value = data['shop_status'] ?? 'pending';
        blockMessage.value = data['message'] ?? 'Access Restricted';
        rejectionReason.value = data['rejection_reason'] ?? '';
      } else {
        Get.snackbar('Error', 'Failed to load dashboard');
      }
    } catch (e) {
      Get.snackbar('Error', 'Network error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSalesChart({int days = 7}) async {
    try {
      final response = await ApiClient.get('/seller/sales-chart?days=$days');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        salesData.assignAll(List<Map<String, dynamic>>.from(data['sales'] ?? []));
      }
    } catch (e) {
      print('Sales chart error: $e');
    }
  }

  Future<void> fetchInventoryAlerts() async {
    try {
      final response = await ApiClient.get('/seller/inventory-alerts');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        inventoryAlerts.assignAll(List<Map<String, dynamic>>.from(data['low_stock_variations'] ?? []));
      }
    } catch (e) {
      print('Inventory alerts error: $e');
    }
  }
}
