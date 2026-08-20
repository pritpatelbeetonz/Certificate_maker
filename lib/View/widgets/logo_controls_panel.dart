import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LogoControlsPanel extends StatelessWidget {
  final bool hasLogo;
  final String currentLogoName;
  final String currentLogoDimensions;
  final VoidCallback onAddNewLogo;
  final VoidCallback onReplaceSelectedLogo;
  final VoidCallback onDismiss;
  final VoidCallback? onCopy;
  final double? currentOpacity;
  final ValueChanged<double>? onOpacityChanged;
  final VoidCallback? onOpacityChangeEnd;

  const LogoControlsPanel({
    super.key,
    required this.hasLogo,
    required this.currentLogoName,
    required this.currentLogoDimensions,
    required this.onAddNewLogo,
    required this.onReplaceSelectedLogo,
    required this.onDismiss,
    this.onCopy,
    this.currentOpacity,
    this.onOpacityChanged,
    this.onOpacityChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Logo',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191C1D),
                      ),
                    ),
                    if (hasLogo)
                      GestureDetector(
                        onTap: onAddNewLogo,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                      color: const Color(0xFF4200AD),
                                      width: 1.w,
                                    ),
                                    borderRadius: BorderRadius.circular(50.r)
                                ),

                                child: const Icon(
                                  Icons.add,
                                  color: Color(0xFF7C3AED),
                                  size: 12,
                                ),
                              ),                              const SizedBox(width: 4),
                              const Text(
                                'Add Logo',
                                style: TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 15.h),
                if (hasLogo) ...[
                  Row(
                    children: [
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentLogoName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentLogoDimensions,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: onReplaceSelectedLogo,
                        icon: Image.asset('assets/Logo edit/Frame.png',width: 18.w,height: 18.w,),
                        label: const Text('Replace Logo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4200AD),
                          foregroundColor: const Color(0xFFFFFFFF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                            value: currentOpacity ?? 1.0,
                            min: 0.0,
                            max: 1.0,
                            onChanged: onOpacityChanged,
                            onChangeEnd: (_) => onOpacityChangeEnd?.call(),
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
                          '${((currentOpacity ?? 1.0) * 100).round()}%',
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
                        onPressed: onCopy,
                        tooltip: 'Duplicate',
                      ),
                    ],
                  ),
                ] else ...[
                  const Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          'No Logo added',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add your organization logo to personalize this certificate.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: onAddNewLogo,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Logo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF3E8FF),
                        foregroundColor: const Color(0xFF7C3AED),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
