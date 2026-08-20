import 'dart:convert';
import 'dart:io';
import 'package:certificate_maker/View/SavedProjectsPage.dart';
import 'package:certificate_maker/View/SettingsPage.dart';
import 'package:certificate_maker/View/browseTemplets.dart';
import 'package:certificate_maker/View/editCertificatePage.dart';
import 'package:certificate_maker/for_ads/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../for_ads/utils/shared_prefrence_service.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late Box _projectsBox;
  List<dynamic> _allTemplates = [];
  List<String> _dynamicCategories = [];
  bool _isLoadingTemplates = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _projectsBox = Hive.box('saved_projects');
    _loadTemplates();
    if (SharedPrefService.getIsFirstTime()) {
      SharedPrefService.setIsFirstTime(false);
      showLog("Entered First page");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    try {
      final String response = await DefaultAssetBundle.of(context).loadString('assets/Certificate/index.json');
      final data = json.decode(response);
      final layouts = data['layouts'] ?? [];
      
      final Set<String> categorySet = {};
      for (final layout in layouts) {
        final String cat = layout['category'] ?? '';
        if (cat.isNotEmpty) {
          categorySet.add(cat);
        }
      }

      setState(() {
        _allTemplates = layouts;
        _dynamicCategories = categorySet.toList();
        _isLoadingTemplates = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTemplates = false;
      });
      debugPrint("Error loading templates: $e");
    }
  }

  Widget _buildCategorySection(String categoryName, String categoryKey) {
    final categoryTemplates = _allTemplates.where((temp) {
      final String cat = temp['category'] ?? '';
      return cat.toLowerCase() == categoryKey.toLowerCase();
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryName,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF191C1D),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Get.to(() => Browsetemplets(initialCategory: categoryName));
                },
                child: Text(
                  "See All",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120.h,
          child: _isLoadingTemplates
              ? const Center(child: CircularProgressIndicator())
              : categoryTemplates.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: categoryTemplates.length,
                      itemBuilder: (context, index) {
                        final item = categoryTemplates[index];
                        final String thumbnail = item['thumbnail'] ?? '';
                        return Padding(
                          padding: EdgeInsets.only(right: 12.w),
                          child: GestureDetector(
                            onTap: () {
                              Get.to(() => EditCertificatePage(
                                    layoutPath: item['layoutPath'] ?? 'assets/cert_jsons/certificate_01.json',
                                  ));
                            },
                            child: Container(
                              width: 175.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: const Color( 0xFFdfe0e1),width: 4),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: Image.asset(
                                  thumbnail,
                                  fit: BoxFit.cover,
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
                        );
                      },
                    ),
        ),
      ],
    );
  }

  String _getThumbnailForProject(Map<dynamic, dynamic> projectData) {
    final document = projectData['document'] as Map<dynamic, dynamic>?;
    final metadata = document?['metadata'] as Map<dynamic, dynamic>?;
    final id = metadata?['id'];
    if (id == 'certificate_01') {
      return 'assets/thumbnails/1 1.png';
    } else if (id == 'certificate_02') {
      return 'assets/thumbnails/2 1.png';
    } else {
      return 'assets/thumbnails/thumbnail_01.png';
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dt);
      
      String timeStr = '${dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour)}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
      
      if (difference.inDays == 0 && dt.day == now.day) {
        return 'Today, $timeStr';
      } else if (difference.inDays == 1 || (difference.inDays == 0 && dt.day == now.day - 1)) {
        return 'Yesterday, $timeStr';
      } else {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[dt.month - 1]} ${dt.day}, $timeStr';
      }
    } catch (e) {
      return '';
    }
  }

  void _showProjectOptions(BuildContext context, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text("Edit Project"),
                onTap: () {
                  Navigator.pop(context);
                  final projectData = _projectsBox.get(name) as Map<dynamic, dynamic>?;
                  if (projectData != null) {
                    Get.to(() => EditCertificatePage(
                      layoutPath: projectData['layoutPath'] ?? 'assets/cert_jsons/certificate_01.json',
                      savedProjectName: name,
                    ));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text("Delete Project", style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _projectsBox.delete(name);
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get and sort projects by updatedAt descending
    final List<MapEntry<dynamic, dynamic>> projects = _projectsBox.keys.map((key) {
      final data = _projectsBox.get(key) as Map<dynamic, dynamic>;
      return MapEntry(key, data);
    }).toList();

    projects.sort((a, b) {
      final aTime = a.value['updatedAt'] as String? ?? '';
      final bTime = b.value['updatedAt'] as String? ?? '';
      return bTime.compareTo(aTime);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFf8f9fa),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Title & Settings Icon)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Certificate App",
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Get.to(() => const SavedProjectsPage());
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EAED),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: const Color(0xFF191C1D),
                                  size: 18.w,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  "Recent",
                                  style: TextStyle(
                                    color: const Color(0xFF191C1D),
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: () {
                            Get.to(() => const SettingsPage());
                          },
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8EAED),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.settings_outlined,
                              color: const Color(0xFF191C1D),
                              size: 20.w,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Banner
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: GestureDetector(
                  onTap: () {
                   // Get.to(() => const Browsetemplets());
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Image.asset(
                      "assets/Home Screen/banner.png",
                      width: double.infinity,
                      //height: 188.h,
                      //fit: BoxFit,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12.h),

              // 3. Category Horizontal Lists
              ..._dynamicCategories.map((category) => _buildCategorySection(category, category)),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
