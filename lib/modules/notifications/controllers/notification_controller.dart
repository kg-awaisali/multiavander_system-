import 'dart:convert';
import 'package:get/get.dart';
import '../../../core/api_client.dart';

class NotificationModel {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.data,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      type: json['type'],
      data: json['data'] ?? {},
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NotificationController extends GetxController {
  var notifications = <NotificationModel>[].obs;
  var unreadCount = 0.obs;
  var isLoading = false.obs;
  bool _isActive = true;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
    // Poll for new notifications every 60 seconds
    _startPolling();
  }

  @override
  void onClose() {
    _isActive = false;
    super.onClose();
  }

  void _startPolling() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_isActive) {
        fetchNotifications();
        _startPolling();
      }
    });
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      final response = await ApiClient.get('/notifications');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data']['data'] ?? [];
        notifications.assignAll(list.map((e) => NotificationModel.fromJson(e)).toList());
        unreadCount.value = data['unread_count'] ?? 0;
      }
    } catch (e) {
      print('Notification fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final response = await ApiClient.post('/notifications/$id/read', {});
      if (response.statusCode == 200) {
        fetchNotifications();
      }
    } catch (e) {
      print('Mark as read error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await ApiClient.post('/notifications/read-all', {});
      if (response.statusCode == 200) {
        fetchNotifications();
      }
    } catch (e) {
      print('Mark all as read error: $e');
    }
  }
}
