class Product {
  final int id;
  final String productName;
  final String categoryName;
  final int subCategoryId;
  final String imageUrl;
  final String sellingPrice;
  final String slug;

  Product({
    required this.id,
    required this.productName,
    required this.categoryName,
    required this.subCategoryId,
    required this.imageUrl,
    required this.sellingPrice,
    required this.slug,
  });

  // Getter to safely get the numeric price (as suggested previously)
  num get numericSellingPrice {
    // 🏆 FIX: Clean the string by removing commas before parsing
    final cleanedPrice = sellingPrice.replaceAll(',', '');
    return num.tryParse(cleanedPrice) ?? 0;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Keep the class property as String, but ensure it's not null
    final rawPrice = json['selling_price'] as String? ?? '0';

    return Product(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      productName: json['product_name'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? '',
      subCategoryId: json['sub_category_id'] is int
          ? json['sub_category_id']
          : int.tryParse(json['sub_category_id'].toString()) ?? 0,
      imageUrl: json['image_url'] as String? ?? '',

      // Pass the raw string to the class property
      sellingPrice: rawPrice,

      slug: json['slug'] as String? ?? '',
    );
  }
}