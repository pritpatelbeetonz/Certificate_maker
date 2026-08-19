import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'editCertificatePage.dart';

class SavedProjectsPage extends StatefulWidget {
  const SavedProjectsPage({super.key});

  @override
  State<SavedProjectsPage> createState() => _SavedProjectsPageState();
}

class _SavedProjectsPageState extends State<SavedProjectsPage> {
  late Box _projectsBox;

  @override
  void initState() {
    super.initState();
    _projectsBox = Hive.box('saved_projects');
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

      String timeStr =
          '${dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour)}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';

      if (difference.inDays == 0 && dt.day == now.day) {
        return 'Today, $timeStr';
      } else if (difference.inDays == 1 ||
          (difference.inDays == 0 && dt.day == now.day - 1)) {
        return 'Yesterday, $timeStr';
      } else {
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return '${months[dt.month - 1]} ${dt.day}, $timeStr';
      }
    } catch (e) {
      return '';
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          backgroundColor: Colors.white,
          title: Text(
            'Delete Project?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: const Color(0xFF0F172A),
            ),
          ),
          content: Text(
            'Are you sure you want to delete “$name”?',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF64748B),
            ),
          ),
          actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          actions: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: const Color(0xFF1F2937),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await _projectsBox.delete(name);
                      setState(() {});
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get and sort projects by updatedAt descending
    final List<MapEntry<dynamic, dynamic>> projects = _projectsBox.keys.map((
      key,
    ) {
      final data = _projectsBox.get(key) as Map<dynamic, dynamic>;
      return MapEntry(key, data);
    }).toList();

    projects.sort((a, b) {
      final aTime = a.value['updatedAt'] as String? ?? '';
      final bTime = b.value['updatedAt'] as String? ?? '';
      return bTime.compareTo(aTime);
    });

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
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.06),
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
                    'Saved Projects',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2x2 Grid or empty state
              Expanded(
                child: projects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/Home Screen/no_project.png',
                              height: 400.h,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      )
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.97,
                            ),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          final String name = project.key as String;
                          final data = project.value;
                          final String? savedThumbnail =
                              data['thumbnailPath'] as String?;
                          final String fallbackThumbnailPath =
                              _getThumbnailForProject(data);
                          final String timeString = _formatDateTime(
                            data['updatedAt'] as String?,
                          );

                          return GestureDetector(
                            onTap: () {
                              Get.to(
                                () => EditCertificatePage(
                                  layoutPath:
                                      data['layoutPath'] ??
                                      'assets/cert_jsons/certificate_01.json',
                                  savedProjectName: name,
                                ),
                              );
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
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      8.w,
                                      8.h,
                                      8.w,
                                      0,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.r),
                                      child: AspectRatio(
                                        aspectRatio: 1.4,
                                        child:
                                            (savedThumbnail != null &&
                                                File(
                                                  savedThumbnail,
                                                ).existsSync())
                                            ? Image.file(
                                                File(savedThumbnail),
                                                fit: BoxFit.contain,
                                              )
                                            : Image.asset(
                                                fallbackThumbnailPath,
                                                fit: BoxFit.contain,
                                              ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 8.h,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(
                                                    0xFF0F172A,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 2.h),
                                              Text(
                                                timeString,
                                                style: TextStyle(
                                                  fontSize: 11.sp,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _showDeleteConfirmationDialog(
                                            context,
                                            name,
                                          ),
                                          child: Image.asset(
                                            "assets/Text edit/delete.png",
                                            width: 20.w,
                                            height: 20.w,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
