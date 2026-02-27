import 'dart:convert';
import 'package:get/get.dart';
import '../../../core/api_client.dart';
import '../../../data/models/flash_sale_campaign_model.dart';
import '../../../data/models/flash_sale_model.dart';

class AdminCampaignController extends GetxController {
  var isLoading = false.obs;
  var campaigns = <FlashSaleCampaignModel>[].obs;
  var pendingSales = <FlashSaleModel>[].obs;
  var monitorSales = <FlashSaleModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCampaigns();
    fetchPendingApprovals();
    fetchMonitorSales();
  }

  Future<void> fetchCampaigns() async {
    isLoading.value = true;
    try {
      final res = await ApiClient.get('/admin/flash-sales/campaigns');
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body)['data'];
        campaigns.value = data.map((e) => FlashSaleCampaignModel.fromJson(e)).toList();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createCampaign(String name, DateTime start, DateTime end) async {
    isLoading.value = true;
    try {
      final res = await ApiClient.post('/admin/flash-sales/campaigns', {
        'name': name,
        'start_time': start.toIso8601String(),
        'end_time': end.toIso8601String(),
      });
      if (res.statusCode == 200) {
        Get.snackbar("Success", "Campaign slot created!");
        fetchCampaigns();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPendingApprovals() async {
    final res = await ApiClient.get('/admin/flash-sales/pending');
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body)['data'];
      pendingSales.value = data.map((e) => FlashSaleModel.fromJson(e)).toList();
    }
  }

  Future<void> approveSale(int id) async {
    final res = await ApiClient.post('/admin/flash-sales/$id/approve', {});
    if (res.statusCode == 200) {
      Get.snackbar("Approved", "Flash Sale is now active!");
      fetchPendingApprovals();
      fetchMonitorSales();
    }
  }

  Future<void> rejectSale(int id) async {
    final res = await ApiClient.post('/admin/flash-sales/$id/reject', {});
    if (res.statusCode == 200) {
      Get.snackbar("Rejected", "Nomination removed.");
      fetchPendingApprovals();
    }
  }

  Future<void> fetchMonitorSales() async {
    final res = await ApiClient.get('/admin/flash-sales/monitor');
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body)['data'];
      monitorSales.value = data.map((e) => FlashSaleModel.fromJson(e)).toList();
    }
  }

  Future<void> deleteSale(int id) async {
    try {
      final res = await ApiClient.delete('/admin/flash-sales/$id');
      if (res.statusCode == 200) {
        Get.snackbar("Deleted", "Flash Sale removed.");
        fetchMonitorSales();
      }
    } catch (e) {
      Get.snackbar("Error", "Check connection");
    }
  }

  Future<void> toggleStatus(int id) async {
    try {
      final res = await ApiClient.post('/admin/flash-sales/$id/toggle', {});
      if (res.statusCode == 200) {
        Get.snackbar("Updated", "Flash Sale status toggled.");
        fetchMonitorSales();
      }
    } catch (e) {
      Get.snackbar("Error", "Check connection");
    }
  }
}
