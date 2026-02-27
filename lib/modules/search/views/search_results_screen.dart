import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/global_header.dart';
import '../../../widgets/product_card.dart';
import '../../home/controllers/home_controller.dart';
import '../../product/views/product_detail_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return WillPopScope(
      onWillPop: () async {
        // Reset search state so Home screen looks clean
        controller.resetSearchState();
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F4),
        body: CustomScrollView(
          slivers: [
            const GlobalHeader(isSliver: true, showBackButton: true),
            
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 800;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? context.width * 0.05 : 10,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Breadcrumb
                        Obx(() => Text(
                          controller.searchQuery.value.isEmpty 
                            ? "All Categories > All Products"
                            : "All Categories > Search results for \"${controller.searchQuery.value}\"",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        )),
                        const SizedBox(height: 20),
                        
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sidebar Filters (Daraz Style)
                            if (isWide)
                              SizedBox(
                                width: 220,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFilterSection("Category", [
                                      "Men's Shoes",
                                      "Sneakers",
                                      "Fashion",
                                      "Accessories"
                                    ]),
                                    const Divider(height: 30),
                                    _buildFilterSection("Brand", [
                                      "Nike",
                                      "Adidas",
                                      "Puma",
                                      "Local Brand"
                                    ]),
                                    const Divider(height: 30),
                                    _buildPriceFilter(controller),
                                  ],
                                ),
                              ),
                            
                            // Results Grid
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Results Header
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Obx(() => Text(
                                            controller.searchQuery.value.isEmpty 
                                              ? "All Products"
                                              : controller.searchQuery.value,
                                            style: const TextStyle(
                                              fontSize: 22, 
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87
                                            ),
                                          )),
                                          const SizedBox(height: 4),
                                          Obx(() => Text(
                                            "${controller.products.length} items found",
                                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                          )),
                                        ],
                                      ),
                                      // Sort / View Toggles
                                      Row(
                                        children: [
                                          const Text("Sort By: ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey[300]!),
                                              borderRadius: BorderRadius.circular(4),
                                              color: Colors.white,
                                            ),
                                            child: const Row(
                                              children: [
                                                Text("Best Match", style: TextStyle(fontSize: 12)),
                                                Icon(Icons.keyboard_arrow_down, size: 16),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  Obx(() {
                                    if (controller.products.isEmpty) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(50.0),
                                          child: Text("No items found. Try different keywords!"),
                                        ),
                                      );
                                    }
                                    return GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isWide ? (constraints.maxWidth > 1200 ? 5 : 4) : 2,
                                        childAspectRatio: 0.6, // Adjusted from 0.7 to handle ProductCard info height
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                      ),
                                      itemCount: controller.products.length,
                                      itemBuilder: (context, index) {
                                        final product = controller.products[index];
                                        return ProductCard(
                                          product: product,
                                          onTap: () => Get.to(() => ProductDetailScreen(product: product)),
                                        );
                                      },
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: InkWell(
            onTap: () {},
            child: Text(
              item, 
              style: const TextStyle(fontSize: 13, color: Colors.black87)
            ),
          ),
        )),
        const SizedBox(height: 8),
        const Text("VIEW MORE", style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPriceFilter(HomeController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Price Range", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        Obx(() {
          // Ensure values are within bounds
          double min = controller.currentMinPrice.value;
          double max = controller.currentMaxPrice.value;
          double totalMax = controller.maxPrice.value;
          
          if (max > totalMax) max = totalMax;
          if (min > max) min = max;

          return Column(
            children: [
              RangeSlider(
                values: RangeValues(min, max),
                min: 0,
                max: totalMax > 0 ? totalMax : 10000.0, // Prevent 0/0 error
                divisions: 100,
                labels: RangeLabels(
                  "Rs. ${min.toInt()}",
                  "Rs. ${max.toInt()}",
                ),
                onChanged: (RangeValues values) {
                  controller.updatePriceFilter(values.start, values.end);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Rs. ${min.toInt()}", style: const TextStyle(fontSize: 12)),
                  Text("Rs. ${max.toInt()}", style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          );
        }),
      ],
    );
  }
}
