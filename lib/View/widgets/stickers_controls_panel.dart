import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StickersControlsPanel extends StatefulWidget {
  final List<dynamic>? stickers;
  final Function(String assetPath) onStickerSelected;
  final VoidCallback onDismiss;
  final bool hasSelection;
  final VoidCallback? onCopy;
  final double? currentOpacity;
  final ValueChanged<double>? onOpacityChanged;
  final VoidCallback? onOpacityChangeEnd;

  const StickersControlsPanel({
    super.key,
    this.stickers,
    required this.onStickerSelected,
    required this.onDismiss,
    required this.hasSelection,
    this.onCopy,
    this.currentOpacity,
    this.onOpacityChanged,
    this.onOpacityChangeEnd,
  });

  @override
  State<StickersControlsPanel> createState() => _StickersControlsPanelState();
}

class _StickersControlsPanelState extends State<StickersControlsPanel> {
  String _selectedCategory = 'All';

  static const List<String> _fallbackStickerAssets = [
    'assets/Final_Certificates/stickers/vintage_ribbon_badge_01.png',
    'assets/Final_Certificates/stickers/vintage_ribbon_badge_02.png',
    'assets/Final_Certificates/stickers/vintage_ribbon_badge_03.png',
    'assets/Final_Certificates/stickers/vintage_ribbon_badge_04.png',
    'assets/Final_Certificates/stickers/classic_badge_07.png',
    'assets/Final_Certificates/stickers/classic_badge_08.png',
    'assets/Final_Certificates/stickers/classic_badge_09.png',
    'assets/Final_Certificates/stickers/classic_badge_10.png',
    'assets/Final_Certificates/stickers/classic_badge_11.png',
    'assets/Final_Certificates/stickers/classic_badge_12.png',
    'assets/Final_Certificates/stickers/classic_badge_03.png',
    'assets/Final_Certificates/stickers/classic_badge_02.png',
    'assets/Final_Certificates/stickers/classic_badge_01.png',
    'assets/Final_Certificates/stickers/classic_badge_04.png',
    'assets/Final_Certificates/stickers/classic_badge_05.png',
    'assets/Final_Certificates/stickers/classic_badge_06.png',
  ];

  List<String> get _categories {
    if (widget.stickers == null || widget.stickers!.isEmpty) {
      return ['All'];
    }
    final Set<String> cats = {'All'};
    for (var s in widget.stickers!) {
      if (s is Map && s['category'] != null) {
        cats.add(s['category'].toString());
      }
    }
    return cats.toList();
  }

  List<String> get _filteredPaths {
    if (widget.stickers != null && widget.stickers!.isNotEmpty) {
      return widget.stickers!
          .where((s) {
            if (_selectedCategory == 'All') return true;
            return s is Map && s['category'] == _selectedCategory;
          })
          .map((s) => s is Map ? (s['path'] ?? '').toString() : s.toString())
          .where((p) => p.isNotEmpty)
          .toList();
    }
    return _fallbackStickerAssets;
  }

  @override
  Widget build(BuildContext context) {
    final paths = _filteredPaths;

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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handler / Top Notch Bar
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (details) {
              if (details.delta.dy > 4.0) {
                widget.onDismiss();
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
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
          const SizedBox(height: 12),

          // Header Text & Close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Stickers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              GestureDetector(
                onTap: widget.onDismiss,
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
          const SizedBox(height: 12),

          // Category filter pills
          if (_categories.length > 1)
            Container(
              height: 32.h,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, idx) {
                  final cat = _categories[idx];
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0052D4)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          if (widget.hasSelection) ...[
            Row(
              children: [
                const Text(
                  'Opacity',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF0052D4),
                      inactiveTrackColor: const Color(0x1A000000),
                      thumbColor: const Color(0xFF0052D4),
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                    ),
                    child: Slider(
                      value: widget.currentOpacity ?? 1.0,
                      min: 0.0,
                      max: 1.0,
                      onChanged: widget.onOpacityChanged,
                      onChangeEnd: (_) => widget.onOpacityChangeEnd?.call(),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1FA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${((widget.currentOpacity ?? 1.0) * 100).round()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, color: Color(0xFF7C3AED), size: 20),
                  onPressed: widget.onCopy,
                  tooltip: 'Duplicate',
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Grid View of Stickers
          Flexible(
            child: SizedBox(
              height: 180.h,
              child: paths.isEmpty
                  ? const Center(child: Text('No stickers found'))
                  : GridView.builder(
                      padding: const EdgeInsets.only(bottom: 12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: paths.length,
                      itemBuilder: (context, index) {
                        final assetPath = paths[index];
                        return GestureDetector(
                          onTap: () => widget.onStickerSelected(assetPath),
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
                              (assetPath.isNotEmpty && !assetPath.startsWith('assets/') && !assetPath.startsWith('http'))
                                  ? 'assets/$assetPath'
                                  : assetPath,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 24,
                              ),
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
