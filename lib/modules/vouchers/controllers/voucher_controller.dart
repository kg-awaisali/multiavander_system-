import 'dart:convert';
import 'package:get/get.dart';
import '../../../core/api_client.dart';

class VoucherModel {
  final int id;
  final String code;
  final String type;
  final double value;
  final double minPurchase;
  final double? maxDiscount;
  final int? usageLimit;
  final int usedCount;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  VoucherModel({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.minPurchase = 0,
    this.maxDiscount,
    this.usageLimit,
    this.usedCount = 0,
    this.startDate,
    this.endDate,
    this.isActive = true,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id'],
      code: json['code'],
      type: json['type'],
      value: double.parse(json['value'].toString()),
      minPurchase: double.parse((json['min_purchase'] ?? 0).toString()),
      maxDiscount: json['max_discount'] != null ? double.parse(json['max_discount'].toString()) : null,
      usageLimit: json['usage_limit'],
      usedCount: json['used_count'] ?? 0,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}

class VoucherController extends GetxController {
  var vouchers = <VoucherModel>[].obs;
  var isLoading = false.obs;
  
  // Stats
  var totalVouchers = 0.obs;
  var activeVouchers = 0.obs;
  var totalUsed = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchVouchers();
    fetchStats();
  }

  Future<void> fetchVouchers() async {
    try {
      isLoading.value = true;
      final response = await ApiClient.get('/seller/vouchers');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'] ?? [];
        vouchers.assignAll(list.map((e) => VoucherModel.fromJson(e)).toList());
      }
    } catch (e) {
      print('Voucher fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStats() async {
    try {
      final response = await ApiClient.get('/seller/voucher-stats');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        totalVouchers.value = data['total'] ?? 0;
        activeVouchers.value = data['active'] ?? 0;
        totalUsed.value = data['total_used'] ?? 0;
      }
    } catch (e) {
      print('Voucher stats error: $e');
    }
  }

  Future<void> createVoucher(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final response = await ApiClient.post('/seller/vouchers', data);
      if (response.statusCode == 201) {
        Get.back();
        Get.snackbar('Success', 'Voucher created successfully');
        fetchVouchers();
        fetchStats();
      } else {
        final errorData = jsonDecode(response.body);
        Get.snackbar('Error', errorData['message'] ?? 'Failed to create voucher');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleStatus(int id) async {
    try {
      final response = await ApiClient.post('/seller/vouchers/$id/toggle', {});
      if (response.statusCode == 200) {
        fetchVouchers();
        fetchStats();
      }
    } catch (e) {
      print('Toggle error: $e');
    }
  }

  Future<void> deleteVoucher(int id) async {
    try {
      final response = await ApiClient.delete('/seller/vouchers/$id');
      if (response.statusCode == 200) {
        fetchVouchers();
        fetchStats();
        Get.snackbar('Success', 'Voucher deleted');
      }
    } catch (e) {
      print('Delete error: $e');
    }
  }
}
