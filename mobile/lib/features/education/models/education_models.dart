import 'package:flutter/material.dart';

enum EducationTopicCategory { indicators, strategies, fundamentals }

class EducationTopic {
  final String id;
  final String title;
  final String description;
  final String content;
  final EducationTopicCategory category;
  final IconData icon;
  final String? videoUrl;
  final String? imageUrl;

  EducationTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.category,
    required this.icon,
    this.videoUrl,
    this.imageUrl,
  });
}

class AcademyCategory {
  final EducationTopicCategory type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  AcademyCategory({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
