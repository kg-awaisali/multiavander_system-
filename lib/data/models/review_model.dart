import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/constants.dart';

class ReviewModel {
  final int id;
  final int productId;
  final int userId;
  final String userName;
  final String? userImage;
  final double rating;
  final String comment;
  final List<String> images;
  final DateTime createdAt;
  final bool isVerified;
  final int helpfulCount;
  final bool isHelpful; // Flag for current user
  final String? sellerReply;
  final DateTime? sellerReplyAt;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.rating,
    required this.comment,
    required this.images,
    required this.createdAt,
    this.isVerified = false,
    this.helpfulCount = 0,
    this.isHelpful = false,
    this.sellerReply,
    this.sellerReplyAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    List<String> processedImages = [];
    if (json['images'] != null) {
      var imagesData = json['images'];
      if (imagesData is String) {
        try {
          imagesData = jsonDecode(imagesData);
        } catch (e) {
          imagesData = [];
        }
      }
      
      if (imagesData is List) {
        processedImages = imagesData.map((img) {
          final imgStr = img.toString();
          final fullUrl = AppConstants.getImageUrl(imgStr);
          debugPrint('📸 Review Image: $imgStr → $fullUrl');
          return fullUrl;
        }).toList();
      }
    }

    // Defensive parsing for helpful_ids
    var helpfulIdsRaw = json['helpful_ids'];
    List helpfulIds = [];
    if (helpfulIdsRaw is List) {
      helpfulIds = helpfulIdsRaw;
    } else if (helpfulIdsRaw is String) {
      try {
        helpfulIds = jsonDecode(helpfulIdsRaw) as List;
      } catch (_) {}
    }
    
    return ReviewModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      userName: json['user']?['name'] ?? 'User',
      userImage: json['user']?['image'],
      rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
      comment: json['comment']?.toString() ?? '',
      images: processedImages,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true || json['is_verified']?.toString() == 'true',
      helpfulCount: helpfulIds.length,
      isHelpful: false, // Set in UI controller
      sellerReply: json['seller_reply']?.toString(),
      sellerReplyAt: json['seller_reply_at'] != null ? DateTime.tryParse(json['seller_reply_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'user_id': userId,
    'rating': rating,
    'comment': comment,
    'images': images,
    'created_at': createdAt.toIso8601String(),
    'is_verified': isVerified,
    'seller_reply': sellerReply,
    'seller_reply_at': sellerReplyAt?.toIso8601String(),
  };
}
