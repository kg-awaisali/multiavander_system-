import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_seller_controller.dart';
import '../widgets/admin_drawer.dart';
import '../../../core/theme.dart';

class AdminSellersScreen extends StatelessWidget {
  const AdminSellersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminSellerController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text("Seller Management", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor, Color(0xFF2575FC)],
            ),
          ),
        ),
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          // 1. Controls (Search & Filter)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: controller.updateSearch,
                    decoration: InputDecoration(
                      hintText: "Search Shop or Owner...",
                      prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primaryColor),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.selectedFilter.value,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
                      style: const TextStyle(color: Color(0xFF2D3436), fontWeight: FontWeight.w500, fontSize: 13),
                      items: ['All', 'Pending', 'Approved', 'Blocked'].map((String val) {
                        return DropdownMenuItem<String>(
                          value: val,
                          child: Text(val),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if(val != null) controller.updateFilter(val);
                      },
                    ),
                  ),
                )),
              ],
            ),
          ),
          
          // 2. Data Table / List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
              
              if (controller.filteredSellers.isEmpty) {
                 return Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey.shade300),
                       const SizedBox(height: 16),
                       Text("No Sellers Found", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                     ],
                   ),
                 );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.filteredSellers.length,
                itemBuilder: (context, index) {
                  final seller = controller.filteredSellers[index];
                  final statusColor = _getStatusColor(seller['status']);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.store_rounded, color: statusColor, size: 24),
                      ),
                      title: Text(seller['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text("Owner: ${seller['owner']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              seller['status'],
                              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (seller['status'] == 'Pending')
                            _ActionButton(
                              icon: Icons.check_circle_rounded,
                              color: Colors.green,
                              onTap: () => controller.approveSeller(seller['id']),
                            ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                        ],
                      ),
                      onTap: () => _showSellerDetail(context, controller, seller),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showSellerDetail(BuildContext context, AdminSellerController controller, Map seller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Seller Details", style: TextStyle(color: Color(0xFF2D3436), fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                    ),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildDetailSection("Shop Information", [
                    _buildDetailRow("Shop Name", seller['name']),
                    _buildDetailRow("Description", seller['description']),
                    _buildDetailRow("Status", seller['status'], color: _getStatusColor(seller['status'])),
                    _buildDetailRow("Wallet Balance", "Rs. ${seller['wallet_balance']}"),
                  ]),
                  _buildDetailSection("Contact Information", [
                    _buildDetailRow("Owner Name", seller['owner']),
                    _buildDetailRow("Phone", seller['phone']),
                    _buildDetailRow("Email", seller['email']),
                  ]),
                  _buildDetailSection("Business Details", [
                    _buildDetailRow("Address", "${seller['address']}, ${seller['city']}, ${seller['state']} ${seller['postal_code']}"),
                    _buildDetailRow("Reg No", seller['business_registration_no']),
                  ]),
                  _buildDetailSection("Bank Account", [
                    _buildDetailRow("Bank", seller['bank_name']),
                    _buildDetailRow("Title", seller['account_title']),
                    _buildDetailRow("Account #", seller['account_number']),
                    _buildDetailRow("IBAN", seller['iban']),
                  ]),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      if (seller['status'] == 'Pending') ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () { Get.back(); controller.approveSeller(seller['id']); },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text("Approve", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () { Get.back(); _showRejectionDialog(context, controller, seller['id']); },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade100,
                              foregroundColor: Colors.orange.shade900,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                      if (seller['status'] != 'Blocked' && seller['status'] != 'Pending')
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () { Get.back(); controller.blockSeller(seller['id']); },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red.shade700,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text("Block Seller", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectionDialog(BuildContext context, AdminSellerController controller, int sellerId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Reject Seller", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Please provide a reason for rejection. The seller will be notified.", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: "Enter rejection reason...",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600))),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Get.back();
                controller.rejectSeller(sellerId, reasonController.text);
              } else {
                Get.snackbar("Error", "Please provide a reason");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Confirm Rejection"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(children: children),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color ?? const Color(0xFF2D3436), fontSize: 14))),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved': return const Color(0xFF26DE81);
      case 'Pending': return AppTheme.primaryColor;
      case 'Blocked': return const Color(0xFFEB3B5A);
      default: return Colors.grey;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
