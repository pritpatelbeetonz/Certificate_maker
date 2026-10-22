import 'dart:async';
import 'dart:convert';
import 'package:certificate_maker/View/SavedProjectsPage.dart';
import 'package:certificate_maker/View/SettingsPage.dart';
import 'package:certificate_maker/View/browseTemplets.dart';
import 'package:certificate_maker/View/editCertificatePage.dart';
import 'package:certificate_maker/View/PremiumCreditView.dart';
import 'package:certificate_maker/for_ads/ads/ads_variable.dart';
import 'package:certificate_maker/for_ads/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../Services/fetch_data_from_server_service.dart';
import '../for_ads/utils/shared_prefrence_service.dart';
import 'widgets/smart_certificate_thumbnail.dart';

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

  // Banner Carousel State
  List<dynamic> _bannerCertificates = [];
  late final PageController _bannerPageController;
  Timer? _bannerTimer;
  static const int _bannerInitialPage = 1000;

  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController(
      viewportFraction: 0.72,
      initialPage: _bannerInitialPage,
    );
    _projectsBox = Hive.box('saved_projects');
    _loadTemplates();
    _loadBannerCertificates();
    if (SharedPrefService.getIsFirstTime()) {
      SharedPrefService.setIsFirstTime(false);
      showLog("Entered First page");
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerResumeTimer?.cancel();
    _bannerPageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Timer? _bannerResumeTimer;
  DateTime? _lastTickTime;

  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    _bannerResumeTimer?.cancel();
    if (_bannerCertificates.isEmpty) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_bannerPageController.hasClients) {
        final nextPage = (_bannerPageController.page?.round() ?? _bannerInitialPage) + 1;
        _bannerPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _onUserInteractionStart() {
    _bannerTimer?.cancel();
    _bannerResumeTimer?.cancel();
  }

  void _onUserInteractionEnd() {
    _bannerResumeTimer?.cancel();
    // Give user 5 seconds of calm idle time after swiping before auto-scroll resumes
    _bannerResumeTimer = Timer(const Duration(seconds: 5), () {
      _startBannerAutoScroll();
    });
  }

  Future<void> _loadBannerCertificates() async {
    try {
      print("[BannerCarousel] 📂 Loading banner certificates...");
      final String response = await FetchDataFromServerServices.loadBannerCertificatesJson();
      final data = json.decode(response);
      final List<dynamic> certs = data['banner_certificates'] ?? [];
      print("[BannerCarousel] 📂 Loaded ${certs.length} banner certificates");
      if (mounted) {
        setState(() {
          _bannerCertificates = certs;
        });
        _startBannerAutoScroll();
      }
    } catch (e) {
      print("[BannerCarousel] ❌ Error loading banner certificates: $e");
    }
  }

  Future<void> _loadTemplates() async {
    try {
      final String response = await FetchDataFromServerServices.loadIndexJson();
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
                        final String rawThumb = item['thumbnail'] ?? '';
                        final String rawLayout = item['layoutPath'] ?? 'assets/cert_jsons/certificate_01.json';
                        final String layoutPath = (rawLayout.isNotEmpty && !rawLayout.startsWith('assets/') && !rawLayout.startsWith('http'))
                            ? 'assets/$rawLayout'
                            : rawLayout;
                        return Padding(
                          padding: EdgeInsets.only(right: 12.w),
                          child: GestureDetector(
                            onTap: () {
                              if (item['premium'] == true && AdsVariable.isPurchase != true) {
                                Get.to(() => PremiumCreditView(
                                      onboarding: false,
                                      onDone: () => Get.back(),
                                    ));
                              } else {
                                AdsVariable.onShowAds(context, onComplete: () {
                                  Get.to(() => EditCertificatePage(
                                        layoutPath: layoutPath,
                                      ));
                                });
                              }
                            },
                            child: Container(
                              width: 175.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: const Color( 0xFFdfe0e1),width: 4),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: SmartCertificateThumbnail(
                                      thumbnailPath: rawThumb,
                                      fit: BoxFit.cover,
                                      width: 175.w,
                                      height: 120.h,
                                    ),
                                  ),
                                  if (item['premium'] == true && AdsVariable.isPurchase != true)
                                    Positioned(
                                      top: 6.h,
                                      right: 6.w,
                                      child: Container(
                                        padding: EdgeInsets.all(4.r),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Image.asset(
                                          'assets/Home Screen/premiumCrown.png',
                                          width: 18.r,
                                          height: 18.r,
                                        ),
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
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Header (Title & Settings Icon)
            SliverToBoxAdapter(
              child: Padding(
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
            ),

            // 2. Auto-animating Focus-Enlarge Certificate Carousel Banner
            if (_bannerCertificates.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220.h,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      // Only react to REAL user drag, not programmatic animateToPage
                      if (notification is ScrollStartNotification && notification.dragDetails != null) {
                        _onUserInteractionStart();
                      } else if (notification is ScrollEndNotification && notification.dragDetails != null) {
                        _onUserInteractionEnd();
                      }
                      return false;
                    },
                    child: Listener(
                      onPointerDown: (_) => _onUserInteractionStart(),
                      onPointerUp: (_) => _onUserInteractionEnd(),
                      onPointerCancel: (_) => _onUserInteractionEnd(),
                      child: PageView.builder(
                        controller: _bannerPageController,
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
                        itemBuilder: (context, index) {
                          final itemIndex = index % _bannerCertificates.length;
                          final item = _bannerCertificates[itemIndex];
                          final String rawThumb = item['thumbnail'] ?? '';
                          final String rawLayout = item['layoutPath'] ?? 'assets/cert_jsons/certificate_01.json';
                          final String layoutPath = (rawLayout.isNotEmpty && !rawLayout.startsWith('assets/') && !rawLayout.startsWith('http'))
                              ? 'assets/$rawLayout'
                              : rawLayout;

                          return AnimatedBuilder(
                            animation: _bannerPageController,
                            builder: (context, child) {
                              double page = _bannerInitialPage.toDouble();
                              if (_bannerPageController.position.hasContentDimensions &&
                                  _bannerPageController.page != null) {
                                page = _bannerPageController.page!;
                              }
                              final double pageOffset = (page - index).abs();
                              final double scale = (1.0 - (pageOffset * 0.15)).clamp(0.85, 1.0);
                              final double opacity = (1.0 - (pageOffset * 0.2)).clamp(0.75, 1.0);

                              return Transform.scale(
                                scale: scale,
                                alignment: Alignment.center,
                                child: Opacity(
                                  opacity: opacity,
                                  child: Container(
                                    margin: EdgeInsets.only(top: 6.h, bottom: 18.h, left: 4.w, right: 4.w),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0F172A).withValues(alpha: 0.14),
                                          blurRadius: 16.r,
                                          spreadRadius: 1,
                                          offset: Offset(0, 8.h),
                                        ),
                                      ],
                                    ),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: GestureDetector(
                              onTap: () {
                                if (item['premium'] == true && AdsVariable.isPurchase != true) {
                                  Get.to(() => PremiumCreditView(
                                        onboarding: false,
                                        onDone: () => Get.back(),
                                      ));
                                } else {
                                  AdsVariable.onShowAds(context, onComplete: () {
                                    Get.to(() => EditCertificatePage(
                                          layoutPath: layoutPath,
                                        ));
                                  });
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16.r),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    SmartCertificateThumbnail(
                                      thumbnailPath: rawThumb,
                                      fit: BoxFit.cover,
                                      width: 280.w,
                                      height: 220.h,
                                    ),
                                    if (item['premium'] == true && AdsVariable.isPurchase != true)
                                      Positioned(
                                        top: 10.h,
                                        right: 10.w,
                                        child: Container(
                                          padding: EdgeInsets.all(5.r),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.55),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Image.asset(
                                            'assets/Home Screen/premiumCrown.png',
                                            width: 20.r,
                                            height: 20.r,
                                          ),
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
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: SizedBox(height: 12.h),
            ),

            // 3. Category Horizontal Lists (Lazy-rendered only when scrolled into view)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = _dynamicCategories[index];
                  return _buildCategorySection(category, category);
                },
                childCount: _dynamicCategories.length,
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: 24.h),
            ),
          ],
        ),
      ),
    );
  }
}
