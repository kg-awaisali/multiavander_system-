import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';
import '../../../core/theme.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Platform Settings", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AdminDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader("General"),
          _buildSettingsTile("Platform Name", "Zbardast", Icons.text_fields),
          _buildSettingsTile("Currency", "PKR (Rs.)", Icons.money),
          
          const SizedBox(height: 20),
          _buildSectionHeader("Financials"),
          _buildSettingsTile("Commission Fee", "10%", Icons.percent),
          _buildSettingsTile("Minimum Payout", "Rs. 1,000", Icons.account_balance_wallet),
          
          const SizedBox(height: 20),
          _buildSectionHeader("System"),
          SwitchListTile(title: const Text("Maintenance Mode"), subtitle: const Text("Disable app for all users"), value: false, onChanged: (v){}),
          SwitchListTile(title: const Text("Allow New Seller Requests"), value: true, onChanged: (v){}),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
    );
  }

  Widget _buildSettingsTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: SizedBox(width: 100, child: TextField(textAlign: TextAlign.right, controller: TextEditingController(text: value), decoration: const InputDecoration(border: InputBorder.none))),
    );
  }
}
