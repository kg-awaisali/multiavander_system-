import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/home_controller.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key});

  // Function to get icon based on category name
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    
    if (name.contains('bag') || name.contains('backpack')) {
      return Icons.backpack;
    } else if (name.contains('health') || name.contains('beauty') || name.contains('spa')) {
      return Icons.spa;
    } else if (name.contains('grocery') || name.contains('food')) {
      return Icons.shopping_basket;
    } else if (name.contains('electronic') || name.contains('phone')) {
      return Icons.smartphone;
    } else if (name.contains('fashion') || name.contains('clothes')) {
      return Icons.checkroom;
    } else if (name.contains('home') || name.contains('furniture')) {
      return Icons.home;
    } else if (name.contains('book') || name.contains('stationery')) {
      return Icons.menu_book;
    } else if (name.contains('sports') || name.contains('fitness')) {
      return Icons.sports_soccer;
    } else if (name.contains('toy') || name.contains('game')) {
      return Icons.toys;
    } else if (name.contains('car') || name.contains('auto')) {
      return Icons.directions_car;
    } else if (name.contains('jewel') || name.contains('watch')) {
      return Icons.watch;
    } else {
      // Default shopping bag for all other categories
      return Icons.shopping_bag;
    }
  }

  // Function to get gradient based on category
  LinearGradient _getCategoryGradient(String categoryName) {
    final name = categoryName.toLowerCase();
    
    if (name.contains('bag') || name.contains('school') || name.contains('backpack')) {
      return const LinearGradient(
        colors: [Color(0xFF2575FC), Color(0xFF6A11CB)], // Blue to Purple
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (name.contains('health') || name.contains('beauty') || name.contains('spa')) {
      return const LinearGradient(
        colors: [Color(0xFF00CDAC), Color(0xFF6A11CB)], // Teal to Purple
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (name.contains('grocery') || name.contains('food') || name.contains('vegetable')) {
      return const LinearGradient(
        colors: [Color(0xFF00CDAC), Color(0xFF2575FC)], // Teal to Blue
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (name.contains('electronic') || name.contains('phone')) {
      return const LinearGradient(
        colors: [Color(0xFF6A11CB), Color(0xFF2575FC)], // Purple to Blue
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (name.contains('fashion') || name.contains('clothes')) {
      return const LinearGradient(
        colors: [Color(0xFF00CDAC), Color(0xFF2575FC)], // Teal to Blue
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (name.contains('home') || name.contains('furniture')) {
      return const LinearGradient(
        colors: [Color(0xFF6A11CB), Color(0xFF00CDAC)], // Purple to Teal
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      // Default gradient for all categories
      return AppTheme.primaryGradient;
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Categories', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Obx(() {
        if (homeController.categories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
          ),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: homeController.categories.length,
            itemBuilder: (context, index) {
              final cat = homeController.categories[index];
              final icon = _getCategoryIcon(cat.name);
              final gradient = _getCategoryGradient(cat.name);
              
              return InkWell(
                onTap: () {
                  homeController.filterByCategory(cat);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Shopping Bag Icon Container
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: gradient.colors.first.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Category Name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          cat.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // "Shop Now" Text
                      Text(
                        'Shop Now',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: gradient.colors.first,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}