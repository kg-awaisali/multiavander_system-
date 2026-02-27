import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_product_controller.dart';
import '../widgets/admin_drawer.dart';
import '../../../core/theme.dart';

class AdminProductsScreen extends StatelessWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminProductController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text("Product Management", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
      body: Obx(() {
        if(controller.isLoading.value) return Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        
        if (controller.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text("No Products Found", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.products.length,
          itemBuilder: (context, index) {
            final product = controller.products[index];
            final isActive = product['status'] == 'Active';
            
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
                contentPadding: const EdgeInsets.all(12),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(product['image']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text("${product['shop']} • ${product['price']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product['status'],
                        style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                onTap: () => _showProductDetail(context, controller, product),
              ),
            );
          },
        );
      }),
    );
  }

  void _showProductDetail(BuildContext context, AdminProductController controller, Map product) {
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
                  const Text("Product Details", style: TextStyle(color: Color(0xFF2D3436), fontSize: 18, fontWeight: FontWeight.bold)),
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
                  // Image Gallery
                  if ((product['all_images'] as List).isNotEmpty)
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: (product['all_images'] as List).length,
                        itemBuilder: (context, index) => Container(
                          width: 180,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                            image: DecorationImage(
                              image: NetworkImage(product['all_images'][index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  _buildDetailSection("Basic Information", [
                    _buildDetailRow("Product Name", product['name']),
                    _buildDetailRow("Brand", product['brand']),
                    _buildDetailRow("Category", product['category']),
                    _buildDetailRow("Price", product['price']),
                    if (product['discounted_price'] != null)
                      _buildDetailRow("Discounted", product['discounted_price']),
                    _buildDetailRow("Status", product['status'], color: product['status'] == 'Active' ? Colors.green : Colors.red),
                  ]),
                  
                  _buildDetailSection("Inventory & Variations", [
                    _buildDetailRow("Stock Level", product['stock'].toString()),
                    _buildDetailRow("Has Variations", product['has_variations'] ? "Yes" : "No"),
                  ]),
                  
                  _buildDetailSection("Shop Details", [
                    _buildDetailRow("Sold By", product['shop']),
                  ]),
                  
                  _buildDetailSection("Description", [
                    _buildDetailRow("Short Desc", product['short_description']),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                    Text(product['description'], style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5)),
                  ]),
                  
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () { Get.back(); controller.toggleStatus(product['id']); },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: product['status'] == 'Active' ? Colors.red.shade50 : Colors.green.shade50,
                            foregroundColor: product['status'] == 'Active' ? Colors.red : Colors.green,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            product['status'] == 'Active' ? "Ban Product" : "Activate Product",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
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

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
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
}
