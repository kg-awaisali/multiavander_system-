import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/admin_category_controller.dart';
import '../../../core/theme.dart';
import '../widgets/admin_drawer.dart';

class AdminCategoryScreen extends StatelessWidget {
  const AdminCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminCategoryController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text("Category Hub", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("New Category", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showCategoryDialog(context, controller, null),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        
        if (controller.categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text("No Categories Found", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.categories.length,
          itemBuilder: (context, index) {
            final cat = controller.categories[index];
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
                  width: 50,
                  height: 50,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: cat.icon.isNotEmpty 
                      ? Image.network(cat.icon, fit: BoxFit.contain, errorBuilder: (c,e,s)=>Icon(Icons.category_rounded, color: AppTheme.primaryColor)) 
                      : Icon(Icons.category_rounded, color: AppTheme.primaryColor),
                ),
                title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3436))),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text("Commission: ${cat.commissionRate}%", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    if (cat.linkedAttributes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text("Attrs: ${cat.linkedAttributes.map((a) => a.name).join(', ')}", 
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      icon: Icons.edit_rounded,
                      color: Colors.blue,
                      onTap: () => _showCategoryDialog(context, controller, cat),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      color: Colors.red,
                      onTap: () => _showDeleteConfirmation(context, controller, cat.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AdminCategoryController controller, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Category?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("This action cannot be undone. All products in this category will become uncategorized."),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () { Get.back(); controller.deleteCategory(id); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, AdminCategoryController controller, CategoryModel? category) {
    final TextEditingController nameController = TextEditingController(text: category?.name ?? '');
    final TextEditingController commissionController = TextEditingController(text: category?.commissionRate.toString() ?? '0');
    final RxString imageUrl = (category?.icon ?? '').obs;
    final RxBool isUploading = false.obs;
    final Rxn<int> selectedParentId = Rxn(category?.parentId);
    final RxList<int> selectedAttributeIds = RxList(category?.linkedAttributes.map((a) => a.id).toList() ?? []);
    final RxString searchQuery = ''.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category == null ? "Add Category" : "Edit Category",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
                  ),
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
            
            // Scrollable Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Category Name *"),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "Enter name (e.g. Electronics)",
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildLabel("Parent Category"),
                    Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<int?>(
                          value: selectedParentId.value,
                          decoration: const InputDecoration(border: InputBorder.none),
                          items: [
                            const DropdownMenuItem(value: null, child: Text("None (Root Category)")),
                            ...controller.categories
                                .where((c) => c.id != category?.id)
                                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (val) => selectedParentId.value = val,
                        ),
                      ),
                    )),
                    const SizedBox(height: 20),
                    
                    _buildLabel("Commission Rate (%)"),
                    TextField(
                      controller: commissionController,
                      decoration: InputDecoration(
                        hintText: "0",
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        suffixText: "%",
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    
                    _buildLabel("Category Icon"),
                    const SizedBox(height: 8),
                    Obx(() => Row(
                      children: [
                        if (imageUrl.value.isNotEmpty)
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Image.network(imageUrl.value, height: 64, width: 64, fit: BoxFit.contain),
                              ),
                              Positioned(
                                right: -5, top: -5,
                                child: GestureDetector(
                                  onTap: () => imageUrl.value = '',
                                  child: Container(
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.close, color: Colors.white, size: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              isUploading.value = true;
                              String? uploadedUrl = await controller.uploadImage(image);
                              isUploading.value = false;
                              if (uploadedUrl != null) imageUrl.value = uploadedUrl;
                            }
                          },
                          child: Container(
                            height: 80, width: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50, 
                              borderRadius: BorderRadius.circular(12), 
                              border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                            ),
                            child: isUploading.value 
                              ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center, 
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade400), 
                                    const SizedBox(height: 4),
                                    Text("Add Icon", style: TextStyle(fontSize: 10, color: Colors.grey.shade500))
                                  ],
                                ),
                          ),
                        ),
                      ],
                    )),
                    const SizedBox(height: 30),
                    
                    _buildLabel("Linked Attributes"),
                    Text("Select attributes for product listing in this category", style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                    const SizedBox(height: 12),
                    
                    TextField(
                      onChanged: (val) => searchQuery.value = val,
                      decoration: InputDecoration(
                        hintText: "Search attributes...",
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Obx(() {
                      if (controller.allAttributes.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Icon(Icons.list_alt_rounded, color: Colors.grey.shade200, size: 48),
                              const SizedBox(height: 8),
                              const Text("No attributes available.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        );
                      }
                      
                      final filtered = controller.allAttributes
                          .where((a) => a.name.toLowerCase().contains(searchQuery.value.toLowerCase()))
                          .toList();
                      
                      return Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: filtered.map((attr) {
                          final isSelected = selectedAttributeIds.contains(attr.id);
                          return FilterChip(
                            label: Text(attr.name, style: TextStyle(fontSize: 12, color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                selectedAttributeIds.add(attr.id);
                              } else {
                                selectedAttributeIds.remove(attr.id);
                              }
                            },
                            backgroundColor: Colors.grey.shade100,
                            selectedColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            checkmarkColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.transparent)),
                          );
                        }).toList(),
                      );
                    }),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            
            // Bottom Action
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      Get.snackbar('Error', 'Category name is required');
                      return;
                    }
                    
                    final commission = double.tryParse(commissionController.text) ?? 0;
                    if (commission < 0 || commission > 100) {
                      Get.snackbar('Error', 'Commission must be between 0-100');
                      return;
                    }
                    
                    if (category != null) {
                      controller.updateCategory(
                        id: category.id,
                        name: name,
                        iconUrl: imageUrl.value,
                        parentId: selectedParentId.value,
                        commissionRate: commission,
                        attributeIds: selectedAttributeIds.toList(),
                      );
                    } else {
                      controller.addCategory(
                        name: name,
                        iconUrl: imageUrl.value,
                        parentId: selectedParentId.value,
                        commissionRate: commission,
                        attributeIds: selectedAttributeIds.toList(),
                      );
                    }
                  },
                  child: Text(
                    category != null ? "Save Changes" : "Create Category", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3436))),
    );
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
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
