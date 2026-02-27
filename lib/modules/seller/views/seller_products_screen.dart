import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/seller_product_controller.dart';
import '../controllers/seller_flash_sale_controller.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';

class SellerProductsScreen extends StatelessWidget {
  const SellerProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerProductController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.fetchProducts();
              controller.fetchCategories();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(context, controller, null),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white)),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('No products yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _showProductDialog(context, controller, null),
                  child: const Text('Add Your First Product'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchProducts,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: controller.products.length,
            itemBuilder: (context, index) {
              final product = controller.products[index];
              return _buildProductCard(product, controller, context);
            },
          ),
        );
      }),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, SellerProductController controller, BuildContext context) {
    final variations = product['variations'] as List? ?? [];
    final totalStock = variations.isNotEmpty 
        ? variations.fold<int>(0, (sum, v) => sum + ((v['stock'] ?? 0) as int))
        : (product['stock'] ?? 0) as int;

    // Price handling - FIX: Show original crossed, discounted in green
    final double originalPrice = double.tryParse(product['price']?.toString() ?? '0') ?? 0;
    final double? discountedPrice = product['discounted_price'] != null 
        ? double.tryParse(product['discounted_price'].toString()) 
        : null;
    final bool hasDiscount = discountedPrice != null && discountedPrice < originalPrice;

    // Image handling
    final images = product['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0].toString() : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null
                  ? Image.network(
                      AppConstants.getImageUrl(imageUrl),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),
            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Unnamed',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['category']?['name'] ?? 'No Category',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  
                  // FIXED PRICE DISPLAY
                  Row(
                    children: [
                      if (hasDiscount) ...[
                        // Discounted price (main - green)
                        Text(
                          'Rs. ${discountedPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Original price (crossed out)
                        Text(
                          'Rs. ${originalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ] else ...[
                        // Only original price
                        Text(
                          'Rs. ${originalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: product['status'] == 'active' ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product['status']?.toString().toUpperCase() ?? 'ACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            color: product['status'] == 'active' ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Stock: $totalStock', style: const TextStyle(fontSize: 12)),
                      if (variations.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text('${variations.length} variants', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showProductDialog(context, controller, product),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, product['id'], controller),
                ),
                IconButton(
                  icon: const Icon(Icons.flash_on, color: Colors.orange),
                  tooltip: 'Suggest for Flash Sale',
                  onPressed: () => _showFlashSaleSuggestionDialog(context, product),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image, color: Colors.grey.shade400, size: 32),
    );
  }

  void _showProductDialog(BuildContext context, SellerProductController controller, Map<String, dynamic>? existingProduct) {
    controller.fetchCategories(); // Ensure categories are loaded
    final isEdit = existingProduct != null;
    final formKey = GlobalKey<FormState>();
    
    // Controllers
    final nameController = TextEditingController(text: existingProduct?['name'] ?? '');
    final descController = TextEditingController(text: existingProduct?['description'] ?? '');
    final shortDescController = TextEditingController(text: existingProduct?['short_description'] ?? '');
    final brandController = TextEditingController(text: existingProduct?['brand'] ?? '');
    final priceController = TextEditingController(text: existingProduct?['price']?.toString() ?? '');
    final discountedPriceController = TextEditingController(text: existingProduct?['discounted_price']?.toString() ?? '');
    final stockController = TextEditingController(text: existingProduct?['stock']?.toString() ?? '');
    
    int? selectedCategoryId = existingProduct?['category_id'];
    bool hasVariations = existingProduct?['has_variations'] ?? false;
    
    // Image handling - up to 5 images
    RxList<String> imageUrls = RxList<String>.from((existingProduct?['images'] as List?)?.map((e) => e.toString()) ?? []);
    RxList<XFile> newImageFiles = RxList<XFile>([]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(sheetContext).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: StatefulBuilder(
          builder: (dialogContext, setState) => Form(
            key: formKey,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isEdit ? 'Edit Product' : 'Add New Product', 
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // IMAGE UPLOAD SECTION - Up to 5 images
                        const Text('Product Images (Up to 5)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: Obx(() => ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // Existing images (URLs from server)
                              ...imageUrls.asMap().entries.map((entry) => Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        entry.value,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Icon(Icons.broken_image, color: Colors.grey.shade400),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        imageUrls.removeAt(entry.key);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                              
                              // New images (picked files)
                              ...newImageFiles.asMap().entries.map((entry) => Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        entry.value.path,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        newImageFiles.removeAt(entry.key);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                              
                              // Add button (if less than 5)
                              if (imageUrls.length + newImageFiles.length < 5)
                                GestureDetector(
                                  onTap: () async {
                                    final picker = ImagePicker();
                                    final picked = await picker.pickImage(source: ImageSource.gallery);
                                    if (picked != null) {
                                      newImageFiles.add(picked);
                                    }
                                  },
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300, width: 2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate, color: Colors.grey.shade500, size: 28),
                                        Text('Add', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          )),
                        ),
                        const SizedBox(height: 16),

                        // Category Selection
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Category *', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextButton.icon(
                              onPressed: () async {
                                await _showCategorySuggestionDialog(context, controller, (newId) {
                                  if (context.mounted) { // Ensure context is valid
                                    setState(() {
                                      selectedCategoryId = newId;
                                      controller.fetchCategoryAttributes(newId);
                                    });
                                  }
                                });
                              },
                              icon: const Icon(Icons.add_circle_outline, size: 16),
                              label: const Text('Add New / Other', style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Obx(() {
                          if (controller.categories.isEmpty) {
                             return Container(
                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                               decoration: BoxDecoration(
                                 border: Border.all(color: Colors.grey),
                                 borderRadius: BorderRadius.circular(4),
                               ),
                               child: Row(
                                 children: const [
                                   Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                                   SizedBox(width: 8),
                                   Text('No categories found. Add new?', style: TextStyle(color: Colors.grey)),
                                 ],
                               ),
                             );
                          }

                          final dropdownItems = controller.categories.map((cat) {
                            final int id = int.tryParse(cat['id'].toString()) ?? 0;
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(cat['name'] ?? ''),
                            );
                          }).toList();
                          
                          // Fix: Ensure selected value exists in the list
                          final bool valueExists = dropdownItems.any((item) => item.value == selectedCategoryId);
                          
                          return DropdownButtonFormField<int>(
                            initialValue: valueExists ? selectedCategoryId : null,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            hint: const Text('Select Category'),
                            items: dropdownItems,
                            onChanged: (val) {
                              setState(() => selectedCategoryId = val);
                              if (val != null) controller.fetchCategoryAttributes(val);
                            },
                            validator: (v) => v == null ? 'Required' : null,
                          );
                        }),
                        const SizedBox(height: 16),

                        // Name
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Product Name *', border: OutlineInputBorder()),
                          validator: (v) => v?.isEmpty == true ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),

                        // Brand
                        TextFormField(
                          controller: brandController,
                          decoration: const InputDecoration(labelText: 'Brand', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),

                        // Short Description
                        TextFormField(
                          controller: shortDescController,
                          decoration: const InputDecoration(labelText: 'Short Description', border: OutlineInputBorder()),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),

                        // Description
                        TextFormField(
                          controller: descController,
                          decoration: const InputDecoration(labelText: 'Full Description', border: OutlineInputBorder()),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),

                        // Price Row - FIXED LABELS
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: priceController,
                                decoration: const InputDecoration(
                                  labelText: 'Original Price *', 
                                  border: OutlineInputBorder(), 
                                  prefixText: 'Rs. ',
                                  helperText: 'Regular price',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) => v?.isEmpty == true ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: discountedPriceController,
                                decoration: const InputDecoration(
                                  labelText: 'Sale Price', 
                                  border: OutlineInputBorder(), 
                                  prefixText: 'Rs. ',
                                  helperText: 'Leave empty if no discount',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Has Variations Toggle
                        SwitchListTile(
                          title: const Text('Has Variations (Size/Color etc.)'),
                          subtitle: const Text('Enable if product has multiple options'),
                          value: hasVariations,
                          onChanged: (v) => setState(() => hasVariations = v),
                          contentPadding: EdgeInsets.zero,
                        ),

                        if (!hasVariations) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: stockController,
                            decoration: const InputDecoration(labelText: 'Stock Quantity *', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            validator: (v) => v?.isEmpty == true ? 'Required' : null,
                          ),
                        ],

                        // Dynamic Category Attributes
                        Obx(() {
                          if (controller.categoryAttributes.isEmpty) return const SizedBox();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              const Text('Category Specific Fields', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 12),
                              ...controller.categoryAttributes.map((attr) {
                                final int id = attr['id'];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TextFormField(
                                    initialValue: controller.attributeValues[id] ?? '',
                                    decoration: InputDecoration(
                                      labelText: '${attr['attribute_name']}${attr['is_required'] == true ? ' *' : ''}',
                                      border: const OutlineInputBorder(),
                                      helperText: attr['attribute_type'] == 'select' ? 'Options: ${(attr['options'] as List?)?.join(', ') ?? ''}' : null,
                                    ),
                                    onChanged: (val) {
                                      controller.attributeValues[id] = val;
                                    },
                                    validator: (v) {
                                      if (attr['is_required'] == true && (v == null || v.isEmpty)) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                );
                              }),
                            ],
                          );
                        }),

                        // VARIATION MANAGER SECTION
                        if (hasVariations) ...[
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Product Variations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              TextButton.icon(
                                onPressed: () => _addVariationDialog(context, controller),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Variant'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          Obx(() {
                            if (controller.draftVariations.isEmpty) {
                              return const Center(child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('No variants added yet', style: TextStyle(color: Colors.grey)),
                              ));
                            }
                            return Column(
                              children: controller.draftVariations.asMap().entries.map((entry) {
                                final index = entry.key;
                                final v = entry.value;
                                final attrs = v['attributes'] as Map<String, dynamic>;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(attrs.entries.map((e) => '${e.key}: ${e.value}').join(' / ')),
                                    subtitle: Text('SKU: ${v['sku'] ?? 'N/A'} | Price: Rs. ${v['price']} | Stock: ${v['stock']}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => controller.removeDraftVariation(index),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          }),
                        ],

                        const SizedBox(height: 24),

                        // Submit Button
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                // Step 1: Upload new images if any
                                List<String> uploadedImageUrls = List.from(imageUrls);
                                
                                if (newImageFiles.isNotEmpty) {
                                  Get.snackbar('Uploading', 'Uploading images...');
                                  for (var imageFile in newImageFiles) {
                                    final uploadedUrl = await controller.uploadImage(imageFile);
                                    if (uploadedUrl != null) {
                                      uploadedImageUrls.add(uploadedUrl);
                                    }
                                  }
                                }
                                
                                // Step 2: Create/Update product with image URLs
                                final productData = {
                                  'category_id': selectedCategoryId,
                                  'name': nameController.text,
                                  'description': descController.text,
                                  'short_description': shortDescController.text,
                                  'brand': brandController.text,
                                  'price': double.tryParse(priceController.text) ?? 0,
                                  'discounted_price': discountedPriceController.text.isNotEmpty 
                                      ? double.tryParse(discountedPriceController.text) : null,
                                  'stock': int.tryParse(stockController.text) ?? 0,
                                  'has_variations': hasVariations,
                                  'images': uploadedImageUrls,
                                  'category_attributes': controller.attributeValues,
                                  'variations': hasVariations ? controller.draftVariations : null,
                                };
                                
                                bool success;
                                if (isEdit) {
                                  success = await controller.updateProduct(existingProduct['id'], productData);
                                } else {
                                  success = await controller.createProduct(productData);
                                }
                                
                                if (success && context.mounted) Navigator.pop(context);
                              }
                            },
                            child: Text(
                              isEdit ? 'Update Product' : 'Create Product', 
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addVariationDialog(BuildContext context, SellerProductController controller) {
    final colorController = TextEditingController();
    final sizeController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final skuController = TextEditingController();
    XFile? variationImageFile; // NEW: To hold the picked image

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setDialogState) => AlertDialog(
          title: const Text('Add Product Variation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                  child: const Text(
                    'Important: Add ONE variation at a time (e.g. Red / XL). Upload a photo for Color variations.',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
                // NEW: Variation Image Picker
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setDialogState(() => variationImageFile = picked);
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      image: variationImageFile != null
                          ? DecorationImage(
                              image: NetworkImage(variationImageFile!.path), // Works on web
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: variationImageFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.grey.shade500, size: 28),
                              Text('Add Image', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                            ],
                          )
                        : null,
                  ),
                ),
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(labelText: 'Color (e.g. Red)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sizeController,
                  decoration: const InputDecoration(labelText: 'Size (e.g. XL)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16), // Increased spacing
                TextField(
                  controller: skuController,
                  decoration: const InputDecoration(labelText: 'SKU (Optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16), // Increased spacing
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price *', border: OutlineInputBorder(), prefixText: 'Rs. '),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16), // Increased spacing
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(labelText: 'Stock *', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (priceController.text.isEmpty || stockController.text.isEmpty) {
                  Get.snackbar('Error', 'Price and Stock are required');
                  return;
                }

                Map<String, String> attrs = {};
                if (colorController.text.isNotEmpty) attrs['Color'] = colorController.text;
                if (sizeController.text.isNotEmpty) attrs['Size'] = sizeController.text;

                if (attrs.isEmpty) {
                  Get.snackbar('Error', 'Please provide at least one attribute (Color or Size)');
                  return;
                }

                // Upload variation image if selected
                String? uploadedImgUrl;
                if (variationImageFile != null) {
                  uploadedImgUrl = await controller.uploadImage(variationImageFile!);
                }

                controller.addDraftVariation({
                  'attributes': attrs,
                  'price': double.tryParse(priceController.text) ?? 0,
                  'stock': int.tryParse(stockController.text) ?? 0,
                  'sku': skuController.text.isEmpty ? null : skuController.text,
                  'variation_image': uploadedImgUrl,
                });
                Get.back();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int productId, SellerProductController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteProduct(productId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showCategorySuggestionDialog(
      BuildContext context, 
      SellerProductController controller, 
      Function(int) onCategoryCreated
  ) async {
    final nameController = TextEditingController();
    RxList<Map<String, dynamic>> attributes = <Map<String, dynamic>>[].obs;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Suggest New Category'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category Name', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Gaming Chairs',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Attributes (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () {
                        attributes.add({
                          'name': '',
                          'type': 'text',
                          'is_required': false,
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Field'),
                    ),
                  ],
                ),
                const Text('Define fields like Material, Voltage, Size etc.', 
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                
                Obx(() => Column(
                  children: attributes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final attr = entry.value; // Not reactive directly
                    
                    return Card(
                      color: Colors.grey.shade50,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: attr['name'],
                                    decoration: const InputDecoration(labelText: 'Field Name'),
                                    onChanged: (v) => attributes[index]['name'] = v,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => attributes.removeAt(index),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: attr['type'],
                                    decoration: const InputDecoration(labelText: 'Type'),
                                    items: const [
                                      DropdownMenuItem(value: 'text', child: Text('Text')),
                                      DropdownMenuItem(value: 'number', child: Text('Number')),
                                      DropdownMenuItem(value: 'boolean', child: Text('Yes/No')),
                                    ],
                                    onChanged: (v) => attributes[index]['type'] = v,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CheckboxListTile(
                                    title: const Text('Required', style: TextStyle(fontSize: 12)),
                                    value: attr['is_required'],
                                    contentPadding: EdgeInsets.zero,
                                    onChanged: (v) {
                                      // Force refresh list to update UI check
                                      var item = attributes[index];
                                      item['is_required'] = v;
                                      attributes[index] = item;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                Get.snackbar('Error', 'Category name is required');
                return;
              }
              
              Get.back(); // Close dialog first
              
              // Show loading
              Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
              
              final newId = await controller.suggestCategory(
                nameController.text, 
                attributes
              );
              
              Get.back(); // Close loading
              
              if (newId != null) {
                onCategoryCreated(newId);
                Get.snackbar('Success', 'Category suggested & selected! waiting for approval.', 
                    backgroundColor: Colors.green.shade100);
              }
            },
            child: const Text('Submit Suggestion'),
          ),
        ],
      ),
    );
  }

  void _showFlashSaleSuggestionDialog(BuildContext context, Map<String, dynamic> product) {
    final flashController = Get.put(SellerFlashSaleController());
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    int? selectedCampaignId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Suggest Flash Sale for ${product['name']}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Select a campaign slot created by Admin to nominate your product.", 
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                
                // Campaign Selection
                Obx(() {
                  if (flashController.isLoading.value) return const LinearProgressIndicator();
                  if (flashController.campaigns.isEmpty) return const Text("No available campaign slots.", style: TextStyle(color: Colors.red));
                  
                  return DropdownButtonFormField<int>(
                    initialValue: selectedCampaignId,
                    decoration: const InputDecoration(labelText: "Choose Campaign Slot", border: OutlineInputBorder()),
                    items: flashController.campaigns.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (val) => setState(() => selectedCampaignId = val),
                  );
                }),
                
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: "Flash Price", border: OutlineInputBorder(), prefixText: "Rs. "),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(labelText: "Flash Stock Limit", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            Obx(() => ElevatedButton(
              onPressed: (flashController.isLoading.value || selectedCampaignId == null) ? null : () async {
                final success = await flashController.suggestFlashSale(
                  productId: product['id'],
                  campaignId: selectedCampaignId!,
                  flashPrice: double.tryParse(priceController.text) ?? 0,
                  stockLimit: int.tryParse(stockController.text) ?? 0,
                );
                if (success) Get.back();
              },
              child: flashController.isLoading.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Submit Nomination"),
            )),
          ],
        ),
      ),
    );
  }
}
