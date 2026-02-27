import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api_client.dart';
import '../../../data/models/product_model.dart';

class SellerProductController extends GetxController {
  var isLoading = false.obs;
  var products = <Map<String, dynamic>>[].obs;
  var categories = <Map<String, dynamic>>[].obs;
  var categoryAttributes = <Map<String, dynamic>>[].obs;
  var selectedCategoryId = Rxn<int>();
  
  // Dynamic form state
  var attributeValues = <int, String>{}.obs; 
  var draftVariations = <Map<String, dynamic>>[].obs;
  var hasVariations = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
    fetchCategories();
  }

  Future<void> fetchProducts({String? search, int? categoryId, String? status}) async {
    isLoading.value = true;
    try {
      String url = '/seller/products?';
      if (search != null) url += 'search=$search&';
      if (categoryId != null) url += 'category_id=$categoryId&';
      if (status != null) url += 'status=$status&';

      final response = await ApiClient.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // SANITIZATION FIX: Pass through ProductModel to ensure all types (int vs string) are corrected
        final List sanitizedList = (data['data'] ?? []).map((e) {
          try {
            return ProductModel.fromJson(e).toJson();
          } catch (e) {
            debugPrint("Error sanitizing product: $e");
            return e; 
          }
        }).toList();

        products.assignAll(List<Map<String, dynamic>>.from(sanitizedList));
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load products: $e');
    } finally {
      isLoading.value = false;
    }
  }



  Future<void> fetchCategories() async {
    try {
      // Use the public categories endpoint which is usually more stable
      final response = await ApiClient.get('/categories');
      debugPrint('Fetching categories from /categories, status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List? list;
        
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          // Handle { "data": [...] } or { "categories": [...] }
          list = decoded['data'] ?? decoded['categories'] ?? decoded['result'];
        }

        if (list != null && list is List) {
          debugPrint('Found ${list.length} categories');
          // Map to Map<String, dynamic> and clear categories first to ensure refresh
          final List<Map<String, dynamic>> mappedList = list.map((e) => Map<String, dynamic>.from(e)).toList();
          categories.assignAll(mappedList);
          categories.refresh();
        } else {
          debugPrint('No category list found in response: $decoded');
          // IF public fails or empty, try the seller endpoint as fallback
          _fetchSellerCategoriesFallback();
        }
      } else {
        debugPrint('Failed to load categories: ${response.body}');
        _fetchSellerCategoriesFallback();
      }
    } catch (e) {
      debugPrint('Categories error: $e');
      _fetchSellerCategoriesFallback();
    }
  }

  Future<void> _fetchSellerCategoriesFallback() async {
    try {
      final response = await ApiClient.get('/seller/categories');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List? list = (decoded is Map) ? decoded['data'] : (decoded is List ? decoded : null);
        if (list != null) {
          final List<Map<String, dynamic>> mappedList = list.map((e) => Map<String, dynamic>.from(e)).toList();
          categories.assignAll(mappedList);
          categories.refresh();
        }
      }
    } catch (e) {
      debugPrint('Fallback categories error: $e');
    }
  }

  Future<void> fetchCategoryAttributes(int categoryId) async {
    selectedCategoryId.value = categoryId;
    attributeValues.clear();
    categoryAttributes.clear();
    try {
      final response = await ApiClient.get('/seller/category-attributes/$categoryId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final attrs = List<Map<String, dynamic>>.from(data['attributes'] ?? []);
        categoryAttributes.assignAll(attrs);
        
        // Initialize values
        for (var attr in attrs) {
          attributeValues[attr['id']] = '';
        }
      }
    } catch (e) {
      print('Attributes error: $e');
    }
  }

  void addDraftVariation(Map<String, dynamic> variation) {
    draftVariations.add(variation);
  }

  void removeDraftVariation(int index) {
    draftVariations.removeAt(index);
  }

  Future<int?> suggestCategory(String name, List<Map<String, dynamic>> attributes) async {
    try {
      final response = await ApiClient.post('/seller/categories/suggest', {
        'name': name,
        'attributes': attributes,
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newCategory = data['data'];
        
        // Refresh categories
        await fetchCategories();
        
        // Return new ID
        return newCategory['id'];
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to suggest category: $e');
    }
    return null;
  }

  Future<bool> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await ApiClient.post('/seller/products', productData);
      if (response.statusCode == 201) {
        Get.snackbar('Success', 'Product created successfully', backgroundColor: Colors.green.shade100);
        fetchProducts();
        return true;
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar('Error', data['message'] ?? 'Failed to create product', backgroundColor: Colors.red.shade100);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Network error: $e', backgroundColor: Colors.red.shade100);
      return false;
    }
  }

  Future<bool> updateProduct(int productId, Map<String, dynamic> productData) async {
    try {
      final response = await ApiClient.put('/seller/products/$productId', productData);
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Product updated successfully', backgroundColor: Colors.green.shade100);
        fetchProducts();
        return true;
      } else {
        Get.snackbar('Error', 'Failed to update product', backgroundColor: Colors.red.shade100);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Network error: $e', backgroundColor: Colors.red.shade100);
      return false;
    }
  }

  Future<bool> deleteProduct(int productId) async {
    try {
      final response = await ApiClient.delete('/seller/products/$productId');
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Product deleted', backgroundColor: Colors.green.shade100);
        fetchProducts();
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete: $e', backgroundColor: Colors.red.shade100);
      return false;
    }
  }

  Future<bool> addVariation(int productId, Map<String, dynamic> variationData) async {
    try {
      final response = await ApiClient.post('/seller/products/$productId/variations', variationData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar('Success', 'Variation added', backgroundColor: Colors.green.shade100);
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar('Error', 'Failed to add variation: $e', backgroundColor: Colors.red.shade100);
      return false;
    }
  }

  Future<bool> updateVariation(int variationId, Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.put('/seller/variations/$variationId', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String?> uploadImage(XFile imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiClient.baseUrl}/upload'),
      );
      
      // Add auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Add image file using bytes for Web compatibility
      final bytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: imageFile.name,
      ));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['relative_path'] ?? data['url']; // Prefer relative path
      }
      return null;
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }

  void clearDraftData() {
    attributeValues.clear();
    draftVariations.clear();
    categoryAttributes.clear();
    selectedCategoryId.value = null;
    hasVariations.value = false;
  }
}
