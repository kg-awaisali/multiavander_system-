import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants.dart';
import '../controllers/home_controller.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/views/login_screen.dart';
import '../../product/views/product_detail_screen.dart';
import '../../cart/views/cart_screen.dart';
import '../../auth/views/seller_registration_screen.dart';
import '../../auth/views/profile_screen.dart';
import './category_list_screen.dart';
import '../../../widgets/product_card.dart';
import '../../../widgets/flash_sale_widget.dart';
import '../../../core/theme.dart';
import '../../../widgets/global_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    Get.put(CartController());
    final authController = Get.put(AuthController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light Grey Background
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
             UserAccountsDrawerHeader(
               decoration: const BoxDecoration(color: AppTheme.primaryColor),
               accountName: Obx(() => Text(authController.user.value?.name ?? "Guest User")),
               accountEmail: Obx(() => Text(authController.user.value?.email ?? "Sign in for more")),
               currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: AppTheme.primaryColor)),
             ),
             if (authController.user.value == null)
               ListTile(leading: const Icon(Icons.login), title: const Text('Login / Signup'), onTap: () => Get.to(() => LoginScreen())),
             ListTile(
               leading: const Icon(Icons.store), 
               title: const Text('Become a Seller'), 
               onTap: () { Get.back(); Get.to(() => SellerRegistrationScreen()); }
             ),
             Obx(() => authController.user.value != null ? ListTile(
               leading: const Icon(Icons.logout, color: Colors.red),
               title: const Text('Logout', style: TextStyle(color: Colors.red)),
               onTap: () {
                 Get.back();
                 authController.logout();
               },
             ) : const SizedBox.shrink()),
          ],
        ),
      ),
      body: Obx(() {
        // Data for Banners (Fallback to Placeholders if API empty)
        final bannerImages = controller.banners.isNotEmpty 
            ? controller.banners.map((e) => AppConstants.getImageUrl(e.imagePath)).toList()
            : [
                'https://icms-image.slatic.net/images/ims-web/bfe8de2c-b737-4265-b11f-7023f295d9b7.jpg',
                'https://icms-image.slatic.net/images/ims-web/e852d4dd-3739-411a-8287-6b453912185c.jpg',
              ];

        return RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async => controller.fetchHomeData(),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const GlobalHeader(isSliver: true),

              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // 2. Banners Slider
                    controller.isLoading.value && controller.banners.isEmpty
                      ? const _ShimmerBanner()
                      : _BannerCarousel(bannerImages: bannerImages),

                    // 3. Categories Grid
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Categories", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 90,
                            child: controller.isLoading.value && controller.categories.isEmpty
                              ? const _ShimmerCategories()
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: controller.categories.length,
                                  itemBuilder: (context, index) {
                                    final cat = controller.categories[index];
                                    return Container(
                                      width: 70,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      child: InkWell(
                                        onTap: () => controller.filterByCategory(cat),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 50, 
                                              height: 50,
                                              margin: const EdgeInsets.only(bottom: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withOpacity(0.1), // Subtle colorful background
                                                shape: BoxShape.circle, // Circular icons look more professional
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.05),
                                                    blurRadius: 5,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: ClipOval(
                                                child: cat.icon != null && cat.icon!.isNotEmpty
                                                  ? CachedNetworkImage(
                                                      imageUrl: AppConstants.getImageUrl(cat.icon!),
                                                      fit: BoxFit.cover,
                                                      placeholder: (context, url) => const Icon(Icons.category_outlined, color: Colors.orange, size: 24),
                                                      errorWidget: (context, url, error) => const Icon(Icons.category_outlined, color: Colors.orange, size: 24),
                                                    )
                                                  : const Icon(Icons.category_outlined, color: Colors.orange, size: 24),
                                              ),
                                            ),
                                            Text(
                                              cat.name, 
                                              textAlign: TextAlign.center, 
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500), 
                                              maxLines: 2, 
                                              overflow: TextOverflow.ellipsis
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 4. Flash Sale Section
                    Obx(() => controller.flashSales.isEmpty 
                        ? const SizedBox.shrink() 
                        : FlashSaleWidget(sales: controller.flashSales)),
                    
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Just For You", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 6. Products Grid or Shimmer
              controller.isLoading.value && controller.products.isEmpty
              ? SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: context.width > 600 ? 4 : 2,
                      childAspectRatio: 0.6,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const _ShimmerProductCard(),
                      childCount: 6,
                    ),
                  ),
                )
              : (controller.products.isEmpty 
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.shopping_basket_outlined, size: 60, color: Colors.grey),
                              SizedBox(height: 10),
                              Text("No products available yet", style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 5),
                              Obx(() => Text(
                                "DB: ${controller.dbName.value} | Total: ${controller.totalCount.value}",
                                style: const TextStyle(color: Colors.grey, fontSize: 10),
                              )),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: context.width > 1200 ? 6 : (context.width > 800 ? 4 : 2),
                          childAspectRatio: 0.6, // Increased to fix overflow
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = controller.products[index];
                            return ProductCard(
                              product: product,
                              onTap: () => Get.to(() => ProductDetailScreen(product: product)),
                            );
                          },
                          childCount: controller.products.length,
                        ),
                      ),
                    )),
                const SliverToBoxAdapter(child: SizedBox(height: 100)), // Extra space at bottom to ensure scrolling
              ],
            ),
          ),
        );
      }),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.category_outlined), activeIcon: Icon(Icons.category), label: 'Categories'),
          BottomNavigationBarItem(
            icon: Obx(() => Badge(
              label: Text('${Get.find<CartController>().totalItems}'),
              isLabelVisible: Get.find<CartController>().totalItems > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            )), 
            activeIcon: Obx(() => Badge(
              label: Text('${Get.find<CartController>().totalItems}'),
              isLabelVisible: Get.find<CartController>().totalItems > 0,
              child: const Icon(Icons.shopping_cart),
            )),
            label: 'Cart'
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Account'),
        ],
        onTap: (index) {
          if(index == 1) Get.to(() => const CategoryListScreen());
          if(index == 2) Get.to(() => const CartScreen());
          if(index == 3) Get.to(() => const ProfileScreen());
        },
      ),
    );
  }
}

// Auto-Rotating Banner Carousel Widget
class _BannerCarousel extends StatefulWidget {
  final List<String> bannerImages;
  const _BannerCarousel({required this.bannerImages});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && widget.bannerImages.isNotEmpty) {
        _currentPage = (_currentPage + 1) % widget.bannerImages.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 7,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
        ),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.bannerImages.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: widget.bannerImages[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => 
                      Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, color: Colors.grey)),
                );
              },
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.bannerImages.length, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index ? Colors.orange : Colors.white.withAlpha(150),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBanner extends StatelessWidget {
  const _ShimmerBanner();

  @override
  Widget build(BuildContext context) {
    double bannerHeight = context.width > 600 ? 350 : 180;
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: bannerHeight,
        width: double.infinity,
        color: Colors.white,
      ),
    );
  }
}

class _ShimmerCategories extends StatelessWidget {
  const _ShimmerCategories();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          width: 70,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(height: 10, width: 40, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerProductCard extends StatelessWidget {
  const _ShimmerProductCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
