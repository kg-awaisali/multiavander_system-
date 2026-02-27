import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../../../core/theme.dart';
import 'package:intl/intl.dart';
import '../../../modules/auth/controllers/auth_controller.dart';
import '../../../core/constants.dart';
import '../../../data/models/product_model.dart';
import '../../product/views/product_detail_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final String otherUserName;
  final int? initialProductId;
  final ProductModel? product;

  const ChatRoomScreen({
    super.key, 
    required this.roomId, 
    required this.otherUserName,
    this.initialProductId,
    this.product,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatController controller = Get.find<ChatController>();
  final AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeOut
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = authController.user.value?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5), // WhatsApp-like bg color
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName, style: const TextStyle(color: Colors.black, fontSize: 16)),
            Text(
              widget.product != null ? 'Inquiry: ${widget.product!.name}' : 'Online', 
              style: TextStyle(
                color: widget.product != null ? AppTheme.primaryColor : Colors.green, 
                fontSize: 11,
                fontWeight: widget.product != null ? FontWeight.bold : FontWeight.normal
              )
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          if (widget.product != null) 
            _buildProductHeader(widget.product!),
          
          // Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: controller.getMessages(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "Start the conversation!", 
                      style: TextStyle(color: Colors.grey.shade600)
                    )
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  reverse: true, // Chat usually starts from bottom
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isMe = data['sender_id'] == currentUserId;
                    
                    return _buildMessageBubble(data, isMe);
                  },
                );
              }
            ),
          ),
          
          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isMe ? 12 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 12),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg['text'] ?? '',
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                ),
                 const SizedBox(height: 4),
                 if (msg['timestamp'] != null)
                   Text(
                    _formatTime(msg['timestamp']),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat.jm().format(date);
  }

  Widget _buildProductHeader(ProductModel product) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              product.images.isNotEmpty ? AppConstants.getImageUrl(product.images[0]) : '',
              width: 40, height: 40, fit: BoxFit.cover,
              errorBuilder: (c,e,s) => Container(color: Colors.grey[100], width:40, height:40),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Discussing Product:', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text('Rs. ${product.price}', style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Get.to(() => ProductDetailScreen(product: product)),
            child: const Text('View Item', style: TextStyle(fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final isSeller = widget.product != null && 
                     authController.user.value?.id == widget.product!.sellerId;

    final replies = isSeller 
        ? ["Yes, Available", "Price is Fixed", "Thanks for ordering", "Please share details"]
        : ["Is it available?", "What is the final price?", "Can you deliver today?", "I want to order"];

    return Column(
      children: [
        // Quick Replies
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: replies.map((text) => _quickReply(text)).toList(),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.add, color: Colors.grey), onPressed: () {}),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300)
                    ),
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (val) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: AppTheme.primaryColor,
                  onPressed: _send,
                  child: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickReply(String text) {
     return Padding(
       padding: const EdgeInsets.only(right: 8),
       child: ActionChip(
         label: Text(text, style: const TextStyle(fontSize: 11)),
         backgroundColor: Colors.white,
         elevation: 1,
         onPressed: () {
            _msgController.text = text;
         },
       ),
     );
  }

  void _send() {
    final text = _msgController.text;
    if (text.isEmpty) return;
    
    controller.sendMessage(widget.roomId, text);
    _msgController.clear();
  }
}

