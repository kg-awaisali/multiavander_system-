import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/admin_marketing_controller.dart';
import '../widgets/admin_drawer.dart';
import '../../../core/theme.dart';

class AdminMarketingScreen extends StatelessWidget {
  const AdminMarketingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminMarketingController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Marketing Center", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AdminDrawer(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }

        // Show Banners List Directly (No Tabs)
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header Row for Banners
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Active Banners", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ElevatedButton.icon(
                    onPressed: () => _showBannerDialog(context: context, controller: controller),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Add New Banner"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              if (controller.banners.isEmpty)
                 Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                       const SizedBox(height: 10),
                       const Text("No Banners Found", style: TextStyle(fontSize: 18, color: Colors.grey)),
                     ],
                   ),
                 )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: controller.banners.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final banner = controller.banners[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: banner['image']!,
                              width: 80,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 80, 
                                height: 60, 
                                color: Colors.grey[200]
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                            ),
                          ),
                          title: Text(banner['title'] ?? 'No Title'),
                          subtitle: Text("Expires: ${banner['expiry_date'] ?? 'Never'}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: banner['status'] == 'active',
                                onChanged: (val) => controller.toggleBanner(banner['id']),
                                activeColor: Colors.green,
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showBannerDialog(context: context, controller: controller, banner: banner),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => controller.deleteBanner(banner['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  void _showBannerDialog({required BuildContext context, required AdminMarketingController controller, Map<String, dynamic>? banner}) {
    final titleController = TextEditingController(text: banner?['title'] ?? '');
    final dateController = TextEditingController(text: banner?['expiry_date'] ?? '');
    final formKey = GlobalKey<FormState>();
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(banner == null ? "Add Banner" : "Edit Banner"),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Banner Title"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: "Expiry Date (YYYY-MM-DD)",
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        dateController.text = picked.toIso8601String().split('T')[0];
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  InkWell(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setState(() => selectedImage = File(image.path));
                      }
                    },
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: selectedImage != null
                          ? (kIsWeb 
                              ? Image.network(selectedImage!.path, fit: BoxFit.cover) 
                              : Image.file(File(selectedImage!.path), fit: BoxFit.cover))
                          : (banner != null 
                              ? CachedNetworkImage(imageUrl: banner['image']!, fit: BoxFit.cover)
                              : const Center(child: Icon(Icons.add_a_photo, size: 40, color: Colors.grey))),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    if (banner == null) {
                      if (selectedImage == null) {
                        Get.snackbar("Error", "Please select an image");
                        return;
                      }
                      controller.addBanner(titleController.text, XFile(selectedImage!.path), dateController.text);
                    } else {
                      controller.updateBanner(
                        banner['id'], 
                        titleController.text, 
                        selectedImage != null ? XFile(selectedImage!.path) : null, 
                        dateController.text,
                        null 
                      );
                    }
                    Get.back();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                child: const Text("Save"),
              ),
            ],
          );
        }
      ),
    );
  }
}
