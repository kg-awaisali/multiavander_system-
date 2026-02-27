import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/constants.dart';

class ProductModel {
  final int id;
  final int shopId;
  final int sellerId;
  final String shopName;
  final int categoryId;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final double? discountedPrice;
  final int stock;
  final List<String> images;
  final List<SpecificationModel> specifications;
  final bool isAvailable;
  final bool hasVariations;
  final List<ProductVariationModel> variations;
  final double currentPrice; // Price after any discount or flash sale
  final bool isFlashSaleActive;
  final double averageRating;
  final int reviewsCount;

  ProductModel({
    required this.id,
    required this.shopId,
    required this.sellerId,
    required this.shopName,
    required this.categoryId,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.discountedPrice,
    required this.stock,
    required this.images,
    required this.specifications,
    this.isAvailable = true,
    this.hasVariations = false,
    this.variations = const [],
    required this.currentPrice,
    this.isFlashSaleActive = false,
    this.averageRating = 0.0,
    this.reviewsCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'shop_id': shopId,
    'seller_id': sellerId,
    'shop': {'name': shopName, 'user_id': sellerId},
    'category_id': categoryId,
    'name': name,
    'slug': slug,
    'description': description,
    'price': price,
    'discounted_price': discountedPrice,
    'stock': stock,
    'images': images,
    'specifications': specifications.map((e) => e.toJson()).toList(),
  };

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Process images to ensure full URLs
    List<String> processedImages = [];
    var imagesData = json['images'];
    
    if (imagesData != null) {
      if (imagesData is String) {
        try {
          imagesData = jsonDecode(imagesData);
        } catch (e) {
          // If not proper JSON, try to treat as single URL if it looks like one, or empty
          if (imagesData.toString().startsWith('http') || imagesData.toString().startsWith('/')) {
            imagesData = [imagesData];
          } else {
            imagesData = [];
          }
        }
      }

      if (imagesData is List) {
        processedImages = imagesData.map((img) {
          final imgStr = img.toString();
          return AppConstants.getImageUrl(imgStr);
        }).cast<String>().toList();
      }
    }

    final List<ProductVariationModel> variations = [];
    if (json['variations'] != null && json['variations'] is List) {
      for (var v in (json['variations'] as List)) {
        try {
          variations.add(ProductVariationModel.fromJson(v));
        } catch (e) {
          debugPrint("Error parsing variation: $e");
        }
      }
    }

    // Calculate total stock if variations are present
    int totalStock = int.tryParse(json['stock']?.toString() ?? '0') ?? 0;
    if (variations.isNotEmpty) {
      totalStock = variations.fold(0, (sum, v) => sum + v.stock);
    }

    return ProductModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      shopId: int.tryParse(json['shop_id']?.toString() ?? '0') ?? 0,
      sellerId: int.tryParse((json['shop']?['user_id'] ?? json['seller_id'])?.toString() ?? '0') ?? 0,
      shopName: json['shop']?['name'] ?? 'Unknown Store',
      categoryId: int.tryParse(json['category_id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? 'Unnamed Product',
      slug: json['slug'] ?? '',
      description: json['description'],
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      discountedPrice: json['discounted_price'] != null 
          ? double.tryParse(json['discounted_price']?.toString() ?? '') 
          : null,
      stock: totalStock, // Use calculated total stock
      images: processedImages,
      specifications: (json['specifications'] as List?)
          ?.map((s) => SpecificationModel.fromJson(s))
          .toList() ?? [],
      isAvailable: totalStock > 0,
      hasVariations: json['has_variations'] == 1 || json['has_variations'] == true,
      variations: variations,
      currentPrice: double.tryParse(json['current_price']?.toString() ?? '') ?? 
                    (json['discounted_price'] != null 
                      ? double.tryParse(json['discounted_price']?.toString() ?? '') 
                      : double.tryParse(json['price']?.toString() ?? '0')) ?? 0,
      isFlashSaleActive: json['is_flash_sale_active'] == 1 || json['is_flash_sale_active'] == true,
      averageRating: double.tryParse(json['average_rating']?.toString() ?? '0.0') ?? 0.0,
      reviewsCount: int.tryParse(json['reviews_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class SpecificationModel {
  final String key;
  final String value;

  SpecificationModel({required this.key, required this.value});

  factory SpecificationModel.fromJson(Map<String, dynamic> json) {
    return SpecificationModel(
      key: json['key']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
  };
}

class ProductVariationModel {
  final int id;
  final String? sku;
  final double price;
  final int stock;
  final Map<String, dynamic> attributes;
  final String? image;
  final String? variationImage; // NEW: Specific image for this variation

  ProductVariationModel({
    required this.id,
    this.sku,
    required this.price,
    required this.stock,
    required this.attributes,
    this.image,
    this.variationImage,
  });

  factory ProductVariationModel.fromJson(Map<String, dynamic> json) {
    return ProductVariationModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      sku: json['sku'],
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      attributes: json['attributes'] is String 
        ? _parseAttributes(json['attributes']) 
        : (json['attributes'] as Map<String, dynamic>? ?? {}),
      image: json['image'],
      variationImage: json['variation_image'],
    );
  }
  
  static Map<String, dynamic> _parseAttributes(dynamic attributes) {
    if (attributes == null) return {};
    if (attributes is Map<String, dynamic>) return attributes;
    if (attributes is String) {
      try {
        return jsonDecode(attributes) as Map<String, dynamic>;
      } catch (e) {
        // Silently fail for malformed JSON
      }
    }
    return {};
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sku': sku,
    'price': price,
    'stock': stock,
    'attributes': attributes,
    'variation_image': variationImage,
  };
}
