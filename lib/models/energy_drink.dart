class EnergyDrink {
  final int? id;
  final String name;
  final String brand;
  final String? flavour;
  final int caffeineMg;
  final int volume;

  const EnergyDrink({
    this.id,
    required this.name,
    required this.brand,
    this.flavour,
    required this.caffeineMg,
    required this.volume,
  });

  factory EnergyDrink.fromJson(Map<String, dynamic> json) {
    return EnergyDrink(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      flavour: json['flavor'] as String?,
      caffeineMg: (json['caffeine_mg'] as num?)?.toInt() ?? 80,
      volume: (json['volume_ml'] as num?)?.toInt() ?? 250,
    );
  }

  Map<String, dynamic> toJson() {
    final trimmedFlavor = flavour?.trim();
    return {
      'name': name.trim(),
      'brand': brand.trim(),
      'flavor': (trimmedFlavor != null && trimmedFlavor.isNotEmpty)
          ? trimmedFlavor
          : null,
      'caffeine_mg': caffeineMg,
      'volume': volume,
    };
  }
}