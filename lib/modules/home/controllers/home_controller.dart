import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/api_client.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/flash_sale_model.dart';
import '../../../data/models/marketplace_models.dart';
import '../../product/views/product_detail_screen.dart';

class HomeController extends GetxController {
  var isLoading = true.obs;
  var banners = <BannerModel>[].obs;
  var categories = <CategoryModel>[].obs;
  var allProducts = <ProductModel>[].obs;
  var products = <ProductModel>[].obs;
  var suggestions = <ProductModel>[].obs;
  var flashSales = <FlashSaleModel>[].obs;
  var searchHistory = <String>[].obs;
  
  final searchController = TextEditingController();
  var searchQuery = "".obs;
  var showSuggestions = false.obs;
  var dbName = "".obs;
  var totalCount = 0.obs;

  // Filter variables
  var minPrice = 0.0.obs;
  var maxPrice = 100000.0.obs; // Default max, wil be updated dynamically
  var currentMinPrice = 0.0.obs;
  var currentMaxPrice = 100000.0.obs;
  var selectedCategory = Rxn<CategoryModel>();

  final _storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    _loadSearchHistory();
    _loadCachedData(); // Load cached data first
    fetchHomeData();
  }

  void _loadCachedData() {
    try {
      final cachedBanners = _storage.read<List>('cached_banners');
      if (cachedBanners != null) {
        banners.value = cachedBanners.map((e) => BannerModel.fromJson(e)).toList();
      }

      final cachedCategories = _storage.read<List>('cached_categories');
      if (cachedCategories != null) {
        categories.value = cachedCategories.map((e) => CategoryModel.fromJson(e)).toList();
      }

      final cachedProducts = _storage.read<List>('cached_products');
      if (cachedProducts != null) {
        final List<ProductModel> fetchedProducts = cachedProducts.map((e) => ProductModel.fromJson(e)).toList();
        allProducts.value = fetchedProducts;
        products.value = fetchedProducts;
        updatePriceRange();
      }

      final cachedFlashSales = _storage.read<List>('cached_flash_sales');
      if (cachedFlashSales != null) {
        flashSales.value = cachedFlashSales.map((e) => FlashSaleModel.fromJson(e)).toList();
      }
      
      // If we have cached data, we can start with isLoading = false 
      // to show current data while we fetch updates in background
      if (banners.isNotEmpty || products.isNotEmpty) {
        isLoading.value = false;
      }
    } catch (e) {
      print("Error loading cached data: $e");
    }
  }

  void fetchHomeData() async {
    // Only show loading if we don't have ANY data (first time launch)
    if (banners.isEmpty && products.isEmpty) {
      isLoading.value = true;
    }
    
    try {
      // Run all fetches in parallel
      await Future.wait([
        fetchBanners(),
        fetchCategories(),
        fetchProducts(),
        fetchFlashSales(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFlashSales() async {
    try {
      final res = await ApiClient.get('/flash-sales/active');
      debugPrint("Flash Sales Response: ${res.statusCode}");
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List? data;
        if (decoded is Map) data = decoded['data'] ?? decoded['result'] ?? decoded['items'];
        else if (decoded is List) data = decoded;
        
        if (data != null) {
          final List<FlashSaleModel> fetched = [];
          for (var item in data) {
            try {
              fetched.add(FlashSaleModel.fromJson(item));
            } catch (e) {
              debugPrint("Error parsing flash sale item: $e");
            }
          }
          flashSales.value = fetched;
          _storage.write('cached_flash_sales', data);
        }
      }
    } catch (e) {
      debugPrint("Error fetching flash sales: $e");
    }
  }

  Future<void> fetchBanners() async {
    try {
      final res = await ApiClient.get('/banners');
      debugPrint("Banners Response: ${res.statusCode}");
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List? data;
        if (decoded is Map) data = decoded['data'] ?? decoded['result'] ?? decoded['items'];
        else if (decoded is List) data = decoded;

        if (data != null) {
          final List<BannerModel> fetched = [];
          for (var item in data) {
            try {
              fetched.add(BannerModel.fromJson(item));
            } catch (e) {
              debugPrint("Error parsing banner item: $e");
            }
          }
          banners.value = fetched;
          _storage.write('cached_banners', data);
        }
      }
    } catch (e) {
      debugPrint("Error fetching banners: $e");
    }
  }

  Future<void> fetchCategories() async {
    try {
      final res = await ApiClient.get('/categories');
      debugPrint("Categories Response: ${res.statusCode}");
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List? data;
        if (decoded is Map) data = decoded['data'] ?? decoded['categories'] ?? decoded['result'] ?? decoded['items'];
        else if (decoded is List) data = decoded;

        if (data != null) {
          final List<CategoryModel> fetched = [];
          for (var item in data) {
            try {
              fetched.add(CategoryModel.fromJson(item));
            } catch (e) {
              debugPrint("Error parsing category item: $e");
            }
          }
          categories.value = fetched;
          _storage.write('cached_categories', data);
        }
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
  }

  Future<void> fetchProducts() async {
    try {
      final res = await ApiClient.get('/products');
      debugPrint("Products Response: ${res.statusCode}");
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List? data;
        // Handle Laravel Pagination or direct lists
          if (decoded is Map) {
            dbName.value = decoded['db']?.toString() ?? "Unknown";
            totalCount.value = int.tryParse(decoded['total_count']?.toString() ?? '0') ?? 0;
            data = decoded['data'] ?? decoded['products'] ?? decoded['result'] ?? decoded['items'];
          } else if (decoded is List) {
          data = decoded;
        }

        if (data != null) {
          final List<ProductModel> fetchedProducts = [];
          for (var item in data) {
            try {
              fetchedProducts.add(ProductModel.fromJson(item));
            } catch (e) {
              debugPrint("Error parsing product item: $item. Error: $e");
            }
          }
          debugPrint("Parsed ${fetchedProducts.length} products successfully");
          allProducts.value = fetchedProducts;
          products.value = fetchedProducts;
          updatePriceRange(); 
          _storage.write('cached_products', data);
        }
      } else {
        debugPrint("Products fetch failed with status: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching products: $e");
      debugPrint("Error fetching products: $e");
    }
  }

  void updatePriceRange() {
    if (allProducts.isEmpty) return;
    
    double max = 0.0;
    for (var p in allProducts) {
      double pPrice = double.tryParse(p.price.toString()) ?? 0.0;
      if (pPrice > max) max = pPrice;
    }
    
    // Set dynamic max price (rounded up)
    double newMax = (max / 1000).ceil() * 1000.0;
    if (newMax < 1000) newMax = 50000;
    
    maxPrice.value = newMax;
    
    // Reset current selection logic: 
    // If currentMax is default (big number) OR currentMax > newMax, clamp it.
    if (currentMaxPrice.value == 100000.0 || currentMaxPrice.value > newMax) {
      currentMaxPrice.value = newMax;
    }
  }

  void applyFilters() {
    var tempProducts = List<ProductModel>.from(allProducts);

    // 1. Filter by Search Query
    if (searchQuery.value.trim().isNotEmpty) {
      final lowercaseQuery = searchQuery.value.toLowerCase().trim();
      tempProducts = tempProducts.where((p) => 
        p.name.toLowerCase().contains(lowercaseQuery) || 
        (p.description?.toLowerCase().contains(lowercaseQuery) ?? false)
      ).toList();
    }

    // 2. Filter by Category
    if (selectedCategory.value != null) {
      tempProducts = tempProducts.where((p) => p.categoryId == selectedCategory.value!.id).toList();
    }

    // 3. Filter by Price Range
    tempProducts = tempProducts.where((p) {
      double pPrice = double.tryParse(p.price.toString()) ?? 0.0;
      return pPrice >= currentMinPrice.value && pPrice <= currentMaxPrice.value;
    }).toList();

    products.value = tempProducts;
  }
  
  void updatePriceFilter(double min, double max) {
    currentMinPrice.value = min;
    currentMaxPrice.value = max;
    applyFilters();
  }

  void search(String query) {
    searchQuery.value = query;
    if (query.trim().isEmpty) {
      showSuggestions.value = false;
      applyFilters(); 
    } else {
      final lowercaseQuery = query.toLowerCase().trim();
      suggestions.value = allProducts.where((p) => 
        p.name.toLowerCase().contains(lowercaseQuery)
      ).take(5).toList();
      
      showSuggestions.value = true;
      
      if (Get.currentRoute != '/search-results') {
        Get.toNamed('/search-results');
      }
      applyFilters();
    }
  }

  void filterByCategory(CategoryModel category) {
    if (selectedCategory.value?.id == category.id) {
       // Toggle logic if desired, for now simpler is better
       // selectedCategory.value = null; 
    } else {
      selectedCategory.value = category;
    }
    
    searchController.text = ""; 
    searchQuery.value = ""; 
    
    suggestions.clear();
    showSuggestions.value = false;
    
    if (Get.currentRoute != '/search-results') {
      Get.toNamed('/search-results');
    }
    applyFilters();
  }

  void clearSearch() {
    searchController.clear();
    search("");
    showSuggestions.value = false;
  }
  
  void resetSearchState() {
    searchController.clear();
    searchQuery.value = "";
    showSuggestions.value = false;
    // Don't reset products here to avoid flicker before pop, or do reset? 
    // Usually fine to reset.
    products.value = allProducts;
  }
  
  void selectSuggestion(ProductModel product) {
    searchController.text = product.name;
    search(product.name);
    addToHistory(product.name);
    showSuggestions.value = false;
    // Tapping a product suggestion goes straight to detail
    Get.to(() => ProductDetailScreen(product: product)); 
  }

  void clearAllHistory() {
    searchHistory.clear();
    _saveSearchHistory();
  }

  void _loadSearchHistory() {
    List? storedHistory = _storage.read<List>('search_history');
    if (storedHistory != null) {
      searchHistory.value = storedHistory.cast<String>();
    }
  }

  void _saveSearchHistory() {
    _storage.write('search_history', searchHistory.toList());
  }

  void addToHistory(String query) {
    if (query.trim().isEmpty) return;
    searchHistory.remove(query); // Remove duplicate
    searchHistory.insert(0, query); // Add to top
    if (searchHistory.length > 10) searchHistory.removeLast(); // Limit size
    _saveSearchHistory();
  }

  void removeFromHistory(String query) {
    searchHistory.remove(query);
    _saveSearchHistory();
  }

  @override
  void onClose() {
    // We don't dispose the searchController here because it's used globally 
    // in the Header across multiple screens.
    super.onClose();
  }
}
