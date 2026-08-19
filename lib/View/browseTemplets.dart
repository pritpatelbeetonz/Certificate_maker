import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'editCertificatePage.dart';

class Browsetemplets extends StatefulWidget {
  const Browsetemplets({super.key});

  @override
  State<Browsetemplets> createState() => _BrowsetempletsState();
}

class _BrowsetempletsState extends State<Browsetemplets> {
  List<dynamic> _allTemplates = [];
  List<dynamic> _filteredTemplates = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All Template';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All Template', 'icon': Icons.grid_view_outlined},
    {'name': 'Achievement', 'icon': Icons.emoji_events_outlined},
    {'name': 'Participation', 'icon': Icons.person_outline},
    {'name': 'Appreciation', 'icon': Icons.favorite_border_outlined},
    {'name': 'Completion', 'icon': Icons.verified_user_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    try {
      final String response = await DefaultAssetBundle.of(context).loadString('assets/index.json');
      final data = json.decode(response);
      setState(() {
        _allTemplates = data['layouts'] ?? [];
        _isLoading = false;
      });
      _filterTemplates();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error loading templates: $e");
    }
  }

  void _filterTemplates() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTemplates = _allTemplates.where((temp) {
        final String name = temp['name'] ?? '';
        final String category = temp['category'] ?? '';

        final matchesSearch = name.toLowerCase().contains(query) || category.toLowerCase().contains(query);
        final matchesCategory = _selectedCategory == 'All Template' || category.toLowerCase() == _selectedCategory.toLowerCase();

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterTemplates();
  }

  void _onSearchChanged() {
    _filterTemplates();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Custom top bar with back arrow and title
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 35.w,
                      height: 35.w,
                      alignment: Alignment.center,
                      //padding: const EdgeInsets.all(10),
                      decoration:  BoxDecoration(
                        color: Color(0xFF000000).withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF1E293B),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Browse Templates',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Search input bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search templates...', // matching search templates hint
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 24),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                ),
              ),
               const SizedBox(height: 16),

              // Categories Selector
              SizedBox(
                height: 40.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final String catName = cat['name']!;
                    final IconData catIcon = cat['icon']!;
                    final bool isSelected = _selectedCategory == catName;

                    return Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: GestureDetector(
                        onTap: () => _onCategorySelected(catName),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFF1EDFF) : Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF6F5BFF) : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                catIcon,
                                size: 18.w,
                                color: isSelected ? const Color(0xFF6F5BFF) : const Color(0xFF64748B),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                catName,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? const Color(0xFF6F5BFF) : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
              
              // Templates listing grid
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredTemplates.isEmpty
                        ? const Center(
                            child: Text(
                              'No templates found',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          )
                        : GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.97,
                            ),
                            itemCount: _filteredTemplates.length,
                            itemBuilder: (context, index) {
                              final item = _filteredTemplates[index];
                              final String displayName = item['name'] ?? '';
                              final String thumbnail = item['thumbnail'] ?? '';
                              final String displaySubtitle = item['category'] ?? '';

                              return GestureDetector(
                                onTap: () {
                                  Get.to(() => EditCertificatePage(
                                        layoutPath: item['layoutPath'] ?? 'assets/cert_jsons/certificate_01.json',
                                      ));
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Image Thumbnail
                                      Padding(
                                        padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10.r),
                                          child: AspectRatio(
                                            aspectRatio: 1.4,
                                            child: Image.asset(
                                              thumbnail,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: const Color(0xFFE2E8F0),
                                                  child: const Icon(
                                                    Icons.image_not_supported_outlined,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Info footer
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                          vertical: 8.h,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    displayName,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      fontWeight: FontWeight.bold,
                                                      color: const Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  SizedBox(height: 2.h),
                                                  Text(
                                                    displaySubtitle,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 11.sp,
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            GestureDetector(
                                              onTap: () {
                                                // Actions for templates
                                              },
                                              child: Icon(
                                                Icons.more_vert,
                                                size: 20.w,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ));
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}