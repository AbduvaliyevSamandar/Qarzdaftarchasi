class ShopProfile {
  final String name;
  final String? ownerPhone;
  final String? ownerName;
  final String? address;

  const ShopProfile({
    required this.name,
    this.ownerPhone,
    this.ownerName,
    this.address,
  });

  ShopProfile copyWith({
    String? name,
    String? ownerPhone,
    String? ownerName,
    String? address,
  }) {
    return ShopProfile(
      name: name ?? this.name,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerName: ownerName ?? this.ownerName,
      address: address ?? this.address,
    );
  }

  bool get isComplete => name.trim().isNotEmpty;
}
