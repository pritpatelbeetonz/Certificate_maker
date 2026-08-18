import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../rendering_engine/models/scene_node.dart';
import 'widgets/realtime_certificate_painter.dart';

class FullScreenViewerPage extends StatefulWidget {
  final SceneDocument document;
  final Map<String, ui.Image> imagePool;
  final Map<String, ui.Picture> picturePool;

  const FullScreenViewerPage({
    super.key,
    required this.document,
    required this.imagePool,
    this.picturePool = const {},
  });

  @override
  State<FullScreenViewerPage> createState() => _FullScreenViewerPageState();
}

class _FullScreenViewerPageState extends State<FullScreenViewerPage> {
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    // Force landscape mode and immersive sticky display
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    // Restore portrait mode and system UI layout bars
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _zoom(double factor) {
    final matrix = _transformationController.value.clone();
    final double currentScale = matrix.getMaxScaleOnAxis();
    final double targetScale = (currentScale * factor).clamp(0.5, 4.0);
    final double scaleChange = targetScale / currentScale;

    final Size size = MediaQuery.of(context).size;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    matrix.translateByVector3(vm.Vector3(centerX, centerY, 0.0));
    matrix.scaleByVector3(vm.Vector3(scaleChange, scaleChange, 1.0));
    matrix.translateByVector3(vm.Vector3(-centerX, -centerY, 0.0));

    setState(() {
      _transformationController.value = matrix;
    });
  }

  void _resetZoom() {
    setState(() {
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double virtualWidth = widget.document.canvas.virtualWidth;
    final double virtualHeight = widget.document.canvas.virtualHeight;
    final double canvasRatio = virtualWidth / virtualHeight;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Stack(
        children: [
          // View-Only Certificate Canvas with Zoom & Pan Gestures
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double targetW = constraints.maxWidth;
                double targetH = targetW / canvasRatio;

                if (targetH > constraints.maxHeight) {
                  targetH = constraints.maxHeight;
                  targetW = targetH * canvasRatio;
                }

                return InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 4.0,
                  boundaryMargin: const EdgeInsets.all(300),
                  child: Container(
                    width: targetW,
                    height: targetH,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      size: Size(targetW, targetH),
                      painter: RealtimeCertificatePainter(
                        document: widget.document,
                        loadedImages: widget.imagePool,
                        picturePool: widget.picturePool,
                        selectedNodeId: null,
                        editingNodeId: null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Floating Action Button to Return to Portrait Edit Mode
          Positioned(
            top: 20,
            right: 20,
            child: SafeArea(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () {
                  Get.back();
                },
                icon: const Icon(Icons.screen_rotation_outlined, size: 20),
                label: const Text(
                  'Back to Portrait',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),

          // Zoom Action Buttons Overlay in Bottom-Right Corner
          Positioned(
            bottom: 20,
            right: 20,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'zoom_in_btn',
                    backgroundColor: Colors.white.withOpacity(0.9),
                    foregroundColor: const Color(0xFF0F172A),
                    onPressed: () => _zoom(1.25),
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_out_btn',
                    backgroundColor: Colors.white.withOpacity(0.9),
                    foregroundColor: const Color(0xFF0F172A),
                    onPressed: () => _zoom(0.8),
                    child: const Icon(Icons.remove),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_reset_btn',
                    backgroundColor: Colors.white.withOpacity(0.9),
                    foregroundColor: const Color(0xFF0F172A),
                    onPressed: _resetZoom,
                    child: const Icon(Icons.fit_screen_outlined),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
