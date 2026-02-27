class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final List<CategoryModel> children;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    required this.children,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? 'Category',
      slug: json['slug'] ?? '',
      icon: json['icon'],
      children: (json['children'] as List?)
          ?.map((c) => CategoryModel.fromJson(c))
          .toList() ?? [],
    );
  }
}

class BannerModel {
  final int id;
  final String imagePath;
  final String? linkType;
  final String? linkId;

  BannerModel({
    required this.id,
    required this.imagePath,
    this.linkType,
    this.linkId,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      imagePath: json['image_path'] ?? '',
      linkType: json['link_type'],
      linkId: json['link_id']?.toString(),
    );
  }
}
