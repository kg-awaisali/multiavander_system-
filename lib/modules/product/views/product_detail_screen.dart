import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../widgets/global_header.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/views/login_screen.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../../data/models/product_model.dart';
import '../../../core/theme.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../chat/views/chat_room_screen.dart';
import '../../cart/views/cart_screen.dart';
import '../../../core/constants.dart';
import '../../../core/api_client.dart';
import '../../../data/models/review_model.dart';
import '../../../widgets/animated_rating_bar.dart';
import '../../../widgets/glass_review_card.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;
  ProductDetailScreen({super.key, required this.product});

  final RxInt quantity = 1.obs;
  final RxInt selectedImageIndex = 0.obs;
  final RxMap<String, String> selectedAttributes = <String, String>{}.obs;
  final Rxn<ProductVariationModel> selectedVariation = Rxn();
  
  // Review State
  final RxList<ReviewModel> reviews = <ReviewModel>[].obs;
  final RxBool isLoadingReviews = false.obs;
  final RxBool isEligible = false.obs;
  final RxDouble avgRating = 0.0.obs;
  final RxInt reviewCount = 0.obs;
  final RxMap<int, int> ratingDistribution = <int, int>{}.obs;
  final RxBool hasInitialized = false.obs;

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    final authController = Get.find<AuthController>();

    // Responsive split layout
    bool isWeb = context.width > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          const GlobalHeader(isSliver: true, showBackButton: true),
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (isWeb)
                  _buildWebLayout(context, cartController, authController)
                else
                  _buildMobileLayout(context, cartController, authController),
                
                // Reviews Section
                _buildReviewsSection(context, authController),
                
                const SizedBox(height: 20), 
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWeb ? null : _buildBottomButtons(cartController, authController),
    );
  }

  Widget _buildMobileLayout(BuildContext context, CartController cartController, AuthController authController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageSection(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPriceSection(),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _buildQuantitySection(),
              const SizedBox(height: 16),
              if (product.hasVariations) _buildVariationsSection(),
              const Divider(height: 32),
              _buildSpecsAndDescription(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebLayout(BuildContext context, CartController cartController, AuthController authController) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.width * 0.1, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: _buildImageSection(height: 450)),
          const SizedBox(width: 40),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildPriceSection(),
                const SizedBox(height: 30),
                _buildQuantitySection(),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(child: _buildBlueButton(cartController, authController, isFull: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildOrangeButton(cartController, authController, isFull: true)),
                  ],
                ),
                const Divider(height: 60),
                _buildSpecsAndDescription(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection({double height = 350}) {
    return Column(
      children: [
        Obx(() => Container(
          height: height,
          width: double.infinity,
          color: Colors.grey[50],
          child: Image.network(
            product.images.isNotEmpty ? AppConstants.getImageUrl(product.images[selectedImageIndex.value]) : 'https://via.placeholder.com/400',
            fit: BoxFit.contain,
          ),
        )),
        const SizedBox(height: 10),
        if (product.images.length > 1)
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: product.images.length,
              itemBuilder: (context, index) {
                return Obx(() => GestureDetector(
                  onTap: () => selectedImageIndex.value = index,
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedImageIndex.value == index ? AppTheme.primaryColor : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Image.network(AppConstants.getImageUrl(product.images[index]), fit: BoxFit.cover),
                    ),
                  ),
                ));
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Obx(() {
      final price = selectedVariation.value?.price ?? product.discountedPrice ?? product.price;
      final stock = selectedVariation.value?.stock ?? product.stock;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Rs. $price',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFf57224), // Daraz Orange
                ),
              ),
              const SizedBox(width: 10),
              if (selectedVariation.value == null && product.discountedPrice != null)
                 Text(
                    'Rs. ${product.price}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                 ),
            ],
          ),
          Text(
            stock > 0 ? 'In Stock: $stock' : 'Out of Stock',
            style: TextStyle(
              color: stock > 0 ? Colors.green : Colors.red, 
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      );
    });
  }

  Widget _buildQuantitySection() {
    return Row(
      children: [
        const Text("Quantity", style: TextStyle(color: Colors.grey)),
        const SizedBox(width: 20),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () { if (quantity.value > 1) quantity.value--; },
                icon: const Icon(Icons.remove, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              Obx(() => Text("${quantity.value}", style: const TextStyle(fontSize: 16))),
              IconButton(
                onPressed: () { quantity.value++; },
                icon: const Icon(Icons.add, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVariationsSection() {
    // 1. Get unique attribute keys
    final Set<String> keys = {};
    for (var v in product.variations) {
      keys.addAll(v.attributes.keys);
    }
    
    // Auto-select first options if not selected
    if (selectedAttributes.isEmpty && product.variations.isNotEmpty) {
       final firstVar = product.variations.first;
       selectedAttributes.addAll(firstVar.attributes.map((k, v) => MapEntry(k, v.toString())));
       selectedVariation.value = firstVar;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: keys.map((key) {
        // Get unique values for this key
        final Set<String> values = product.variations
            .map((v) => v.attributes[key]?.toString())
            .where((v) => v != null)
            .cast<String>()
            .toSet();
        
        final bool isColorAttr = key.toLowerCase().contains('color') || key.toLowerCase().contains('rang') || key.toLowerCase().contains('colour');
            
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$key:', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: values.map((val) {
                  return Obx(() {
                    final isSelected = selectedAttributes[key] == val;
                    
                    // Find a variation with this attribute value to get its image
                    final matchingVariation = product.variations.firstWhereOrNull(
                      (v) => v.attributes[key]?.toString() == val
                    );
                    final String? variationImgUrl = matchingVariation?.variationImage;
                    
                    // CHECK AVAILABILITY
                    bool isAvailable = product.variations.any((v) {
                      if (v.attributes[key]?.toString() != val) {
                        return false;
                      }
                      if (v.stock <= 0) {
                        return false;
                      }
                      for (var entry in selectedAttributes.entries) {
                        if (entry.key == key) {
                          continue;
                        }
                        if (v.attributes[entry.key]?.toString() != entry.value) {
                          return false;
                        }
                      }
                      return true;
                    });
                    
                    // COLOR ATTRIBUTE: Show Swatches or Variation Images
                    if (isColorAttr) {
                      Color? swatchColor;
                      try {
                        String colorName = val.toLowerCase().trim();
                        if (colorName.startsWith('#')) {
                          swatchColor = Color(int.parse(colorName.replaceFirst('#', '0xFF')));
                        } else {
                          // Standard color mapping
                          final Map<String, Color> colorMap = {
                            'red': Colors.red,
                            'blue': Colors.blue,
                            'green': Colors.green,
                            'black': Colors.black,
                            'white': Colors.white,
                            'yellow': Colors.yellow,
                            'grey': Colors.grey,
                            'gray': Colors.grey,
                            'orange': Colors.orange,
                            'pink': Colors.pink,
                            'purple': Colors.purple,
                            'brown': Colors.brown,
                            'cyan': Colors.cyan,
                            'teal': Colors.teal,
                            'indigo': Colors.indigo,
                          };
                          swatchColor = colorMap[colorName];
                        }
                      } catch (e) {}

                      return GestureDetector(
                        onTap: isAvailable ? () {
                          selectedAttributes[key] = val;
                          _updateSelectedVariation();
                          if (variationImgUrl != null && variationImgUrl.isNotEmpty) {
                            final fullUrl = AppConstants.getImageUrl(variationImgUrl);
                            final idx = product.images.indexWhere((img) => img == fullUrl);
                            if (idx != -1) selectedImageIndex.value = idx;
                          }
                        } : null,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: swatchColor ?? Colors.grey.shade200,
                            backgroundImage: (swatchColor == null && variationImgUrl != null && variationImgUrl.isNotEmpty) 
                                ? NetworkImage(AppConstants.getImageUrl(variationImgUrl)) 
                                : null,
                            child: isSelected 
                              ? Icon(
                                  Icons.check_circle, 
                                  color: (swatchColor == Colors.white || swatchColor == Colors.yellow) ? Colors.black : Colors.white, 
                                  size: 20
                                )
                              : null,
                          ),
                        ),
                      );
                    }
                    
                    // NON-COLOR ATTRIBUTE: Square Professional Buttons
                    return GestureDetector(
                      onTap: isAvailable ? () {
                        selectedAttributes[key] = val;
                        _updateSelectedVariation();
                      } : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white,
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          val,
                          style: TextStyle(
                            color: isAvailable ? (isSelected ? AppTheme.primaryColor : Colors.black87) : Colors.grey[400],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            decoration: !isAvailable ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    );
                  });
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _updateSelectedVariation() {
     // Find variation matching ALL selected attributes
     // Using firstWhereOrNull to avoid crash if no match found
     final match = product.variations.firstWhereOrNull((v) {
       for (var entry in selectedAttributes.entries) {
          if (v.attributes[entry.key]?.toString() != entry.value) return false;
       }
       return true;
     });
     selectedVariation.value = match;
  }

  Widget _buildSpecsAndDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Specifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...product.specifications.map((spec) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text('${spec.key}: ', style: const TextStyle(color: Colors.grey)),
              Text(spec.value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        )),
        const SizedBox(height: 24),
        const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          product.description ?? 'No description available.',
          style: const TextStyle(height: 1.5, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(CartController cartController, AuthController authController) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          _buildActionIcon(Icons.store_mall_directory_outlined, "Store", onTap: () {
            // Visit store logic
          }),
          const SizedBox(width: 20),
          _buildActionIcon(Icons.chat_bubble_outline, "Chat", onTap: () {
            _handleChat(authController);
          }),
          const SizedBox(width: 20),
          Expanded(child: _buildBlueButton(cartController, authController)),
          const SizedBox(width: 10),
          Expanded(child: _buildOrangeButton(cartController, authController)),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  void _handleChat(AuthController authController) async {
    if (authController.user.value == null) {
      Get.to(() => LoginScreen());
      Get.snackbar("Auth Required", "Please login to chat with seller");
      return;
    }

    // Initialize Chat Controller if not found
    final chatController = Get.put(ChatController());
    
    // Show loading
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    
    final chatId = await chatController.startChat({
      'id': product.sellerId,
      'name': product.shopName,
      'image': '', // Shop image not available in product model currently
      'email': '',
    });
    
    Get.back(); // Close loading

    if (chatId != null) {
      Get.to(() => ChatRoomScreen(
        roomId: chatId,
        otherUserName: product.shopName,
        product: product,
      ));
    } else {
      Get.snackbar("Error", "Could not start chat");
    }
  }

  // --- Review Methods ---

  void _fetchReviews() async {
    isLoadingReviews.value = true;
    final authController = Get.find<AuthController>();
    final currentUserId = authController.user.value?.id;

    try {
      final res = await ApiClient.get('/products/${product.id}/reviews');
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final dynamic nestedData = decoded['data'];
        final List? data = nestedData is Map ? nestedData['data'] : null;
        
        if (data != null) {
          final List<ReviewModel> parsedReviews = [];
          for (var e in data) {
            try {
              final model = ReviewModel.fromJson(e);
              // Check if current user helpful'd this
              final helpfulIds = e['helpful_ids'];
              List likes = [];
              if (helpfulIds is List) likes = helpfulIds;
              else if (helpfulIds is String) {
                try { likes = jsonDecode(helpfulIds) as List; } catch(_) {}
              }

              parsedReviews.add(ReviewModel(
                id: model.id,
                productId: model.productId,
                userId: model.userId,
                userName: model.userName,
                userImage: model.userImage,
                rating: model.rating,
                comment: model.comment,
                images: model.images,
                createdAt: model.createdAt,
                isVerified: model.isVerified,
                helpfulCount: model.helpfulCount,
                isHelpful: currentUserId != null && likes.any((id) => id.toString() == currentUserId.toString()),
                sellerReply: model.sellerReply,
                sellerReplyAt: model.sellerReplyAt,
              ));
            } catch (e) {
              debugPrint("Error parsing single review: $e");
            }
          }
          reviews.value = parsedReviews;
          
          reviewCount.value = nestedData['total'] ?? 0;
          
          final Map? dist = decoded['distribution'];
          if (dist != null) {
            ratingDistribution.value = dist.map((key, value) => MapEntry(int.parse(key.toString()), int.parse(value.toString())));
          }
          if (decoded['average_rating'] != null) {
            avgRating.value = double.tryParse(decoded['average_rating'].toString()) ?? 0.0;
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching reviews: $e");
    } finally {
      isLoadingReviews.value = false;
    }
  }

  void _toggleHelpful(int reviewId) async {
    final authController = Get.find<AuthController>();
    if (authController.user.value == null) {
      Get.snackbar("Auth Required", "Please login to vote", backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    try {
      final res = await ApiClient.post('/reviews/$reviewId/helpful', {});
      if (res.statusCode == 200) {
        // Refresh silently
        _fetchReviews();
      }
    } catch (e) {
      debugPrint("Error toggling helpful: $e");
    }
  }

  void _submitSellerReply(int reviewId, String reply) async {
    if (reply.trim().length < 2) return;

    try {
      final res = await ApiClient.post('/reviews/$reviewId/reply', {'reply': reply});
      if (res.statusCode == 200) {
        Get.snackbar("Success", "Reply sent to customer", backgroundColor: Colors.green, colorText: Colors.white);
        _fetchReviews();
      } else {
        Get.snackbar("Error", "Could not send reply", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint("Error submitting reply: $e");
    }
  }

  void _deleteReview(int reviewId) async {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Delete Review", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to delete this review?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Get.back();
              final res = await ApiClient.delete('/reviews/$reviewId');
              if (res.statusCode == 200) {
                Get.snackbar("Success", "Review deleted");
                _fetchReviews();
              } else {
                Get.snackbar("Error", "Could not delete review");
              }
            }, 
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      )
    );
  }

  void _checkEligibility() async {
    final authController = Get.find<AuthController>();
    if (authController.user.value == null) return;

    try {
      final res = await ApiClient.get('/products/${product.id}/review-eligibility');
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        isEligible.value = decoded['data']?['eligible'] ?? false;
      }
    } catch (e) {
      debugPrint("Error checking eligibility: $e");
    }
  }

  Widget _buildReviewsSection(BuildContext context, AuthController authController) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hasInitialized.value) {
        // Initialize from product data first
        avgRating.value = product.averageRating;
        reviewCount.value = product.reviewsCount;
        
        _fetchReviews();
        _checkEligibility();
        hasInitialized.value = true;
      }
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1E), // Dark futuristic background
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Customer Reviews',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Obx(() => isEligible.value 
                ? TextButton.icon(
                    onPressed: () => _showWriteReviewDialog(context),
                    icon: const Icon(Icons.edit, color: Colors.cyanAccent),
                    label: const Text('Write Review', style: TextStyle(color: Colors.cyanAccent)),
                  )
                : const SizedBox.shrink()
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRatingSummary(),
          const SizedBox(height: 24),
          Obx(() {
            if (isLoadingReviews.value) {
              return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
            }
            if (reviews.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No reviews yet. Be the first to review!',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                final isMine = authController.user.value?.id == review.userId;
                final isSellerOfProduct = authController.user.value?.id == product.sellerId;
                
                return GlassReviewCard(
                  review: review,
                  isMine: isMine,
                  isSeller: isSellerOfProduct,
                  onEdit: () => _showWriteReviewDialog(context, existingReview: review),
                  onDelete: () => _deleteReview(review.id),
                  onHelpful: () => _toggleHelpful(review.id),
                  onReply: (reply) => _submitSellerReply(review.id, reply),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Obx(() => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                avgRating.value.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              AnimatedRatingBar(rating: avgRating.value, size: 16),
              const SizedBox(height: 4),
              Text(
                '${reviewCount.value} Reviews',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = ratingDistribution[star] ?? 0;
                final total = reviewCount.value > 0 ? reviewCount.value : 1;
                final progress = count / total;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        star.toString(),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            valueColor: const AlwaysStoppedAnimation(Colors.cyanAccent),
                            minHeight: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ));
  }

  void _showWriteReviewDialog(BuildContext context, {ReviewModel? existingReview}) {
    final rating = (existingReview?.rating ?? 0.0).obs;
    final commentController = TextEditingController(text: existingReview?.comment);
    final RxList<XFile> selectedImages = <XFile>[].obs;
    final RxList<String> existingImages = (existingReview?.images ?? []).obs;
    final isSubmitting = false.obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rate Product', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Center(
                child: Obx(() => AnimatedRatingBar(
                  rating: rating.value,
                  size: 40,
                  isInteractive: true,
                  onRatingChanged: (val) => rating.value = val,
                )),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: commentController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  filled: true,
                   fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Photos', style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 10),
              // Existing Images
              Obx(() => existingImages.isNotEmpty ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: existingImages.map((imageUrl) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: -5,
                          top: -5,
                          child: GestureDetector(
                            onTap: () => existingImages.remove(imageUrl),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
              ) : const SizedBox.shrink()),
              Obx(() => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ...selectedImages.map((file) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb 
                          ? Image.network(file.path, width: 70, height: 70, fit: BoxFit.cover)
                          : Image.file(File(file.path), width: 70, height: 70, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: -5,
                        top: -5,
                        child: GestureDetector(
                          onTap: () => selectedImages.remove(file),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )),
                  if (selectedImages.length < 5)
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final List<XFile> images = await picker.pickMultiImage();
                        if (images.isNotEmpty) {
                          selectedImages.addAll(images.take(5 - selectedImages.length));
                        }
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.add_photo_alternate, color: Colors.cyanAccent),
                      ),
                    ),
                ],
              )),
              const SizedBox(height: 30),
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSubmitting.value ? null : () async {
                    if (commentController.text.length < 5) {
                      Get.snackbar("Error", "Please write a comment with at least 5 characters",
                        backgroundColor: Colors.red, colorText: Colors.white);
                      return;
                    }
                    
                    isSubmitting.value = true;
                    try {
                      List<http.MultipartFile> multipartFiles = [];
                      for (var file in selectedImages) {
                        if (kIsWeb) {
                          final bytes = await file.readAsBytes();
                          multipartFiles.add(http.MultipartFile.fromBytes('images[]', bytes, filename: file.name));
                        } else {
                          multipartFiles.add(await http.MultipartFile.fromPath('images[]', file.path));
                        }
                      }

                      final url = existingReview != null 
                        ? '/reviews/${existingReview.id}'
                        : '/products/${product.id}/reviews';
                      
                      final response = await ApiClient.postMultipart(
                        url,
                        {
                          'rating': rating.value.toString(),
                          'comment': commentController.text,
                          if (existingReview != null) '_method': 'PUT',
                          if (existingReview != null) ...{
                            for (int i = 0; i < existingImages.length; i++)
                              'existing_images[$i]': existingImages[i].split('/').last,
                          }
                        },
                        multipartFiles,
                      );

                      final responseBody = await http.Response.fromStream(response);
                      if (responseBody.statusCode == 200 || responseBody.statusCode == 201) {
                        Get.back(); // Close bottom sheet
                        Get.snackbar("Success", "Review submitted successfully!",
                          backgroundColor: Colors.green, colorText: Colors.white);
                        _fetchReviews();
                        isEligible.value = false;
                      } else {
                        final error = jsonDecode(responseBody.body)['message'] ?? "Error submitting review";
                        Get.snackbar("Error", error, backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    } catch (e) {
                      Get.snackbar("Error", "Something went wrong: $e", backgroundColor: Colors.red, colorText: Colors.white);
                    } finally {
                      isSubmitting.value = false;
                    }
                  },
                  child: isSubmitting.value 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black)) 
                    : const Text('Submit Review', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildBlueButton(CartController cartController, AuthController authController, {bool isFull = false}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2ca6e0), // Cyan/Blue
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: isFull ? 20 : 12),
      ),
      onPressed: () {
        if (authController.user.value == null) {
          Get.to(() => LoginScreen());
          Get.snackbar("Auth Required", "Please login to buy items");
        } else {
          final variation = selectedVariation.value;
          cartController.addToCart(product, variation: variation, qty: quantity.value);
          // Potential: Jump to checkout or cart
          Get.to(() => const CartScreen());
        }
      },
      child: const Text('Buy Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildOrangeButton(CartController cartController, AuthController authController, {bool isFull = false}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFf57224), // Orange
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: isFull ? 20 : 12),
      ),
      onPressed: () {
        if (authController.user.value == null) {
          Get.to(() => LoginScreen());
          Get.snackbar("Auth Required", "Please login to add items to cart");
        } else {
          final variation = selectedVariation.value;
          cartController.addToCart(product, variation: variation, qty: quantity.value);
        }
      },
      child: const Text('Add to Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
