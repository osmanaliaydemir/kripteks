class Strategy {
  final String id;
  final String name;
  final String description;
  final String category;

  Strategy({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
  });

  factory Strategy.fromJson(Map<String, dynamic> json) {
    return Strategy(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
    );
  }
}
