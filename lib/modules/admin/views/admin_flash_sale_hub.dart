import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'admin_campaign_screen.dart';
import 'admin_approval_screen.dart';
import 'admin_monitoring_screen.dart';
import '../controllers/admin_campaign_controller.dart';
import '../../../core/theme.dart';

class AdminFlashSaleHub extends StatelessWidget {
  const AdminFlashSaleHub({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AdminCampaignController());

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Flash Sale Hub", style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Campaigns", icon: Icon(Icons.calendar_today)),
              Tab(text: "Approvals", icon: Icon(Icons.pending_actions)),
              Tab(text: "Monitoring", icon: Icon(Icons.bar_chart)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminCampaignScreen(),
            AdminApprovalScreen(),
            AdminMonitoringScreen(),
          ],
        ),
      ),
    );
  }
}
