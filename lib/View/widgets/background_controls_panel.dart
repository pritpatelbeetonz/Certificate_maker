import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BackgroundsControlPanel extends StatelessWidget {
  final List<dynamic> backgrounds;
  final String? currentBackgroundPath;
  final Function(String path) onBackgroundSelected;
  final VoidCallback onDismiss;

  const BackgroundsControlPanel({
    super.key,
    required this.backgrounds,
    required this.currentBackgroundPath,
    required this.onBackgroundSelected,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title and Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Change Background',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Grid list of background frames
          SizedBox(
            height: 180.h,
            child: backgrounds.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      mainAxisSpacing: 12.w,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: backgrounds.length,
                    itemBuilder: (context, index) {
                      final bg = backgrounds[index];
                      final String name = bg['name'] ?? '';
                      final String path = bg['path'] ?? '';
                      final bool isSelected = currentBackgroundPath == path;

                      return GestureDetector(
                        onTap: () => onBackgroundSelected(path),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0052D4)
                                  : const Color(0xFFE2E8F0),
                              width: isSelected ? 3 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF0052D4).withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(6.r),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: Image.asset(
                                      path,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: const Color(0xFFF1F5F9),
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
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFF0F5FF)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(9.r),
                                  ),
                                ),
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? const Color(0xFF0052D4)
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
