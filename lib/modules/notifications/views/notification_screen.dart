import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../../../core/theme.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationController());

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: controller.markAllAsRead,
            child: const Text('Mark all as read', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.fetchNotifications,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: controller.notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              return _buildNotificationTile(notification, controller);
            },
          ),
        );
      }),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification, NotificationController controller) {
    IconData icon;
    Color iconColor;

    // Determine icon based on type (simple logic for now)
    if (notification.type.contains('Order')) {
      icon = Icons.shopping_bag_outlined;
      iconColor = Colors.blue;
    } else if (notification.type.contains('Chat') || notification.type.contains('Message')) {
      icon = Icons.chat_bubble_outline;
      iconColor = Colors.green;
    } else if (notification.type.contains('Voucher')) {
      icon = Icons.local_offer_outlined;
      iconColor = Colors.orange;
    } else if (notification.type.contains('flash_sale')) {
      icon = Icons.flash_on;
      iconColor = Colors.amber;
    } else if (notification.type.contains('nomination')) {
      icon = Icons.how_to_reg;
      iconColor = Colors.purple;
    } else if (notification.type.contains('suggestion')) {
      icon = Icons.lightbulb_outline;
      iconColor = Colors.blue;
    } else {
      icon = Icons.notifications_none;
      iconColor = Colors.grey;
    }

    return ListTile(
      onTap: () => controller.markAsRead(notification.id),
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        notification.data['title'] ?? 'New Notification',
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            notification.data['message'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat.yMMMd().add_jm().format(notification.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
      trailing: !notification.isRead 
        ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle))
        : null,
      isThreeLine: true,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Nothing to see here', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        ],
      ),
    );
  }
}
