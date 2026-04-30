class Product {
  final String id;
  final String shopOwnerId;
  final String name;
  final double price;
  final String? unit;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.shopOwnerId,
    required this.name,
    required this.price,
    this.unit,
    required this.createdAt,
  });

  Product copyWith({String? name, double? price, String? unit}) {
    return Product(
      id: id,
      shopOwnerId: shopOwnerId,
      name: name ?? this.name,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'shop_owner_id': shopOwnerId,
        'name': name,
        'price': price,
        'unit': unit,
        'created_at': createdAt.toIso8601String(),
      };

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as String,
        shopOwnerId: m['shop_owner_id'] as String,
        name: m['name'] as String,
        price: (m['price'] as num).toDouble(),
        unit: m['unit'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
