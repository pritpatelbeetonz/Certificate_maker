import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StickersControlsPanel extends StatelessWidget {
  final Function(String assetPath) onStickerSelected;
  final VoidCallback onDismiss;

  const StickersControlsPanel({
    super.key,
    required this.onStickerSelected,
    required this.onDismiss,
  });

  static const List<String> _stickerAssets = [
    'assets/stickers/set-vintage-badges-with-red-ribbons 1.png',
    'assets/stickers/set-vintage-badges-with-red-ribbons 2.png',
    'assets/stickers/set-vintage-badges-with-red-ribbons 3.png',
    'assets/stickers/set-vintage-badges-with-red-ribbons 4.png',
    'assets/stickers/image 131.png',
    'assets/stickers/image 132.png',
    'assets/stickers/image 133.png',
    'assets/stickers/image 134.png',
    'assets/stickers/image 135.png',
    'assets/stickers/image 136.png',
    'assets/stickers/Group.png',
    'assets/stickers/Group-1.png',
    'assets/stickers/Frame 2085663520.png',
    'assets/stickers/image 128.png',
    'assets/stickers/image 129.png',
    'assets/stickers/image 130.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handler / Top Notch Bar
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (details) {
              if (details.delta.dy > 4.0) {
                onDismiss();
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Text
          const Text(
            'Stickers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),

          // Grid View of Stickers
          Flexible(
            child: SizedBox(
              height: 180.h,
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: _stickerAssets.length,
                itemBuilder: (context, index) {
                  final assetPath = _stickerAssets[index];
                  return GestureDetector(
                    onTap: () => onStickerSelected(assetPath),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade100,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
