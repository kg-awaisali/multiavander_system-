import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme.dart';
import '../modules/auth/controllers/auth_controller.dart';
import '../modules/auth/views/login_screen.dart';
import '../modules/cart/views/cart_screen.dart';
import '../modules/product/views/product_detail_screen.dart';
import '../modules/home/controllers/home_controller.dart';
import '../modules/cart/controllers/cart_controller.dart';
import '../modules/auth/views/seller_registration_screen.dart';
import '../modules/auth/views/profile_screen.dart';
import '../modules/chat/views/chat_list_screen.dart';
import '../../../core/constants.dart';

class GlobalHeader extends StatefulWidget {
  final bool showBackButton;
  final bool isSliver;

  const GlobalHeader({
    super.key,
    this.showBackButton = false,
    this.isSliver = true,
  });

  @override
  State<GlobalHeader> createState() => _GlobalHeaderState();
}

class _GlobalHeaderState extends State<GlobalHeader> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _hideTimer?.cancel();
    _hideOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) _hideOverlay();
      });
    }
  }

  void _showOverlay() {
    if (!mounted) return;
    _hideTimer?.cancel();
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      try {
        _overlayEntry?.remove();
      } catch (e) {
        // Overlay might have already been removed by the framework
        debugPrint("Overlay remove error: $e");
      }
      _overlayEntry = null;
    }
  }

  OverlayEntry _createOverlayEntry() {
    final homeController = Get.find<HomeController>();
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 40,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(widget.showBackButton ? 40 : 10, 42),
          child: Material(
            elevation: 8,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(4),
            child: Obx(() {
              final query = homeController.searchQuery.value;
              final history = homeController.searchHistory;
              final suggestions = homeController.suggestions;

              if (query.isEmpty && history.isEmpty) return const SizedBox.shrink();

              return Container(
                constraints: const BoxConstraints(maxHeight: 450),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (query.isEmpty && history.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Search History", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                            GestureDetector(
                              onTap: () => homeController.clearAllHistory(),
                              child: const Text("CLEAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final h = history[index];
                            return ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              title: Text(h, style: const TextStyle(fontSize: 14)),
                              onTap: () {
                                homeController.searchController.text = h;
                                homeController.search(h);
                                _focusNode.unfocus();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                    if (query.isNotEmpty) ...[
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.search, size: 20, color: Colors.orange),
                        title: Text("Search for \"$query\"", style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.orange)),
                        onTap: () {
                          homeController.search(query);
                          homeController.addToHistory(query);
                          _focusNode.unfocus();
                        },
                      ),
                      if (suggestions.isNotEmpty) const Divider(height: 1),
                      Flexible(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: suggestions.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final p = suggestions[index];
                            return ListTile(
                              leading: Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey[100]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    AppConstants.getImageUrl(p.images.isNotEmpty ? p.images[0] : ''),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              title: Text(p.name, style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text("Rs. ${p.price}", style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                              onTap: () {
                                homeController.addToHistory(p.name);
                                _focusNode.unfocus();
                                Get.to(() => ProductDetailScreen(product: p));
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void onSearchSubmit(String query) {
    final homeController = Get.find<HomeController>();
    homeController.search(query);
    if (query.isNotEmpty) {
      homeController.addToHistory(query);
    }
    _focusNode.unfocus();
    
    // Force navigation to results to allow filtering "All Products"
    if (Get.currentRoute != '/search-results') {
      Get.toNamed('/search-results');
    }
  }

  Widget _buildSearchField(BuildContext context) {
    final homeController = Get.find<HomeController>();
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Icon(Icons.search, color: Colors.grey, size: 20),
          ),
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: homeController.searchController,
              onSubmitted: onSearchSubmit,
              onChanged: (val) => homeController.search(val),
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search in Zbardast...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(bottom: 7),
              ),
            ),
          ),
          Obx(() => homeController.searchQuery.value.isNotEmpty
             ? GestureDetector(
                 onTap: () {
                   homeController.searchController.clear();
                   homeController.search('');
                 },
                 child: const Padding(
                   padding: EdgeInsets.symmetric(horizontal: 10),
                   child: Icon(Icons.close, color: Colors.grey, size: 18),
                 ),
               )
             : const SizedBox.shrink()),
          // Price Filter Icon
          GestureDetector(
            onTap: () => _showPriceFilterBottomSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey.withOpacity(0.2))),
              ),
              child: const Icon(Icons.filter_list_rounded, color: AppTheme.primaryColor, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _showPriceFilterBottomSheet(BuildContext context) {
    final homeController = Get.find<HomeController>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Price Range", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Obx(() => Column(
              children: [
                 Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Rs. ${homeController.currentMinPrice.value.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text("Rs. ${homeController.currentMaxPrice.value.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                RangeSlider(
                  values: RangeValues(homeController.currentMinPrice.value, homeController.currentMaxPrice.value),
                  min: homeController.minPrice.value,
                  max: homeController.maxPrice.value,
                  divisions: 100,
                  activeColor: AppTheme.primaryColor,
                  inactiveColor: AppTheme.primaryColor.withOpacity(0.2),
                  labels: RangeLabels(
                    homeController.currentMinPrice.value.toStringAsFixed(0),
                    homeController.currentMaxPrice.value.toStringAsFixed(0),
                  ),
                  onChanged: (RangeValues values) {
                    homeController.updatePriceFilter(values.start, values.end);
                  },
                ),
              ],
            )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("APPLY FILTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    final Widget flexibleSpace = ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.8),
                AppTheme.primaryColor.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 0.5)),
          ),
        ),
      ),
    );

    final Widget? leading = widget.showBackButton 
      ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        )
      : null;

    final double leadingWidth = widget.showBackButton ? 40 : 0;

    final Widget title = Row(
      children: [
        if (!widget.showBackButton)
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 24),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        Expanded(child: _buildSearchField(context)),
      ],
    );

    final List<Widget> actions = [
      _buildBecomeSellerButton(),
      IconButton(
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        icon: Obx(() {
          final cartCount = Get.find<CartController>().totalItems;
          return Badge(
            label: Text('$cartCount'),
            isLabelVisible: cartCount > 0,
            backgroundColor: Colors.white,
            textColor: AppTheme.primaryColor,
            child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 22),
          );
        }),
        onPressed: () => Get.to(() => const CartScreen()),
      ),
      IconButton(
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
        onPressed: () => Get.to(() => const ChatListScreen()),
      ),
      IconButton(
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        icon: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 22),
        onPressed: () => Get.to(() => const ProfileScreen()),
      ),
    ];

    final PreferredSizeWidget bottom = PreferredSize(
      preferredSize: const Size.fromHeight(40),
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              _buildTrendItem("makeup"),
              _buildTrendItem("bags"),
              _buildTrendItem("watches"),
              _buildTrendItem("airpods"),
              _buildTrendItem("bottles"),
              _buildTrendItem("shoes"),
            ],
          ),
        ),
      ),
    );

    if (widget.isSliver) {
      return SliverAppBar(
        backgroundColor: Colors.transparent,
        floating: false,
        pinned: true,
        elevation: 0,
        toolbarHeight: kToolbarHeight,
        flexibleSpace: flexibleSpace,
        automaticallyImplyLeading: false,
        leading: leading,
        leadingWidth: leadingWidth,
        titleSpacing: 0,
        title: title,
        actions: actions,
        bottom: bottom,
      );
    }

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 35),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: flexibleSpace,
        automaticallyImplyLeading: false,
        leading: leading,
        leadingWidth: leadingWidth,
        titleSpacing: 0,
        title: title,
        actions: actions,
        bottom: bottom,
      ),
    );
  }

  Widget _buildBecomeSellerButton() {
    final authController = Get.find<AuthController>();
    return Obx(() {
      // Access isLoggedIn here to trigger reactive dependency
      final isLog = authController.isLoggedIn;
      
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextButton(
          onPressed: () {
            if (isLog) {
              Get.to(() => const SellerRegistrationScreen());
            } else {
              Get.to(() => LoginScreen());
            }
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text("SELL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
      );
    });
  }

  Widget _buildTrendItem(String text) {
    final homeController = Get.find<HomeController>();
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          homeController.searchController.text = text;
          homeController.search(text);
          homeController.addToHistory(text);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
