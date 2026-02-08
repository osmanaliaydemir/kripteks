import 'package:flutter/material.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/education/models/education_models.dart';
import 'package:mobile/features/education/data/academy_data.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class AcademyScreen extends StatefulWidget {
  const AcademyScreen({super.key});

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State<AcademyScreen> {
  EducationTopicCategory? _selectedCategory;
  String? _selectedSubCategory;

  @override
  Widget build(BuildContext context) {
    var filteredTopics = _selectedCategory == null
        ? AcademyData.topics
        : AcademyData.topics
              .where((t) => t.category == _selectedCategory)
              .toList();

    if (_selectedSubCategory != null) {
      filteredTopics = filteredTopics
          .where((t) => t.subCategory == _selectedSubCategory)
          .toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Kripto Akademi'),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ne Öğrenmek İstersiniz?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Piyasa okuryazarlığınızı artırarak daha bilinçli işlemler yapın.',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  _buildCategoryList(),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategory == null
                            ? 'Tüm Konular'
                            : AcademyData.categories
                                  .firstWhere(
                                    (c) => c.type == _selectedCategory,
                                  )
                                  .title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedCategory != null)
                        TextButton(
                          onPressed: () => setState(() {
                            _selectedCategory = null;
                            _selectedSubCategory = null;
                          }),
                          child: const Text('Temizle'),
                        ),
                    ],
                  ),
                  _buildSubCategoryList(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final topic = filteredTopics[index];
                return _buildTopicCard(context, topic, index);
              }, childCount: filteredTopics.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: AcademyData.categories.map((cat) {
          final isSelected = _selectedCategory == cat.type;
          return Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 4),
            child: InkWell(
              onTap: () => setState(() {
                if (_selectedCategory == cat.type) {
                  _selectedCategory = null;
                  _selectedSubCategory = null;
                } else {
                  _selectedCategory = cat.type;
                  _selectedSubCategory = null;
                }
              }),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: 300.ms,
                width: 150,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cat.color.withValues(alpha: 0.15)
                      : AppColors.surface.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? cat.color
                        : Colors.white.withValues(alpha: 0.05),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: cat.color.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(cat.icon, color: cat.color, size: 24),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      cat.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.2, end: 0);
        }).toList(),
      ),
    );
  }

  Widget _buildTopicCard(
    BuildContext context,
    EducationTopic topic,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface.withValues(alpha: 0.6),
            AppColors.surface.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () => context.push('/academy/topic', extra: topic),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(topic.icon, color: AppColors.primary, size: 24),
          ),
          title: Text(
            topic.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  topic.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      (AcademyData.categories
                              .firstWhere((c) => c.type == topic.category)
                              .color)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        (AcademyData.categories
                                .firstWhere((c) => c.type == topic.category)
                                .color)
                            .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  topic.subCategory ??
                      AcademyData.categories
                          .firstWhere((c) => c.type == topic.category)
                          .title,
                  style: TextStyle(
                    color: AcademyData.categories
                        .firstWhere((c) => c.type == topic.category)
                        .color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right,
              color: Colors.white38,
              size: 20,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSubCategoryList() {
    if (_selectedCategory == null) return const SizedBox.shrink();

    final subCategories = AcademyData.topics
        .where((t) => t.category == _selectedCategory)
        .map((t) => t.subCategory)
        .where((s) => s != null)
        .cast<String>()
        .toSet()
        .toList();

    if (subCategories.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildSubFilterChip(
              title: 'Tümü',
              isSelected: _selectedSubCategory == null,
              onTap: () => setState(() => _selectedSubCategory = null),
            ),
            ...subCategories.map((sub) {
              return _buildSubFilterChip(
                title: sub,
                isSelected: _selectedSubCategory == sub,
                onTap: () => setState(() => _selectedSubCategory = sub),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSubFilterChip({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.white60,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
