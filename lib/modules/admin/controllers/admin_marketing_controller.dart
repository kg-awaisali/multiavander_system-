import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import '../../../../core/api_client.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/constants.dart';

class AdminMarketingController extends GetxController {
  var isLoading = false.obs;
  var banners = <Map<String, dynamic>>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchBanners();
  }

  void fetchBanners() async {
    isLoading.value = true;
    try {
      final response = await ApiClient.get('/banners');
      
      if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         final List list = data['data'];
         banners.assignAll(list.map((b) => <String, dynamic>{
            'id': b['id'].toString(),
            'title': b['title'] ?? 'No Title',
            'image': AppConstants.getImageUrl(b['image_path']),
            'active': (b['status'] == 1).toString(),
            'expiry_date': b['expiry_date'] ?? '',
         }).toList());
      }
    } catch (e) {
      print("Fetch Banners Error: $e");
      Get.snackbar('Error', 'Failed to fetch banners');
    } finally {
      isLoading.value = false;
    }
  }

  void deleteBanner(String id) async {
    try {
      final response = await ApiClient.delete('/admin/banners/$id');
      if(response.statusCode == 200) {
         banners.removeWhere((b) => b['id'] == id);
         Get.snackbar('Deleted', 'Banner removed');
      }
    } catch (e) {
       Get.snackbar('Error', 'Failed to delete');
    }
  }

  // Upload Image Helper
  Future<String?> _uploadImage(XFile file) async {
      try {
        final request = http.MultipartRequest('POST', Uri.parse('${AppConstants.baseUrl}/upload'));
        
        // Add Authorization Headers
        final headers = await ApiClient.getHeaders();
        request.headers.addAll(headers);

        final bytes = await file.readAsBytes();
        
        // Ensure filename has extension
        String filename = file.name;
        if (!filename.contains('.')) {
          filename += '.jpg'; // Fallback
        }

        request.files.add(http.MultipartFile.fromBytes(
          'file', 
          bytes, 
          filename: filename
        ));
        
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
           final data = jsonDecode(response.body);
           return data['url'];
        } else {
           print("Upload Failed: ${response.statusCode} - ${response.body}");
           Get.snackbar('Error', 'Upload Failed: ${response.statusCode}');
        }
      } catch (e) {
         print("Upload Error: $e");
         Get.snackbar('Error', 'Upload Exception: $e');
      }
      return null;
  }
  
  // Add Banner with Title and Expiry Date
  Future<void> addBanner(String title, XFile file, String? expiryDate) async {
      isLoading.value = true;
      String? url = await _uploadImage(file);
      if(url != null) {
          final response = await ApiClient.post('/admin/banners', {
              'title': title,
              'image_path': url,
              'expiry_date': expiryDate,
          });
          
          if(response.statusCode == 200 || response.statusCode == 201) {
             Get.back(); // Close dialog
             Get.snackbar('Success', 'Banner Added');
             fetchBanners();
          } else {
             print("Add Banner Failed: ${response.statusCode} - ${response.body}");
             Get.snackbar('Error', 'Failed: ${response.body}');
          }
      } else {
         Get.snackbar('Error', 'Image Upload Failed');
      }
      isLoading.value = false;
  }

  // Update Banner
  Future<void> updateBanner(String id, String title, XFile? file, String currentUrl, String? expiryDate) async {
      isLoading.value = true;
      String url = currentUrl;
      
      if(file != null) {
         String? newUrl = await _uploadImage(file);
         if(newUrl != null) url = newUrl;
      }
      
      final response = await ApiClient.put('/admin/banners/$id', {
          'title': title,
          'image_path': url,
          'expiry_date': expiryDate,
      });
      
      if(response.statusCode == 200) {
         Get.back();
         Get.snackbar('Success', 'Banner Updated');
         fetchBanners();
      } else {
         Get.snackbar('Error', 'Update Failed');
      }
      isLoading.value = false;
  }

  void toggleBanner(String id) {
    // Backend doesn't support toggle yet (only create/delete). 
    // Implementing visual toggle for now or skipping.
    // Ideally we add update endpoint.
     Get.snackbar('Notice', 'Toggle not supported on backend yet, delete and re-upload.');
  }

  void sendNotification(String title, String body, String audience) {
    // API Call to FCM (Placeholder)
    Get.snackbar('Sent', 'Notification sent to $audience');
  }
}
