import 'product_model.dart';

class FlashSaleModel {
  final int id;
  final int productId;
  final double flashPrice;
  final int stockLimit;
  final int soldCount;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final bool isApproved;
  final ProductModel? product;

  final String? campaignName;

  FlashSaleModel({
    required this.id,
    required this.productId,
    required this.flashPrice,
    required this.stockLimit,
    required this.soldCount,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.isApproved,
    this.product,
    this.campaignName,
  });

  factory FlashSaleModel.fromJson(Map<String, dynamic> json) {
    return FlashSaleModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      flashPrice: double.tryParse(json['flash_price']?.toString() ?? '0') ?? 0,
      stockLimit: int.tryParse(json['stock_limit']?.toString() ?? '0') ?? 0,
      soldCount: int.tryParse(json['sold_count']?.toString() ?? '0') ?? 0,
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      status: json['status'],
      isApproved: json['is_approved'] == 1 || json['is_approved'] == true,
      product: json['product'] != null ? ProductModel.fromJson(json['product']) : null,
      campaignName: json['campaign'] != null ? json['campaign']['name'] : null,
    );
  }

  double get soldPercentage => stockLimit > 0 ? (soldCount / stockLimit) : 0;
  bool get isSoldOut => soldCount >= stockLimit;
}
