import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/api_client.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/flash_sale_model.dart';

class AdminFlashSaleController extends GetxController {
  var isLoading = false.obs;
  var allProducts = <ProductModel>[].obs;
  var flashSales = <FlashSaleModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
    fetchFlashSales();
  }

  Future<void> fetchProducts() async {
    final res = await ApiClient.get('/products');
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body)['data'];
      allProducts.value = data.map((e) => ProductModel.fromJson(e)).toList();
    }
  }

  Future<void> fetchFlashSales() async {
    isLoading.value = true;
    try {
      final res = await ApiClient.get('/flash-sales/active');
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body)['data'];
        flashSales.value = data.map((e) => FlashSaleModel.fromJson(e)).toList();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createFlashSale({
    required int productId,
    required double flashPrice,
    required int stockLimit,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    isLoading.value = true;
    try {
      final res = await ApiClient.post('/admin/flash-sales', {
        'product_id': productId,
        'flash_price': flashPrice,
        'stock_limit': stockLimit,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
      });

      if (res.statusCode == 200) {
        Get.snackbar("Success", "Flash Sale campaign created!");
        fetchFlashSales();
        return true;
      } else {
        final msg = jsonDecode(res.body)['message'] ?? "Error creating campaign";
        Get.snackbar("Error", msg);
        return false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteFlashSale(int id) async {
    isLoading.value = true;
    try {
      final res = await ApiClient.delete('/admin/flash-sales/$id');
      if (res.statusCode == 200) {
        Get.snackbar("Success", "Flash Sale deleted.");
        fetchFlashSales();
        return true;
      } else {
        Get.snackbar("Error", "Failed to delete.");
        return false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> toggleFlashSaleStatus(int id) async {
    try {
      final res = await ApiClient.post('/admin/flash-sales/$id/toggle', {});
      if (res.statusCode == 200) {
        Get.snackbar("Success", "Status updated.");
        fetchFlashSales();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
