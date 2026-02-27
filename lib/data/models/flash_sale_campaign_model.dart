class FlashSaleCampaignModel {
  final int id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final String status;

  FlashSaleCampaignModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory FlashSaleCampaignModel.fromJson(Map<String, dynamic> json) {
    return FlashSaleCampaignModel(
      id: json['id'],
      name: json['name'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      status: json['status'],
    );
  }

  bool get isActive => DateTime.now().isAfter(startTime) && DateTime.now().isBefore(endTime);
  bool get isUpcoming => DateTime.now().isBefore(startTime);
}
