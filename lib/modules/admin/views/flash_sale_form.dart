import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_flash_sale_controller.dart';
import '../../../data/models/product_model.dart';
import '../../../core/theme.dart';

class FlashSaleForm extends StatefulWidget {
  const FlashSaleForm({super.key});

  @override
  State<FlashSaleForm> createState() => _FlashSaleFormState();
}

class _FlashSaleFormState extends State<FlashSaleForm> {
  final controller = Get.put(AdminFlashSaleController());
  
  ProductModel? selectedProduct;
  final flashPriceController = TextEditingController();
  final stockLimitController = TextEditingController();
  DateTime startTime = DateTime.now().add(const Duration(minutes: 5));
  DateTime endTime = DateTime.now().add(const Duration(hours: 24));

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? startTime : endTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? startTime : endTime),
      );
      if (pickedTime != null) {
        setState(() {
          final newDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (isStart) {
            startTime = newDateTime;
          } else {
            endTime = newDateTime;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Flash Sale", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Product Selection", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Obx(() => DropdownButtonFormField<ProductModel>(
              isExpanded: true,
              value: selectedProduct,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Select Product",
              ),
              items: controller.allProducts.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(p.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedProduct = val),
            )),
            if (selectedProduct != null) ...[
              const SizedBox(height: 8),
              Text("Original Price: Rs. ${selectedProduct!.price}", style: const TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: flashPriceController,
              decoration: const InputDecoration(
                labelText: "Flash Sale Price",
                border: OutlineInputBorder(),
                prefixText: "Rs. ",
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: stockLimitController,
              decoration: const InputDecoration(
                labelText: "Stock Limit (Quantity for Sale)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            const Text("Campaign Schedule", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              title: const Text("Start Time"),
              subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(startTime)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDateTime(context, true),
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text("End Time"),
              subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(endTime)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDateTime(context, false),
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 40),
            Obx(() => SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                onPressed: controller.isLoading.value ? null : () async {
                  if (selectedProduct == null) {
                    Get.snackbar("Error", "Please select a product");
                    return;
                  }
                  final price = double.tryParse(flashPriceController.text) ?? 0;
                  if (price <= 0 || price >= selectedProduct!.price) {
                    Get.snackbar("Error", "Invalid Flash Price. Must be lower than original price.");
                    return;
                  }
                  final stock = int.tryParse(stockLimitController.text) ?? 0;
                  if (stock <= 0) {
                    Get.snackbar("Error", "Invalid Stock Limit");
                    return;
                  }
                  if (endTime.isBefore(startTime)) {
                    Get.snackbar("Error", "End time must be after start time");
                    return;
                  }

                  final success = await controller.createFlashSale(
                    productId: selectedProduct!.id,
                    flashPrice: price,
                    stockLimit: stock,
                    startTime: startTime,
                    endTime: endTime,
                  );
                  if (success) Get.back();
                },
                child: controller.isLoading.value 
                  ? Center(child: CircularProgressIndicator(color: Colors.white))
                  : const Text("LAUNCH CAMPAIGN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
