import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../product/views/product_detail_screen.dart';
import '../../../data/models/product_model.dart';
import '../../../widgets/animated_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  var orders = [].obs;
  var isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    isLoading.value = true;
    try {
      final response = await ApiClient.get('/my-orders');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        orders.value = data['data'];
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch orders: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Obx(() {
        if (isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No orders yet', style: TextStyle(color: Colors.grey, fontSize: 18)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Start Shopping', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: fetchOrders,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(order);
            },
          ),
        );
      }),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    String status = order['status'] ?? 'pending';
    Color statusColor = _getStatusColor(status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order #${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Placed on: ${DateFormat('dd MMM yyyy').format(DateTime.parse(order['created_at']))}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  order['status_description'] ?? '',
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 13, fontStyle: FontStyle.italic),
                ),
                const Divider(height: 24),
                
                // Items Summary
                ... (order['items'] as List).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          image: item['product']['images'] != null && (item['product']['images'] as List).isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(AppConstants.getImageUrl(item['product']['images'][0])),
                                fit: BoxFit.cover,
                              )
                            : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['product']['name'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                            Text('Qty: ${item['quantity']} | Rs. ${item['price']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            if (status.toLowerCase() == 'delivered')
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: TextButton(
                                  onPressed: () => _showReviewDialog(item['product']),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  child: const Text('Rate & Review', style: TextStyle(color: Colors.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(color: Colors.grey)),
                    Text('Rs. ${order['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor)),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Tracking Status (Daraz Style)
                _buildTrackingStepper(status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStepper(String currentStatus) {
    final stages = ['pending', 'processing', 'shipped', 'delivered'];
    int currentIndex = stages.indexOf(currentStatus.toLowerCase());
    if (currentIndex == -1) currentIndex = 0;

    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Order Tracking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(stages.length, (index) {
            bool isLast = index == stages.length - 1;
            bool isDone = index <= currentIndex;
            bool isActive = index == currentIndex;

            return Expanded(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: isDone ? AppTheme.primaryColor : Colors.grey[300],
                          shape: BoxShape.circle,
                          border: isActive ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 4) : null,
                        ),
                        child: Icon(
                          index < currentIndex ? Icons.check : _getStageIcon(stages[index]),
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStageLabel(stages[index]),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                          color: isDone ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        color: index < currentIndex ? AppTheme.primaryColor : Colors.grey[300],
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  IconData _getStageIcon(String stage) {
    switch (stage) {
      case 'pending': return Icons.receipt_long;
      case 'processing': return Icons.settings;
      case 'shipped': return Icons.local_shipping;
      case 'delivered': return Icons.home;
      default: return Icons.circle;
    }
  }

  String _getStageLabel(String stage) {
    switch (stage) {
      case 'pending': return 'Placed';
      case 'processing': return 'Processing';
      case 'shipped': return 'Shipped';
      case 'delivered': return 'Delivered';
      default: return stage;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'processing': return Colors.blue;
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _showReviewDialog(Map<String, dynamic> productData) {
    // Map JSON to ProductModel if needed, or just use IDs
    final productId = productData['id'];
    final productName = productData['name'];
    
    final rating = 0.0.obs;
    final commentController = TextEditingController();
    final RxList<XFile> selectedImages = <XFile>[].obs;
    final isSubmitting = false.obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E), // Futuristic Dark
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review: $productName', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
              const Text('Add Photos', style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 10),
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
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2), style: BorderStyle.solid),
                        ),
                        child: const Icon(Icons.add_a_photo, color: Colors.white54),
                      ),
                    ),
                ],
              )),
              const SizedBox(height: 30),
              Obx(() => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSubmitting.value ? null : () async {
                    if (commentController.text.length < 5) {
                      Get.snackbar("Required", "Comment must be at least 5 characters", backgroundColor: Colors.red, colorText: Colors.white);
                      return;
                    }
                    
                    isSubmitting.value = true;
                    try {
                      final url = Uri.parse('${AppConstants.baseUrl}/products/$productId/reviews');
                      var request = http.MultipartRequest('POST', url);
                      
                      request.headers.addAll(await ApiClient.getHeaders());
                      request.fields['rating'] = rating.value.toString();
                      request.fields['comment'] = commentController.text;
                      
                      for (var file in selectedImages) {
                        if (kIsWeb) {
                          final bytes = await file.readAsBytes();
                          request.files.add(http.MultipartFile.fromBytes('images[]', bytes, filename: file.name));
                        } else {
                          request.files.add(await http.MultipartFile.fromPath('images[]', file.path));
                        }
                      }
                      
                      var response = await request.send();
                      if (response.statusCode == 200 || response.statusCode == 201) {
                        Get.back(); // Close bottom sheet
                        Get.snackbar("Success", "Thank you for your review!", backgroundColor: Colors.green, colorText: Colors.white);
                      } else {
                        final stringRes = await response.stream.bytesToString();
                        final error = jsonDecode(stringRes)['message'] ?? 'Error submitting review';
                        Get.snackbar("Error", error, backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    } catch (e) {
                      Get.snackbar("Error", "Could not submit review: $e", backgroundColor: Colors.red, colorText: Colors.white);
                    } finally {
                      isSubmitting.value = false;
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSubmitting.value 
                    ? const CircularProgressIndicator(color: Color(0xFF1A1A2E))
                    : const Text('Submit Review', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 16)),
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
}
