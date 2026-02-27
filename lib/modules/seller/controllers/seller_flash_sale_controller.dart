import 'dart:convert';
import 'package:get/get.dart';
import '../../../core/api_client.dart';
import '../../../data/models/flash_sale_campaign_model.dart';

class SellerFlashSaleController extends GetxController {
  var isLoading = false.obs;
  var campaigns = <FlashSaleCampaignModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCampaigns();
  }

  Future<void> fetchCampaigns() async {
    isLoading.value = true;
    try {
      final res = await ApiClient.get('/seller/flash-sales/campaigns');
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body)['data'];
        campaigns.value = data.map((e) => FlashSaleCampaignModel.fromJson(e)).toList();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> suggestFlashSale({
    required int productId,
    required int campaignId,
    required double flashPrice,
    required int stockLimit,
  }) async {
    isLoading.value = true;
    try {
      final res = await ApiClient.post('/seller/flash-sales/nominate', {
        'product_id': productId,
        'campaign_id': campaignId,
        'flash_price': flashPrice,
        'stock_limit': stockLimit,
      });

      if (res.statusCode == 200) {
        Get.snackbar("Success", "Suggestion submitted for approval!");
        return true;
      } else {
        final msg = jsonDecode(res.body)['message'] ?? "Error submitting suggestion";
        Get.snackbar("Error", msg);
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
