import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../rendering_engine/models/scene_node.dart';

class TextControlsPanel extends StatelessWidget {
  final TextNode? selectedNode;
  final TextEditingController textController;
  final FocusNode textFocusNode;
  final List<Map<String, dynamic>> colorPalette;
  final List<String> fontFamilies;
  final VoidCallback onAddNewTextNode;
  final VoidCallback onSaveTextEditingState;
  final Function({
    String? fontFamily,
    double? fontSize,
    String? color,
    String? fontWeight,
    String? fontStyle,
    String? decoration,
    String? align,
    bool? saveHistory,
  })
  onUpdateProperty;
  final Function(String hex, Color color) onColorSelected;
  final VoidCallback onDismiss;

  const TextControlsPanel({
    super.key,
    required this.selectedNode,
    required this.textController,
    required this.textFocusNode,
    required this.colorPalette,
    required this.fontFamilies,
    required this.onAddNewTextNode,
    required this.onSaveTextEditingState,
    required this.onUpdateProperty,
    required this.onColorSelected,
    required this.onDismiss,
  });

  void _showColorPickerDialog(BuildContext context) {
    Color selectedColor = const Color(0xFF2563EB);
    if (selectedNode != null) {
      try {
        String hex = selectedNode!.color.replaceAll('#', '');
        if (hex.length == 6) hex = 'FF$hex';
        selectedColor = Color(int.parse(hex, radix: 16));
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Choose Color',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                selectedColor = color;
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final hex =
                    '#FF${selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                onColorSelected(hex, selectedColor);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B21B6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = selectedNode != null;
    final double maxHeight = MediaQuery.of(context).size.height * 0.40;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const SizedBox(height: 2),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Edit Text',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          GestureDetector(
                            onTap: onAddNewTextNode,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      border: Border.all(
                                        color: Color(0xFF4200AD),
                                        width: 1.w,
                                      ),
                                      borderRadius: BorderRadius.circular(50.r)
                                    ),

                                    child: Icon(
                                      Icons.add,
                                      color: Color(0xFF7C3AED),
                                      size: 12,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'New Text',
                                    style: TextStyle(
                                      color: Color(0xFF7C3AED),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: colorPalette.length + 1,
                          itemBuilder: (context, index) {
                            if (index == colorPalette.length) {
                              return GestureDetector(
                                onTap: hasSelection
                                    ? () => _showColorPickerDialog(context)
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              );
                            }

                            final palItem = colorPalette[index];
                            final Color col = palItem['color'];
                            final String hex = palItem['hex'];

                            final bool isSelected =
                                hasSelection &&
                                selectedNode!.color.toUpperCase() ==
                                    hex.toUpperCase();

                            return GestureDetector(
                              onTap: hasSelection
                                  ? () {
                                      onUpdateProperty(color: hex);
                                    }
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: col,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF8B5CF6)
                                          : const Color(0xFFE2E8F0),
                                      width: isSelected ? 3.0 : 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 178.w,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value:
                                    hasSelection &&
                                        fontFamilies.contains(
                                          selectedNode!.fontFamily,
                                        )
                                    ? selectedNode!.fontFamily
                                    : 'System',style: TextStyle(color: Color(0xFF000000).withValues(alpha: 0.6)),
                                icon: Image.asset("assets/Text edit/Dropdown.png",width: 24.w,height: 24.w,),
                                isExpanded: true,
                                onChanged: hasSelection
                                    ? (String? newFont) {
                                        if (newFont != null) {
                                          onUpdateProperty(fontFamily: newFont);
                                        }
                                      }
                                    : null,
                                items: fontFamilies.map<DropdownMenuItem<String>>((
                                  String value,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                        fontFamily: value == 'System'
                                            ? null
                                            : value,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildAlignToggleButton(
                              image: "assets/Text edit/right.png",
                              isActive:
                              hasSelection &&
                                  (selectedNode!.align == 'left' ||
                                      selectedNode!.align == ''),
                              onTap: hasSelection
                                  ? () => onUpdateProperty(align: 'left')
                                  : null,
                            ),
                          ),
                         const SizedBox(width: 8),
                          Expanded(
                            child: _buildAlignToggleButton(
                              isActive:
                              hasSelection &&
                                  selectedNode!.align == 'center',
                              onTap: hasSelection
                                  ? () => onUpdateProperty(align: 'center')
                                  : null, image: 'assets/Text edit/center.png',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildAlignToggleButton(
                              isActive:
                              hasSelection &&
                                  selectedNode!.align == 'right',
                              onTap: hasSelection
                                  ? () => onUpdateProperty(align: 'right')
                                  : null, image: 'assets/Text edit/right.png',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildAlignToggleButton(
                              isActive:
                              hasSelection &&
                                  selectedNode!.align == 'justify',
                              onTap: hasSelection
                                  ? () => onUpdateProperty(align: 'justify')
                                  : null, image: 'assets/Text edit/justify.png',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.w,),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding:EdgeInsets.symmetric(horizontal: 12.w, vertical: 0.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F1FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    'A-',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: const Color(0xFF0052D4),
                                        inactiveTrackColor: const Color(0x1A000000),
                                        thumbColor: const Color(0xFF0052D4),
                                        overlayColor: const Color(0xFF0052D4).withOpacity(0.12),
                                        trackHeight: 3,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6,
                                          elevation: 1,
                                        ),
                                      ),
                                      child: Slider(
                                        value: hasSelection
                                            ? selectedNode!.fontSize.clamp(6.0, 100.0)
                                            : 14.0,
                                        min: 6.0,
                                        max: 100.0,
                                        onChanged: hasSelection
                                            ? (double val) {
                                                onUpdateProperty(
                                                  fontSize: val,
                                                  saveHistory: false,
                                                );
                                              }
                                            : null,
                                        onChangeEnd: (_) => onSaveTextEditingState(),
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'A+',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      hasSelection
                                          ? selectedNode!.fontSize.round().toString()
                                          : '14',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Row(
                            children: [
                              _buildStyleToggleButton(
                                iconText: 'B',
                                isActive:
                                    hasSelection &&
                                    selectedNode!.fontWeight == 'bold',
                                onTap: hasSelection
                                    ? () {
                                        final newWeight =
                                            selectedNode!.fontWeight == 'bold'
                                            ? 'normal'
                                            : 'bold';
                                        onUpdateProperty(fontWeight: newWeight);
                                      }
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              _buildStyleToggleButton(
                                iconText: 'I',
                                isActive:
                                    hasSelection &&
                                    selectedNode!.fontStyle == 'italic',
                                isItalic: true,
                                onTap: hasSelection
                                    ? () {
                                        final newStyle =
                                            selectedNode!.fontStyle == 'italic'
                                            ? 'normal'
                                            : 'italic';
                                        onUpdateProperty(fontStyle: newStyle);
                                      }
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              _buildStyleToggleButton(
                                iconText: 'U',
                                isActive:
                                    hasSelection &&
                                    selectedNode!.decoration == 'underline',
                                isUnderline: true,
                                onTap: hasSelection
                                    ? () {
                                        final newDeco =
                                            selectedNode!.decoration ==
                                                'underline'
                                            ? 'none'
                                            : 'underline';
                                        onUpdateProperty(decoration: newDeco);
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleToggleButton({
    required String iconText,
    required bool isActive,
    bool isItalic = false,
    bool isUnderline = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          iconText,
          style: TextStyle(
            fontWeight: iconText == 'B' ? FontWeight.bold : FontWeight.w600,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: isUnderline
                ? TextDecoration.underline
                : TextDecoration.none,
            // color: isActive ? const Color(0xFF2563EB) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildAlignToggleButton({
    required String image,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Image.asset(image,width: 20.w,height: 20.w,),
      ),
    );
  }
}
