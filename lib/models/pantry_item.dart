class PantryItem {
  final String name;
  final bool isSelected;
  final DateTime? addedDate;

  PantryItem({
    required this.name,
    this.isSelected = false,
    this.addedDate,
  });

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    return PantryItem(
      name: json['name'] ?? '',
      isSelected: json['isSelected'] ?? false,
      addedDate: json['addedDate'] != null 
          ? DateTime.parse(json['addedDate']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isSelected': isSelected,
      'addedDate': addedDate?.toIso8601String(),
    };
  }

  PantryItem copyWith({
    String? name,
    bool? isSelected,
    DateTime? addedDate,
  }) {
    return PantryItem(
      name: name ?? this.name,
      isSelected: isSelected ?? this.isSelected,
      addedDate: addedDate ?? this.addedDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PantryItem && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
} 