import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import '../../../../core/api_client.dart';
import '../widgets/admin_drawer.dart';
import '../controllers/admin_category_controller.dart';
import '../../../core/theme.dart';

class AdminAttributesScreen extends StatefulWidget {
  const AdminAttributesScreen({super.key});

  @override
  State<AdminAttributesScreen> createState() => _AdminAttributesScreenState();
}

class _AdminAttributesScreenState extends State<AdminAttributesScreen> {
  var isLoading = false;
  var attributes = <AttributeModel>[];

  @override
  void initState() {
    super.initState();
    fetchAttributes();
  }

  Future<void> fetchAttributes() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiClient.get('/admin/attributes');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List attrList = data['data'] ?? data;
        setState(() {
          attributes = attrList.map((e) => AttributeModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch attributes');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void deleteAttribute(int id) async {
    try {
      final response = await ApiClient.delete('/admin/attributes/$id');
      if (response.statusCode == 200) {
        Get.snackbar('Deleted', 'Attribute removed');
        fetchAttributes();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text("Global Attributes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
        label: const Text("New Attribute", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAttributeDialog(null),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : attributes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("No Attributes Found", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text("Tap + to define shared product traits", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: attributes.length,
                  itemBuilder: (context, index) {
                    final attr = attributes[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _getTypeColor(attr.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _getTypeIcon(attr.type),
                        ),
                        title: Text(attr.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3436))),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(attr.type.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getTypeColor(attr.type))),
                                if (attr.isRequired) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                                    child: const Text("REQUIRED", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.red)),
                                  ),
                                ],
                              ],
                            ),
                            if (attr.options != null && attr.options!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text("Options: ${attr.options!.join(', ')}", 
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ActionButton(
                              icon: Icons.edit_rounded,
                              color: Colors.blue,
                              onTap: () => _showAttributeDialog(attr),
                            ),
                            const SizedBox(width: 8),
                            _ActionButton(
                              icon: Icons.delete_outline_rounded,
                              color: Colors.red,
                              onTap: () => _showDeleteConfirmation(attr.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Attribute?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("This attribute will be removed from all assigned categories. Sellers will no longer see it."),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () { Get.back(); deleteAttribute(id); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Icon _getTypeIcon(String type) {
    final color = _getTypeColor(type);
    switch (type) {
      case 'number': return Icon(Icons.numbers_rounded, color: color, size: 20);
      case 'dropdown': return Icon(Icons.list_rounded, color: color, size: 20);
      case 'boolean': return Icon(Icons.toggle_on_rounded, color: color, size: 20);
      default: return Icon(Icons.text_fields_rounded, color: color, size: 20);
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'number': return Colors.teal;
      case 'dropdown': return Colors.blue;
      case 'boolean': return Colors.orange;
      default: return Colors.purple;
    }
  }

  void _showAttributeDialog(AttributeModel? attribute) {
    final nameController = TextEditingController(text: attribute?.name ?? '');
    final optionsController = TextEditingController(
      text: attribute?.options?.join(', ') ?? '',
    );
    final RxString selectedType = (attribute?.type ?? 'text').obs;
    final RxBool isRequired = (attribute?.isRequired ?? false).obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    attribute == null ? "Add Attribute" : "Edit Attribute",
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
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Attribute Name *"),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "e.g. Memory, Material, Style",
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildLabel("Input Type"),
                    Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          value: selectedType.value,
                          decoration: const InputDecoration(border: InputBorder.none),
                          items: const [
                            DropdownMenuItem(value: 'text', child: Text('Simple Text')),
                            DropdownMenuItem(value: 'number', child: Text('Numerical Value')),
                            DropdownMenuItem(value: 'dropdown', child: Text('Predefined Options (List)')),
                            DropdownMenuItem(value: 'boolean', child: Text('Toggle (Yes/No)')),
                          ],
                          onChanged: (val) => selectedType.value = val!,
                        ),
                      ),
                    )),
                    const SizedBox(height: 20),
                    
                    Obx(() => selectedType.value == 'dropdown'
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Options (comma-separated)"),
                              TextField(
                                controller: optionsController,
                                decoration: InputDecoration(
                                  hintText: "Red, Green, Blue",
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  helperText: "Users will select from these options",
                                  helperStyle: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          )
                        : const SizedBox.shrink()),
                    
                    Container(
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Obx(() => CheckboxListTile(
                        title: const Text("Mandatory Selection", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text("Sellers must provide this value", style: TextStyle(fontSize: 12)),
                        value: isRequired.value,
                        onChanged: (val) => isRequired.value = val!,
                        activeColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      )),
                    ),
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
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      Get.snackbar('Error', 'Attribute name is required');
                      return;
                    }
                    
                    List<String>? options;
                    if (selectedType.value == 'dropdown') {
                      final optText = optionsController.text.trim();
                      if (optText.isEmpty) {
                        Get.snackbar('Error', 'Options are required for dropdown type');
                        return;
                      }
                      options = optText.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                    }
                    
                    final body = {
                      'name': name,
                      'type': selectedType.value,
                      'options': options,
                      'is_required': isRequired.value,
                    };
                    
                    try {
                      final response = attribute == null
                          ? await ApiClient.post('/admin/attributes', body)
                          : await ApiClient.put('/admin/attributes/${attribute.id}', body);
                      
                      if (response.statusCode == 200 || response.statusCode == 201) {
                        Get.back();
                        Get.snackbar('Success', attribute == null ? 'Attribute created' : 'Attribute updated');
                        fetchAttributes();
                        
                        if (Get.isRegistered<AdminCategoryController>()) {
                          Get.find<AdminCategoryController>().fetchAttributes();
                        }
                      } else {
                        final error = jsonDecode(response.body);
                        Get.snackbar('Error', error['message'] ?? 'Failed to save');
                      }
                    } catch (e) {
                      Get.snackbar('Error', 'Network error');
                    }
                  },
                  child: Text(
                    attribute == null ? "Define Attribute" : "Save Changes",
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
