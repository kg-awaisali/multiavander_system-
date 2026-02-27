import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/flash_sale_model.dart';
import '../core/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants.dart';
import '../modules/product/views/product_detail_screen.dart';

class FlashSaleWidget extends StatefulWidget {
  final List<FlashSaleModel> sales;
  const FlashSaleWidget({super.key, required this.sales});

  @override
  State<FlashSaleWidget> createState() => _FlashSaleWidgetState();
}

class _FlashSaleWidgetState extends State<FlashSaleWidget> {
  late Timer _timer;
  Duration _timeLeft = const Duration();

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  void _calculateTimeLeft() {
    if (widget.sales.isEmpty) return;
    final now = DateTime.now();
    final endTime = widget.sales.first.endTime;
    if (mounted) {
      setState(() {
        _timeLeft = endTime.isAfter(now) ? endTime.difference(now) : const Duration();
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sales.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    "Flash Sale",
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text("Ending in ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(_timeLeft),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  "SHOP MORE >",
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 190,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: widget.sales.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                final sale = widget.sales[index];
                final product = sale.product;
                if (product == null) return const SizedBox.shrink();

                return GestureDetector(
                  onTap: () => Get.to(() => ProductDetailScreen(product: product)),
                  child: SizedBox(
                    width: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: product.images.isNotEmpty ? AppConstants.getImageUrl(product.images[0]) : '',
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                errorWidget: (context, url, error) => const Icon(Icons.flash_on, color: Colors.orange),
                              ),
                            ),
                            if (sale.isSoldOut)
                              Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    "SOLD OUT",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Rs. ${sale.flashPrice.toStringAsFixed(0)}",
                          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          "Rs. ${product.price.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: sale.soldPercentage,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              sale.isSoldOut ? Colors.grey : AppTheme.primaryColor,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${(sale.soldPercentage * 100).toStringAsFixed(0)}% Sold",
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ))
        ],
      ),
    );
  }
}
