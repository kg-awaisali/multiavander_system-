import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/api_client.dart';
import '../../../../core/constants.dart';

// Category Model
class CategoryModel {
  int id;
  String name;
  String icon;
  String slug;
  int? parentId;
  double commissionRate;
  List<CategoryModel> children;
  List<AttributeModel> linkedAttributes;

  CategoryModel({
    required this.id, 
    required this.name, 
    required this.icon, 
    required this.slug, 
    this.parentId,
    this.commissionRate = 0.0,
    this.children = const [],
    this.linkedAttributes = const [],
  });
  
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      parentId: json['parent_id'] != null ? int.tryParse(json['parent_id'].toString()) : null,
      commissionRate: double.tryParse(json['commission_rate']?.toString() ?? '0') ?? 0.0,
      children: (json['children'] as List?)?.map((c) => CategoryModel.fromJson(c)).toList() ?? [],
      linkedAttributes: (json['linked_attributes'] as List?)?.map((a) => AttributeModel.fromJson(a)).toList() ?? [],
    );
  }
}

// Attribute Model
class AttributeModel {
  int id;
  String name;
  String type;
  List<String>? options;
  bool isRequired;
  bool isApproved;

  AttributeModel({
    required this.id,
    required this.name,
    required this.type,
    this.options,
    this.isRequired = false,
    this.isApproved = true,
  });

  factory AttributeModel.fromJson(Map<String, dynamic> json) {
    return AttributeModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      options: json['options'] != null ? List<String>.from(json['options']) : null,
      isRequired: json['is_required'] == true || json['is_required'] == 1 || json['is_required']?.toString() == '1',
      isApproved: json['is_approved'] == true || json['is_approved'] == 1 || json['is_approved']?.toString() == '1',
    );
  }
}

class AdminCategoryController extends GetxController {
  var isLoading = false.obs;
  var categories = <CategoryModel>[].obs;
  var allAttributes = <AttributeModel>[].obs; // For multi-select
  var pendingCategories = <CategoryModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    fetchAttributes();
  }

  void fetchCategories() async {
    isLoading.value = true;
    try {
      final response = await ApiClient.get('/categories');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        categories.assignAll(data.map((e) => CategoryModel.fromJson(e)).toList());
      } else {
        Get.snackbar('Error', 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Fetch Categories Exception: $e");
      Get.snackbar('Error', 'Failed to fetch categories: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void fetchAttributes() async {
    try {
      final response = await ApiClient.get('/admin/attributes');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List attrList = data['data'] ?? data;
        allAttributes.assignAll(attrList.map((e) => AttributeModel.fromJson(e)).toList());
      }
    } catch (e) {
      // Silently fail, attributes are optional
    }
  }

  void fetchPendingCategories() async {
    try {
      final response = await ApiClient.get('/categories?pending=true');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        pendingCategories.assignAll(data.map((e) => CategoryModel.fromJson(e)).toList());
      }
    } catch (e) {
      // Silently fail
    }
  }

  void addCategory({
    required String name, 
    required String iconUrl, 
    int? parentId, 
    double? commissionRate,
    List<int>? attributeIds,
  }) async {
     try {
       final response = await ApiClient.post('/admin/categories', {
         'name': name,
         'icon': iconUrl,
         'parent_id': parentId,
         'commission_rate': commissionRate ?? 0.0,
         'attributes': attributeIds ?? [],
       });
       if(response.statusCode == 200 || response.statusCode == 201) {
          Get.back();
          Get.snackbar('Success', 'Category Added');
          fetchCategories();
       } else {
          final errorData = jsonDecode(response.body);
          Get.snackbar('Error', errorData['message'] ?? 'Failed to add category (Status: ${response.statusCode})');
       }
     } catch (e) {
        Get.snackbar('Error', 'Network Error: $e');
     }
  }

  void deleteCategory(int id) async {
     try {
       final response = await ApiClient.delete('/admin/categories/$id');
       if(response.statusCode == 200) {
          Get.snackbar('Deleted', 'Category removed successfully');
          fetchCategories();
       }
     } catch(e) {
        Get.snackbar('Error', 'Failed to delete');
     }
  }
  
  void updateCategory({
    required int id, 
    required String name, 
    required String iconUrl,
    int? parentId,
    double? commissionRate,
    List<int>? attributeIds,
  }) async {
     try {
       final response = await ApiClient.put('/admin/categories/$id', {
          'name': name,
          'icon': iconUrl,
          'parent_id': parentId,
          'commission_rate': commissionRate,
          'attributes': attributeIds,
       });
       
       if(response.statusCode == 200) {
          Get.back();
          Get.snackbar('Updated', 'Category updated successfully');
          fetchCategories();
       }
     } catch(e) {
        Get.snackbar('Error', 'Failed to update');
     }
  }

  void approveCategory(int id) async {
    try {
      await ApiClient.post('/admin/categories/$id/approve', {});
      Get.snackbar('Approved', 'Category approved');
      fetchPendingCategories();
      fetchCategories();
    } catch (e) {
      Get.snackbar('Error', 'Failed to approve');
    }
  }

  void rejectCategory(int id) async {
    try {
      await ApiClient.post('/admin/categories/$id/reject', {});
      Get.snackbar('Rejected', 'Category rejected');
      fetchPendingCategories();
    } catch (e) {
      Get.snackbar('Error', 'Failed to reject');
    }
  }

  // Method to upload image - WEB COMPATIBLE
  Future<String?> uploadImage(XFile xFile) async {
      try {
        final request = http.MultipartRequest('POST', Uri.parse('${AppConstants.baseUrl}/upload'));
        
        // Use fromBytes for Web compatibility instead of fromPath
        final bytes = await xFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'image', // The key expected by backend
          bytes,
          filename: xFile.name,
        ));
        
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
           final data = jsonDecode(response.body);
           return data['url'] ?? data['relative_path'];
        } else {
           Get.snackbar('Upload Failed', 'Server error: ${response.statusCode}');
           return null;
        }
      } catch (e) {
         Get.snackbar('Error', 'Image upload failed: $e');
         return null;
      }
  }
}
