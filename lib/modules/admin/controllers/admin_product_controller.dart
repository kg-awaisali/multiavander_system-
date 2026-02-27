import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api_client.dart';
import '../../../../core/constants.dart';

class AdminProductController extends GetxController {
  var isLoading = false.obs;
  var products = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  void fetchProducts() async {
    isLoading.value = true;
    try {
      final response = await ApiClient.get('/admin/products');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Assuming Laravel pagination: {data: [...], current_page: 1, ...}
        final List list = data['data'];

        products.assignAll(list.map((p) {
          // Handle status - could be boolean (0/1), integer, or string ('active'/'banned')
          String statusStr = 'Active';
          var rawStatus = p['status'];
          if (rawStatus is String) {
            statusStr = _capitalize(rawStatus);
          } else if (rawStatus is int || rawStatus is bool) {
            statusStr = (rawStatus == 1 || rawStatus == true) ? 'Active' : 'Banned';
          }
          
          return {
            'id': p['id'],
            'name': (p['name'] ?? 'Unnamed').toString(),
            'description': (p['description'] ?? 'No description').toString(),
            'short_description': (p['short_description'] ?? '').toString(),
            'brand': (p['brand'] ?? 'N/A').toString(),
            'price': 'Rs. ${(p['price'] ?? 0).toString()}',
            'discounted_price': p['discounted_price'] != null ? 'Rs. ${p['discounted_price']}' : null,
            'stock': (p['stock'] ?? 0).toString(),
            'has_variations': p['has_variations'] == 1 || p['has_variations'] == true,
            'shop': p['shop'] != null ? (p['shop']['name'] ?? 'Unknown').toString() : 'Unknown',
            'category': p['category'] != null ? (p['category']['name'] ?? 'N/A').toString() : 'N/A',
            'status': statusStr,
            'image': AppConstants.getImageUrl((p['images'] != null && (p['images'] is List) && (p['images'] as List).isNotEmpty) ? p['images'][0].toString() : null),
            'all_images': (p['images'] is List) ? (p['images'] as List).map((img) => AppConstants.getImageUrl(img.toString())).toList() : [],
          };
        }).toList());
      } else {
        Get.snackbar('Error', 'Failed to fetch products: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch products: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String _capitalize(String s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '';

  void toggleStatus(int id) async {
     // Determine current status to toggle
     int index = products.indexWhere((p) => p['id'] == id);
     if(index == -1) return;
     
     String currentStatus = products[index]['status'].toString().toLowerCase();
     String newStatus = currentStatus == 'active' ? 'banned' : 'active';
     
     try {
       final response = await ApiClient.post('/admin/products/$id/status', {'status': newStatus});
       if(response.statusCode == 200) {
          var p = products[index];
          p['status'] = _capitalize(newStatus);
          products[index] = p;
          products.refresh();
          Get.snackbar('Success', 'Product status changed to $newStatus', backgroundColor: Colors.green.shade100);
       } else {
          final data = jsonDecode(response.body);
          Get.snackbar('Error', data['message'] ?? 'Failed to update status', backgroundColor: Colors.red.shade100);
       }
     } catch (e) {
        Get.snackbar('Error', 'Network Error: $e', backgroundColor: Colors.red.shade100);
     }
  }
}
