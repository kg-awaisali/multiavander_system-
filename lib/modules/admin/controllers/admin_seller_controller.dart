import 'dart:convert';
import 'package:get/get.dart';
import '../../../../core/api_client.dart';

class AdminSellerController extends GetxController {
  var isLoading = false.obs;
  var sellers = <Map<String, dynamic>>[].obs;
  var filteredSellers = <Map<String, dynamic>>[].obs;
  var searchController = ''.obs;
  var selectedFilter = 'All'.obs; // All, Pending, Approved, Blocked

  @override
  void onInit() {
    super.onInit();
    fetchSellers();
  }

  void fetchSellers() async {
    isLoading.value = true;
    try {
       final response = await ApiClient.get('/admin/sellers'); // Add ?status= if needed
       print("AdminSellerController: Status ${response.statusCode}, Body: ${response.body}"); // Debug
       
       if(response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          
          sellers.value = data.map((item) {
             return {
                'id': item['id'],
                'name': (item['name'] ?? 'Unknown').toString(),
                'description': (item['description'] ?? 'No description').toString(),
                'owner': item['user'] != null ? (item['user']['name'] ?? 'Unknown').toString() : 'Unknown',
                'phone': item['user'] != null ? (item['user']['phone'] ?? 'N/A').toString() : 'N/A',
                'email': item['user'] != null ? (item['user']['email'] ?? 'N/A').toString() : 'N/A',
                'status': _capitalize((item['status'] ?? 'pending').toString()),
                'address': (item['address'] ?? '').toString(),
                'city': (item['city'] ?? '').toString(),
                'state': (item['state'] ?? '').toString(),
                'postal_code': (item['postal_code'] ?? '').toString(),
                'business_registration_no': (item['business_registration_no'] ?? 'N/A').toString(),
                'bank_name': (item['bank_name'] ?? 'N/A').toString(),
                'account_title': (item['account_title'] ?? 'N/A').toString(),
                'account_number': (item['account_number'] ?? 'N/A').toString(),
                'iban': (item['iban'] ?? 'N/A').toString(),
                'wallet_balance': (item['wallet_balance'] ?? '0').toString(),
             };
          }).toList();
          
          filterSellers();
       } else {
          Get.snackbar('Error', 'Failed: ${response.statusCode} ${response.body}');
       }
    } catch (e) {
      print(e);
      Get.snackbar('Error', 'Exception: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  String _capitalize(String s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '';

  void filterSellers() {
    var list = sellers.toList();
    
    // 1. Filter by Status
    if (selectedFilter.value != 'All') {
       // Allow case insensitive match or mapping
       // UI uses: Approved, Pending, Blocked (Capitalized)
       // Data uses: same
      list = list.where((s) => s['status'].toString().toLowerCase() == selectedFilter.value.toLowerCase()).toList();
    }

    // 2. Filter by Search
    if (searchController.value.isNotEmpty) {
      list = list.where((s) => 
        s['name'].toString().toLowerCase().contains(searchController.value.toLowerCase()) || 
        s['owner'].toString().toLowerCase().contains(searchController.value.toLowerCase())
      ).toList();
    }

    filteredSellers.assignAll(list);
  }

  void updateSearch(String val) {
    searchController.value = val;
    filterSellers();
  }

  void updateFilter(String val) {
    selectedFilter.value = val;
    filterSellers();
  }

  void approveSeller(int id) async {
    _updateStatus(id, 'approved');
  }

  void blockSeller(int id) async {
    _updateStatus(id, 'blocked');
  }

  void rejectSeller(int id, String reason) async {
    _updateStatus(id, 'rejected', reason: reason);
  }
  
  void _updateStatus(int id, String status, {String? reason}) async {
     try {
       final response = await ApiClient.post('/admin/sellers/$id/status', {
         'status': status,
         if (reason != null) 'rejection_reason': reason,
       });
       if(response.statusCode == 200) {
          Get.snackbar('Success', 'Seller status updated to $status');
          fetchSellers(); // Refresh list
       } else {
          final data = jsonDecode(response.body);
          Get.snackbar('Error', data['message'] ?? 'Failed to update status');
       }
     } catch (e) {
        Get.snackbar('Error', 'Network Error');
     }
  }
}
