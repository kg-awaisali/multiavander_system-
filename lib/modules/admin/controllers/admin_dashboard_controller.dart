import 'dart:convert';
import 'package:get/get.dart';
import '../../../../core/api_client.dart';
import '../../notifications/controllers/notification_controller.dart';

class AdminDashboardController extends GetxController {
  var isLoading = false.obs;
  var totalBuyers = 0.obs;
  var totalSellers = 0.obs;
  var totalProducts = 0.obs;
  var totalOrders = 0.obs;
  var totalRevenue = 0.0.obs;
  var pendingSellers = 0.obs;
  
  // Lists for Recent Activity
  var recentOrders = <Map<String, dynamic>>[].obs;
  var topSellingProducts = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    Get.put(NotificationController());
    fetchDashboardStats();
  }

  void fetchDashboardStats() async {
    isLoading.value = true;
    try {
      final response = await ApiClient.get('/admin/stats');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stats = data['stats'];
        
        totalBuyers.value = stats['total_buyers'];
        totalSellers.value = stats['total_sellers'];
        totalProducts.value = stats['total_products'];
        totalOrders.value = stats['total_orders'];
        totalRevenue.value = double.tryParse(stats['total_revenue'].toString()) ?? 0.0;
        pendingSellers.value = stats['pending_sellers'];
        
        if (data['recent_orders'] != null) {
          recentOrders.assignAll(List<Map<String, dynamic>>.from(data['recent_orders']));
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load stats: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
