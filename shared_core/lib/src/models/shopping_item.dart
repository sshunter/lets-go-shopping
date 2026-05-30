import 'package:uuid/uuid.dart';

class ShoppingItem {
  final String id;
  final String name;
  final bool isCompleted;
  final DateTime createdAt;

  ShoppingItem({
    required this.id,
    required this.name,
    this.isCompleted = false,
    required this.createdAt,
  });

  ShoppingItem copyWith({
    String? id,
    String? name,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'],
      name: json['name'],
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          isCompleted == other.isCompleted &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ isCompleted.hashCode ^ createdAt.hashCode;
}
