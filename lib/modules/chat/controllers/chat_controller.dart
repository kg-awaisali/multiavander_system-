import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  RxInt totalUnreadCount = 0.obs;
  StreamSubscription? _unreadSubscription;

  @override
  void onInit() {
    super.onInit();
    _listenToUnreadMessages();
  }

  @override
  void onClose() {
    _unreadSubscription?.cancel();
    super.onClose();
  }

  void _listenToUnreadMessages() {
    final currentUser = _authController.user.value;
    if (currentUser == null) return;

    // Listen to all chats where I am a participant
    _unreadSubscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUser.id)
        .snapshots()
        .listen((snapshot) {
            int count = 0;
            for (var doc in snapshot.docs) {
               final data = doc.data();
               final List seenBy = data['seen_by'] ?? [];
               // If my ID is NOT in seen_by, it's unread
               if (!seenBy.contains(currentUser.id)) {
                 count++;
               }
            }
            totalUnreadCount.value = count;
        });
  }

  // 1. Create or Get Chat Room (Optimized for Offline)
  Future<String?> startChat(Map<String, dynamic> otherUser, {
    int? productId, 
    String? productName, 
    String? productImage
  }) async {
    final currentUser = _authController.user.value;
    if (currentUser == null) return null;

    try {
      int myId = currentUser.id;
      // Handle parsing safely
      int otherId = 0;
      try {
        otherId = int.parse(otherUser['id'].toString());
      } catch (e) {
        return null; // Silent fail or handle upstream
      }

      // Deterministic ID generation (No await needed!)
      String baseId = myId < otherId ? "${myId}_$otherId" : "${otherId}_$myId";
      String chatId = productId != null ? "${baseId}_$productId" : "${baseId}_general";

      // Prepare data
      final chatData = {
          'participants': [myId, otherId],
          'users': {
            myId.toString(): {'name': currentUser.name, 'email': currentUser.email, 'image': ''},
            otherId.toString(): {'name': otherUser['name'], 'email': otherUser['email'] ?? '', 'image': otherUser['image'] ?? ''}
          },
          'last_message_time': DateTime.now(), // Local time for immediate offline showing
          'seen_by': [myId], // Initially seen by creator
          if (productId != null) 'product_id': productId,
          if (productName != null) 'product_name': productName,
          if (productImage != null) 'product_image': productImage,
      };
      
      // Background mein room create/update karein (Sync later)
      _firestore.collection('chats').doc(chatId).set(chatData, SetOptions(merge: true))
          .catchError((e) => print("Offline/Bg Error: $e"));

      // Foran ID return karein taake UI open ho jaye
      return chatId; 
    } catch (e) {
      print("Chat Logic Error: $e");
      return null;
    }
  }

  // 2. Send Message (WhatsApp Style: Local Update First)
  Future<void> sendMessage(String chatId, String text) async {
    final currentUser = _authController.user.value;
    if (currentUser == null || text.trim().isEmpty) return;

    // Use local timestamp for immediate UI update while offline
    final timestamp = DateTime.now(); 

    try {
      // Background add (Queued if offline)
      _firestore.collection('chats').doc(chatId).collection('messages').add({
        'sender_id': currentUser.id,
        'text': text,
        'timestamp': timestamp, // Local time use karein
        'is_read': false,
        'type': 'text',
      });

      _firestore.collection('chats').doc(chatId).update({
        'last_message': text,
        'last_message_time': timestamp,
        'last_sender_id': currentUser.id,
        'seen_by': [currentUser.id], // Reset seen_by to ONLY sender (others haven't seen update)
      });
    } catch (e) {
      print("Offline Queue Error: $e");
    }
  }

  // Mark Chat as Read
  void markAsRead(String chatId) {
     final currentUser = _authController.user.value;
     if (currentUser == null) return;
     
     _firestore.collection('chats').doc(chatId).update({
        'seen_by': FieldValue.arrayUnion([currentUser.id])
     }).catchError((e) => print("Mark Read Error: $e"));
  }

  // Stream Messages
  Stream<QuerySnapshot> getMessages(String chatId) {
    // Mark as read when opening stream
    markAsRead(chatId);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Stream my Chat Rooms
  Stream<QuerySnapshot> getMyChats() {
    final currentUser = _authController.user.value;
    if (currentUser == null) return const Stream.empty();

    print("Fetching chats for user ID: ${currentUser.id} (Type: ${currentUser.id.runtimeType})");
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUser.id)
        // .orderBy('last_message_time', descending: true) // Temporarily removed to fix Index issue
        .snapshots();
  }
}
