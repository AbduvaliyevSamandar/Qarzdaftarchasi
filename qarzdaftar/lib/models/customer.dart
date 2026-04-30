class Customer {
  final String id;
  final String shopOwnerId;
  final String name;
  final String? phone;
  final String? address;
  final String? note;
  final String? photoPath;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.shopOwnerId,
    required this.name,
    this.phone,
    this.address,
    this.note,
    this.photoPath,
    required this.createdAt,
  });

  Customer copyWith({
    String? name,
    String? phone,
    String? address,
    String? note,
    String? photoPath,
    bool removePhoto = false,
  }) {
    return Customer(
      id: id,
      shopOwnerId: shopOwnerId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      note: note ?? this.note,
      photoPath: removePhoto ? null : (photoPath ?? this.photoPath),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'shop_owner_id': shopOwnerId,
        'name': name,
        'phone': phone,
        'address': address,
        'note': note,
        'photo_path': photoPath,
        'created_at': createdAt.toIso8601String(),
      };

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
        id: m['id'] as String,
        shopOwnerId: m['shop_owner_id'] as String,
        name: m['name'] as String,
        phone: m['phone'] as String?,
        address: m['address'] as String?,
        note: m['note'] as String?,
        photoPath: m['photo_path'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
