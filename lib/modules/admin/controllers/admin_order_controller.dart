import 'dart:convert';
import 'package:get/get.dart';
import '../../../../core/api_client.dart';

class AdminOrderController extends GetxController {
  var isLoading = false.obs;
  var orders = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  void fetchOrders() async {
    isLoading.value = true;
    try {
      final response = await ApiClient.get('/admin/orders');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'];

        orders.assignAll(list.map((o) {
          return {
            'id': '#ORD-${o['id']}',
            'db_id': o['id'], // Store real ID for updates
            'user': o['user']['name'],
            'amount': 'Rs. ${o['total_amount']}',
            'date': o['created_at'].toString().substring(0, 10),
            'status': _capitalize(o['status'] ?? 'pending'),
            'items': 0, // Backend might need to load items count. Assuming 0 for now or update API to send withCount('items')
          };
        }).toList());
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch orders');
    } finally {
      isLoading.value = false;
    }
  }

  String _capitalize(String s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '';

  void updateStatus(String orderIdDisplay, String newStatus) async { // orderIdDisplay like #ORD-123
    // Find internal ID
    int index = orders.indexWhere((o) => o['id'] == orderIdDisplay);
    if(index == -1) return;
    
    int dbId = orders[index]['db_id'];

    try {
      final response = await ApiClient.post('/admin/orders/$dbId/status', {'status': newStatus.toLowerCase()});
      
      if(response.statusCode == 200) {
        var ord = orders[index];
        ord['status'] = newStatus;
        orders[index] = ord;
        Get.snackbar('Success', 'Order status updated to $newStatus');
      } else {
        Get.snackbar('Error', 'Failed to update order');
      }
    } catch (e) {
       Get.snackbar('Error', 'Network Error');
    }
  }
}
