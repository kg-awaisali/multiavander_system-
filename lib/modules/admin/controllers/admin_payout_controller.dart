import 'package:get/get.dart';

class AdminPayoutController extends GetxController {
  var isLoading = false.obs;
  var payouts = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPayouts();
  }

  void fetchPayouts() async {
    isLoading.value = true;
    try {
      await Future.delayed(const Duration(seconds: 1));
      payouts.assignAll([
        {'id': 1, 'seller': 'Ali Electronic', 'amount': 'Rs. 50,000', 'status': 'Pending', 'bank': 'HBL - 1234...'},
        {'id': 2, 'seller': 'Fashion Hub', 'amount': 'Rs. 12,000', 'status': 'Approved', 'bank': 'Meezan - 5678...'},
        {'id': 3, 'seller': 'Tech World', 'amount': 'Rs. 5,000', 'status': 'Rejected', 'bank': 'Easypaisa - 0300...'},
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  void updatePayoutStatus(int id, String status) {
    int index = payouts.indexWhere((p) => p['id'] == id);
    if(index != -1) {
      var pay = payouts[index];
      pay['status'] = status;
      payouts[index] = pay;
      Get.snackbar('Updated', 'Payout marked as $status');
    }
  }
}
