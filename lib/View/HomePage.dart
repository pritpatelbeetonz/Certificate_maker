import 'dart:io';
import 'package:certificate_maker/View/browseTemplets.dart';
import 'package:certificate_maker/View/editCertificatePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
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
                    GestureDetector(
                      onTap: () {
                        // Settings Action placeholder
                      },
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F3F5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.settings_outlined,
                          color: const Color(0xFF1E293B),
                          size: 22.w,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Banner
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: SizedBox(
                  width: double.infinity,
                  height: 188.h,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            "assets/Home Screen/banner bg.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          left: 20.w,
                          bottom: 20.h,
                          child: GestureDetector(
                            onTap: () {
                              Get.to(() => const Browsetemplets());
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Browse Template",
                                    style: TextStyle(
                                      color: const Color(0xFF6F5BFF),
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Icon(
                                    Icons.arrow_forward_outlined,
                                    color: const Color(0xFF6F5BFF),
                                    size: 16.w,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // 3. Section Title: Recent Certificates & View All
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recent Certificates",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(() => const Browsetemplets());
                      },
                      child: Text(
                        "View all",
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF6F5BFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // 4. Certificates Grid or Empty State
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: projects.isEmpty
                    ? Center(
                        child: Image.asset('assets/Home Screen/no_project.png',height: 319.38385009765625.h,width: 246.w,),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          childAspectRatio: 0.97,
                        ),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          final String name = project.key as String;
                          final data = project.value;
                          final String? savedThumbnail = data['thumbnailPath'] as String?;
                          final String fallbackThumbnailPath = _getThumbnailForProject(data);
                          final String timeString = _formatDateTime(data['updatedAt'] as String?);

                          return GestureDetector(
                            onTap: () {
                              Get.to(() => EditCertificatePage(
                                    layoutPath: data['layoutPath'] ?? 'assets/cert_jsons/certificate_01.json',
                                    savedProjectName: name,
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
                              child:Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Certificate Thumbnail
                                Padding(
                                  padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.r),
                                    child: AspectRatio(
                                      aspectRatio: 1.4,
                                      child: (savedThumbnail != null &&
                                          File(savedThumbnail).existsSync())
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

                                // Certificate Title & Date & Actions Menu
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
                                          children: [
                                            Text(
                                              name,
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
                                        onTap: () => _showProjectOptions(context, name),
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
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
