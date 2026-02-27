import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import 'chat_room_screen.dart';
import '../../../core/theme.dart';
import 'package:intl/intl.dart';
import '../../../data/models/product_model.dart';
import '../../../core/constants.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatController());
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: controller.getMyChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final docs = snapshot.data!.docs;
          final myId = authController.user.value?.id.toString();

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              // Identify Other User
              String otherUserId = "";
              Map<String, dynamic> otherUserData = {};
              
              if (data['users'] != null) {
                (data['users'] as Map).forEach((key, value) {
                  if (key != myId) {
                    otherUserId = key;
                    otherUserData = value as Map<String, dynamic>;
                  }
                });
              }

              return ListTile(
                onTap: () => Get.to(() => ChatRoomScreen(
                  roomId: doc.id, 
                  otherUserName: otherUserData['name'] ?? 'User',
                  product: data['product_id'] != null ? ProductModel(
                     id: int.tryParse(data['product_id'].toString()) ?? 0,
                     name: data['product_name'] ?? 'Product',
                     description: '', 
                     categoryId: 0, // Required dummy
                     price: 0.0,
                     stock: 0,
                     discountedPrice: 0.0,
                     images: [data['product_image'] ?? ''],
                     sellerId: 0,
                     shopName: '',
                     shopId: 0, // Required dummy
                     slug: '',  // Required dummy
                     specifications: [], // Required dummy
                     currentPrice: 0.0, // Required dummy
                  ) : null,
                )),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  backgroundImage: otherUserData['image'] != null && otherUserData['image'].toString().isNotEmpty
                      ? NetworkImage(otherUserData['image'])
                      : null,
                  child: otherUserData['image'] == null || otherUserData['image'].toString().isEmpty
                      ? Text(
                          otherUserData['name']?.substring(0, 1).toUpperCase() ?? '?',
                          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                title: Row(
                   children: [
                      Expanded(
                        child: Text(
                          otherUserData['name'] ?? 'Unknown User',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (data['product_name'] != null)
                        Container(
                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                           margin: const EdgeInsets.only(left: 4),
                           decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4)
                           ),
                           child: Text(
                             data['product_name'], 
                             style: const TextStyle(fontSize: 10, color: Colors.blue),
                             maxLines: 1, overflow: TextOverflow.ellipsis
                           ),
                        )
                   ],
                ),
                subtitle: Row(
                  children: [
                    if (data['product_image'] != null && data['product_image'].toString().isNotEmpty)
                       Padding(
                         padding: const EdgeInsets.only(right: 6),
                         child: ClipRRect(
                           borderRadius: BorderRadius.circular(2),
                           child: Image.network(
                             AppConstants.getImageUrl(data['product_image']),
                             width: 20, height: 20, fit: BoxFit.cover,
                             errorBuilder: (c,e,s) => const SizedBox(),
                           ),
                         ),
                       ),
                    Expanded(
                      child: Text(
                        data['last_message'] ?? 'No messages yet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: (data['last_sender_id'].toString() != myId) ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (data['last_message_time'] != null)
                      Text(
                        _formatTime(data['last_message_time']),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    
                    // Unread indicator (Simple dot for now if not me)
                   if ((data['last_sender_id'].toString() != myId))
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 10, height: 10,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle
                        ),
                      )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No conversations yet', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        ],
      ),
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = timestamp.toDate();
      final now = DateTime.now();
      if (date.day == now.day && date.month == now.month && date.year == now.year) {
        return DateFormat.jm().format(date);
      }
      return DateFormat.yMd().format(date);
    } catch (e) {
      return '';
    }
  }
}
