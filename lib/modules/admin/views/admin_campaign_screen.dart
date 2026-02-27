import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_campaign_controller.dart';
import '../../../core/theme.dart';

class AdminCampaignScreen extends StatelessWidget {
  const AdminCampaignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminCampaignController());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Flash Sale Campaigns", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showCreateCampaignDialog(context, controller),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) return Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        if (controller.campaigns.isEmpty) return const Center(child: Text("No campaigns created."));

        return ListView.builder(
          itemCount: controller.campaigns.length,
          itemBuilder: (context, index) {
            final campaign = controller.campaigns[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(campaign.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${DateFormat('MMM dd, HH:mm').format(campaign.startTime)} - ${DateFormat('MMM dd, HH:mm').format(campaign.endTime)}"),
                trailing: Chip(
                  label: Text(campaign.status.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: campaign.isActive ? Colors.green : Colors.grey,
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showCreateCampaignDialog(BuildContext context, AdminCampaignController controller) {
    final nameController = TextEditingController();
    DateTime start = DateTime.now().add(const Duration(hours: 1));
    DateTime end = DateTime.now().add(const Duration(hours: 25));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("New Campaign Slot"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Campaign Name (e.g. Mega Monday)"),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: const Text("Start"),
                subtitle: Text(DateFormat('MMM dd, HH:mm').format(start)),
                onTap: () async {
                  final date = await showDatePicker(context: context, initialDate: start, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (date != null) {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(start));
                    if (time != null) setState(() => start = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                  }
                },
              ),
              ListTile(
                title: const Text("End"),
                subtitle: Text(DateFormat('MMM dd, HH:mm').format(end)),
                onTap: () async {
                  final date = await showDatePicker(context: context, initialDate: end, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (date != null) {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(end));
                    if (time != null) setState(() => end = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600))),
            ElevatedButton(
              onPressed: () {
                controller.createCampaign(nameController.text, start, end);
                Get.back();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              child: const Text("Create Slot"),
            ),
          ],
        ),
      ),
    );
  }
}
