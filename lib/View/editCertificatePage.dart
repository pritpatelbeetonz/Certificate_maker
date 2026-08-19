// ignore_for_file: deprecated_member_use, unused_local_variable
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import '../rendering_engine/models/scene_node.dart';
import '../rendering_engine/canvas/viewport_transformer.dart';
import '../rendering_engine/models/sticker_model.dart';
import '../rendering_engine/widgets/interactive_overlay.dart';
import '../rendering_engine/styles/paint_factory.dart';
import '../rendering_engine/assets/dynamic_font_manager.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:hive/hive.dart';
import 'HomePage.dart';
import 'previewCertificatePage.dart';
import 'fullScreenViewerPage.dart';

import 'widgets/realtime_certificate_painter.dart';
import 'widgets/text_controls_panel.dart';
import 'widgets/logo_controls_panel.dart';
import 'widgets/signature_controls_panel.dart';
import 'widgets/stickers_controls_panel.dart';
import '../rendering_engine/export/scene_export_service.dart';

class EditCertificatePage extends StatefulWidget {
  final String layoutPath;
  final String? savedProjectName;

  const EditCertificatePage({
    super.key,
    required this.layoutPath,
    this.savedProjectName,
  });

  @override
  State<EditCertificatePage> createState() => _EditCertificatePageState();
}

class _EditCertificatePageState extends State<EditCertificatePage> {
  SceneDocument? _document;
  bool _isLoading = true;
  String? _selectedNodeId;
  String _activeTab = '';
  double _zoomScale = 1.0;
  double _zoomStartScale = 1.0;
  int _activePointers = 0;
  bool _isTouchOnNode = false;
  Size _lastCanvasPaintSize = Size.zero;
  final GlobalKey _canvasKey = GlobalKey();
  String? _editingTextNodeId;
  String? _lastSelectedLogoId;
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  Offset? _startFocalPoint;
  double _startScrollX = 0.0;
  double _startScrollY = 0.0;
  bool _showHorizontalGuideline = false;
  bool _showVerticalGuideline = false;
  bool _isCenterHorizontalGuideline = false;
  bool _isCenterVerticalGuideline = false;
  bool _hasVibratedX = false;
  bool _hasVibratedY = false;
  bool _isInteracting = false;
  bool _hasVibratedRotation = false;

  final List<List<Offset>> _signatureStrokes = [];
  final Color _currentSignatureColor = const Color(0xFF2563EB);

  String _pickedLogoName = 'Creative logo.png';
  String _pickedLogoDimensions = '350 × 120 px';

  final Map<String, String> _logoNames = {};
  final Map<String, String> _logoDimensions = {};
  final Map<String, String> _signatureNames = {};
  final Map<String, String> _signatureDimensions = {};

  // Image pool repository mapping assetId to loaded ui.Image
  final Map<String, ui.Image> _imagePool = {};

  // Picture pool repository mapping assetId to loaded ui.Picture (for SVGs)
  final Map<String, ui.Picture> _picturePool = {};

  // Undo/Redo history stacks (as json strings of SceneDocument)
  final List<String> _history = [];
  int _historyIndex = -1;

  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  final List<Map<String, dynamic>> _colorPalette = [
    {'color': const Color(0xFF2563EB), 'hex': '#FF2563EB'}, // Blue
    {'color': const Color(0xFFEF4444), 'hex': '#FFEF4444'}, // Red
    {'color': const Color(0xFFF59E0B), 'hex': '#FFF59E0B'}, // Yellow
    {'color': const Color(0xFF10B981), 'hex': '#FF10B981'}, // Green
    {'color': const Color(0xFF1F2937), 'hex': '#FF1F2937'}, // Black
    {'color': const Color(0xFF8B5CF6), 'hex': '#FF8B5CF6'}, // Purple
    {'color': const Color(0xFFFFFFFF), 'hex': '#FFFFFFFF'}, // White
  ];

  final List<String> _fontFamilies = [
    'System',
    'LibreBodoni',
    'LoveYaLikeASister',
    'OoohBaby',
  ];

  @override
  void initState() {
    super.initState();
    _loadLayoutAndAssets();
    _textController.addListener(_onTextChanged);
    _textFocusNode.addListener(() {
      if (!_textFocusNode.hasFocus && _editingTextNodeId != null) {
        _endEditing();
      }
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _textFocusNode.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final selectedLayer = (_selectedNodeId != null && _document != null)
        ? _document!.layers.firstWhereOrNull((l) => l.id == _selectedNodeId)
        : null;
    final TextNode? selectedNode = selectedLayer is TextNode ? selectedLayer : null;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _onBackPress();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
            onPressed: _onBackPress,
          ),
          title: const Text(
            'Edit Certificate',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            GestureDetector(
              onLongPress: _historyIndex > 0 ? _resetToFirstState : null,
              child: IconButton(
                icon: Icon(
                  Icons.undo,
                  color: _historyIndex > 0
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFCBD5E1),
                ),
                onPressed: _historyIndex > 0 ? _undo : null,
              ),
            ),
            GestureDetector(
              onLongPress: _historyIndex < _history.length - 1 ? _resetToLastState : null,
              child: IconButton(
                icon: Icon(
                  Icons.redo,
                  color: _historyIndex < _history.length - 1
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFCBD5E1),
                ),
                onPressed: _historyIndex < _history.length - 1 ? _redo : null,
              ),
            ),
            if (_selectedNodeId == null)
              IconButton(
                icon: const Icon(Icons.fullscreen, color: Color(0xFF0F172A)),
                tooltip: 'Preview Landscape',
                onPressed: () async {
                  if (_document == null) return;
                  await Get.to(() => FullScreenViewerPage(
                        document: _document!,
                        imagePool: _imagePool,
                        picturePool: _picturePool,
                      ));
                  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                  await SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                  ]);
                  setState(() {});
                },
              ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: ElevatedButton(
                onPressed: () {
                  if (_document == null) return;
                  Get.to(() => PreviewCertificatePage(
                        document: _document!,
                        imagePool: _imagePool,
                        layoutPath: widget.layoutPath,
                      ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B21B6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text(
                  'Export',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _document == null
            ? const Center(child: Text("Error loading layout"))
            : Column(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      alignment: Alignment.center,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double canvasRatio =
                              _document!.canvas.virtualWidth /
                              _document!.canvas.virtualHeight;

                          double targetW = constraints.maxWidth * _zoomScale;
                          double targetH =
                              (constraints.maxWidth / canvasRatio) * _zoomScale;

                          if (targetH > constraints.maxHeight * _zoomScale) {
                            targetH = constraints.maxHeight * _zoomScale;
                            targetW = targetH * canvasRatio;
                          }

                          final Size canvasPaintSize = Size(targetW, targetH);
                          final transformer = ViewportTransformer(
                            virtualWidth: _document!.canvas.virtualWidth,
                            virtualHeight: _document!.canvas.virtualHeight,
                            targetSize: canvasPaintSize,
                          );
                          _lastCanvasPaintSize = canvasPaintSize;

                          final scrollPhysics =
                              (_isTouchOnNode || _activePointers > 1)
                              ? const NeverScrollableScrollPhysics()
                              : const BouncingScrollPhysics();

                          return Listener(
                            onPointerDown: _onPointerDown,
                            onPointerUp: _onPointerUp,
                            onPointerCancel: _onPointerCancel,
                            child: SingleChildScrollView(
                              controller: _verticalScrollController,
                              scrollDirection: Axis.vertical,
                              physics: scrollPhysics,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: SingleChildScrollView(
                                  controller: _horizontalScrollController,
                                  scrollDirection: Axis.horizontal,
                                  physics: scrollPhysics,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: constraints.maxWidth,
                                    ),
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Container(
                                        key: _canvasKey,
                                        width: targetW,
                                        height: targetH,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.08),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            GestureDetector(
                                              onTapUp: (details) {
                                                _detectHitTest(
                                                  details.localPosition,
                                                  canvasPaintSize,
                                                );
                                              },
                                              onDoubleTapDown: (details) {
                                                _detectDoubleTapHitTest(
                                                  details.localPosition,
                                                  canvasPaintSize,
                                                );
                                              },
                                              onScaleStart: _onScaleStart,
                                              onScaleUpdate: _onScaleUpdate,
                                              child: CustomPaint(
                                                size: canvasPaintSize,
                                                painter: RealtimeCertificatePainter(
                                                  document: _document!,
                                                  loadedImages: _imagePool,
                                                  picturePool: _picturePool,
                                                  selectedNodeId: _selectedNodeId,
                                                  editingNodeId: _editingTextNodeId,
                                                ),
                                              ),
                                            ),
                                              if (_isInteracting || _showHorizontalGuideline || _showVerticalGuideline)
                                                IgnorePointer(
                                                  child: CustomPaint(
                                                    size: canvasPaintSize,
                                                    painter: GuidelinePainter(
                                                      showHorizontal: _isInteracting || _showHorizontalGuideline,
                                                      showVertical: _isInteracting || _showVerticalGuideline,
                                                      horizontalY: canvasPaintSize.height / 2.0,
                                                      verticalX: canvasPaintSize.width / 2.0,
                                                      isCenterHorizontal: _showHorizontalGuideline && _isCenterHorizontalGuideline,
                                                      isCenterVertical: _showVerticalGuideline && _isCenterVerticalGuideline,
                                                      showGrid: _isInteracting,
                                                    ),
                                                  ),
                                                ),
                                              if (selectedLayer != null && _editingTextNodeId != selectedLayer.id) ...[
                                               _buildSelectedOverlay(
                                                 selectedLayer,
                                                 transformer,
                                                 canvasPaintSize,
                                               ),
                                             ],
                                            if (_editingTextNodeId != null) ...[
                                              _buildInlineEditor(transformer),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Floating Zoom Controls Capsule
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove,
                              size: 20,
                              color: Color(0xFF64748B),
                            ),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                             onPressed: () {
                               _zoomTo((_zoomScale - 0.25).clamp(0.5, 3.0));
                             },
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(_zoomScale * 100).round()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(
                              Icons.add,
                              size: 20,
                              color: Color(0xFF64748B),
                            ),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                             onPressed: () {
                               _zoomTo((_zoomScale + 0.25).clamp(0.5, 3.0));
                             },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_editingTextNodeId == null) ...[
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _buildDynamicControlsPanel(selectedNode),
                    ),
                    _buildBottomNavigationBar(),
                  ],
                ],
              ),
      ),
    );
  }

  void _zoomTo(double newZoom, [Offset? customFocalPoint]) {
    if ((newZoom - _zoomScale).abs() < 0.001) return;

    final RenderBox? viewportBox = context.findRenderObject() as RenderBox?;
    if (viewportBox == null) return;
    
    final Offset focal = customFocalPoint ?? Offset(viewportBox.size.width / 2, viewportBox.size.height / 2);
    final double currentScrollX = _horizontalScrollController.hasClients ? _horizontalScrollController.offset : 0.0;
    final double currentScrollY = _verticalScrollController.hasClients ? _verticalScrollController.offset : 0.0;
    
    final double ratio = newZoom / _zoomScale;
    final double targetScrollX = (currentScrollX + focal.dx) * ratio - focal.dx;
    final double targetScrollY = (currentScrollY + focal.dy) * ratio - focal.dy;

    setState(() {
      _zoomScale = newZoom;
    });

    if (_horizontalScrollController.hasClients) {
      _horizontalScrollController.jumpTo(targetScrollX);
    }
    if (_verticalScrollController.hasClients) {
      _verticalScrollController.jumpTo(targetScrollY);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_horizontalScrollController.hasClients) {
        _horizontalScrollController.jumpTo(targetScrollX.clamp(0.0, _horizontalScrollController.position.maxScrollExtent));
      }
      if (_verticalScrollController.hasClients) {
        _verticalScrollController.jumpTo(targetScrollY.clamp(0.0, _verticalScrollController.position.maxScrollExtent));
      }
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _zoomStartScale = _zoomScale;
    final RenderBox? viewportBox = context.findRenderObject() as RenderBox?;
    if (viewportBox != null) {
      _startFocalPoint = viewportBox.globalToLocal(details.focalPoint);
      _startScrollX = _horizontalScrollController.hasClients ? _horizontalScrollController.offset : 0.0;
      _startScrollY = _verticalScrollController.hasClients ? _verticalScrollController.offset : 0.0;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_activePointers < 2 || _startFocalPoint == null) {
      return;
    }

    final double newZoom = (_zoomStartScale * details.scale).clamp(0.5, 3.0);

    if ((newZoom - _zoomScale).abs() < 0.001) {
      return;
    }

    final double ratio = newZoom / _zoomStartScale;
    final double targetScrollX = (_startScrollX + _startFocalPoint!.dx) * ratio - _startFocalPoint!.dx;
    final double targetScrollY = (_startScrollY + _startFocalPoint!.dy) * ratio - _startFocalPoint!.dy;

    setState(() {
      _zoomScale = newZoom;
    });

    if (_horizontalScrollController.hasClients) {
      _horizontalScrollController.jumpTo(targetScrollX);
    }
    if (_verticalScrollController.hasClients) {
      _verticalScrollController.jumpTo(targetScrollY);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_horizontalScrollController.hasClients) {
        _horizontalScrollController.jumpTo(targetScrollX.clamp(0.0, _horizontalScrollController.position.maxScrollExtent));
      }
      if (_verticalScrollController.hasClients) {
        _verticalScrollController.jumpTo(targetScrollY.clamp(0.0, _verticalScrollController.position.maxScrollExtent));
      }
    });
  }

  bool _isPointNearSelectedNode(
    Offset localPos,
    SceneNode node,
    ViewportTransformer transformer,
  ) {
    final double sx = transformer.toScreenX(node.bounds.x);
    final double sy = transformer.toScreenY(node.bounds.y);
    final double sw = transformer.toScreenWidth(node.bounds.width);
    final double sh = transformer.toScreenHeight(node.bounds.height);

    // Padding to include handles (rotate, resize, delete buttons)
    const double padding = 45.0;
    final rect = Rect.fromLTWH(
      sx - padding,
      sy - padding,
      sw + padding * 2,
      sh + padding * 2,
    );

    if (node.transform.rotation != 0.0) {
      final center = Offset(sx + sw / 2, sy + sh / 2);
      final angleRad = -node.transform.rotation * pi / 180.0;

      final rotatedX =
          cos(angleRad) * (localPos.dx - center.dx) -
          sin(angleRad) * (localPos.dy - center.dy) +
          center.dx;
      final rotatedY =
          sin(angleRad) * (localPos.dx - center.dx) +
          cos(angleRad) * (localPos.dy - center.dy) +
          center.dy;

      return rect.contains(Offset(rotatedX, rotatedY));
    }

    return rect.contains(localPos);
  }

  void _onPointerDown(PointerDownEvent event) {
    bool isTouchOnNode = false;
    final selectedLayer = (_selectedNodeId != null && _document != null)
        ? _document!.layers.firstWhereOrNull((l) => l.id == _selectedNodeId)
        : null;
    final TextNode? selectedNode = selectedLayer is TextNode ? selectedLayer : null;

    if (selectedLayer != null && _lastCanvasPaintSize != Size.zero) {
      final renderBox =
          _canvasKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final localPos = renderBox.globalToLocal(event.position);
        final transformer = ViewportTransformer(
          virtualWidth: _document!.canvas.virtualWidth,
          virtualHeight: _document!.canvas.virtualHeight,
          targetSize: _lastCanvasPaintSize,
        );
        isTouchOnNode = _isPointNearSelectedNode(
          localPos,
          selectedLayer,
          transformer,
        );
      }
    }

    if (_editingTextNodeId != null && !isTouchOnNode) {
      _endEditing();
    }

    setState(() {
      _activePointers++;
      _isTouchOnNode = isTouchOnNode;
      _isInteracting = isTouchOnNode;
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() {
      _activePointers = (_activePointers - 1).clamp(0, 10);
      if (_activePointers == 0) {
        _isTouchOnNode = false;
        _isInteracting = false;
      }
      _showHorizontalGuideline = false;
      _showVerticalGuideline = false;
      _hasVibratedX = false;
      _hasVibratedY = false;
      _hasVibratedRotation = false;
    });
  }

  void _onPointerCancel(PointerCancelEvent event) {
    setState(() {
      _activePointers = (_activePointers - 1).clamp(0, 10);
      if (_activePointers == 0) {
        _isTouchOnNode = false;
        _isInteracting = false;
      }
      _showHorizontalGuideline = false;
      _showVerticalGuideline = false;
      _hasVibratedX = false;
      _hasVibratedY = false;
      _hasVibratedRotation = false;
    });
  }

  void _endEditing() {
    if (_editingTextNodeId == null) return;
    setState(() {
      _editingTextNodeId = null;
    });
    _textFocusNode.unfocus();
    
    // Only save history if the current state is different from the last history state
    if (_document != null && _history.isNotEmpty) {
      final currentJson = json.encode(_document!.toJson());
      final lastJson = _history[_historyIndex];
      if (currentJson != lastJson) {
        _saveToHistory();
      }
    }
  }

  void _detectDoubleTapHitTest(Offset localTapPos, Size paintSize) {
    if (_document == null) return;
    final transformer = ViewportTransformer(
      virtualWidth: _document!.canvas.virtualWidth,
      virtualHeight: _document!.canvas.virtualHeight,
      targetSize: paintSize,
    );

    final reversedLayers = List<SceneNode>.from(_document!.layers).reversed.toList();
    for (final node in reversedLayers) {
      if (node is! TextNode || !node.state.visible) continue;

      final double sx = transformer.toScreenX(node.bounds.x);
      final double sy = transformer.toScreenY(node.bounds.y);
      final double sw = transformer.toScreenWidth(node.bounds.width);
      final double sh = transformer.toScreenHeight(node.bounds.height);

      final rect = Rect.fromLTWH(sx, sy, sw, sh);

      bool hit = false;
      if (node.transform.rotation != 0.0) {
        final center = rect.center;
        final angleRad = -node.transform.rotation * pi / 180.0;
        
        final rotatedTapX = cos(angleRad) * (localTapPos.dx - center.dx) -
            sin(angleRad) * (localTapPos.dy - center.dy) +
            center.dx;
        final rotatedTapY = sin(angleRad) * (localTapPos.dx - center.dx) +
            cos(angleRad) * (localTapPos.dy - center.dy) +
            center.dy;

        hit = rect.contains(Offset(rotatedTapX, rotatedTapY));
      } else {
        hit = rect.contains(localTapPos);
      }

      if (hit) {
        setState(() {
          _selectedNodeId = node.id;
          _editingTextNodeId = node.id;
          _textController.value = _textController.value.copyWith(
            text: node.text,
            selection: TextSelection.collapsed(offset: node.text.length),
            composing: TextRange.empty,
          );
          _activeTab = 'Text';
        });
        _textFocusNode.requestFocus();
        return;
      }
    }
  }

  Widget _buildInlineEditor(ViewportTransformer transformer) {
    if (_document == null || _editingTextNodeId == null) return const SizedBox.shrink();
    final node = _document!.layers.firstWhereOrNull((l) => l.id == _editingTextNodeId);
    if (node is! TextNode) return const SizedBox.shrink();

    final double sx = transformer.toScreenX(node.bounds.x);
    final double sy = transformer.toScreenY(node.bounds.y);
    final double sw = transformer.toScreenWidth(node.bounds.width);
    final double sh = transformer.toScreenHeight(node.bounds.height);

    final double screenScale = transformer.scaleX;

    final parsedColor = PaintFactory.parseHexColor(node.color);
    final parsedFontWeight = _parseFontWeight(node.fontWeight);
    final parsedFontStyle = _parseFontStyle(node.fontStyle);
    final parsedTextAlign = _parseTextAlign(node.align);
    final parsedTextDecoration = _parseTextDecoration(node.decoration);

    Widget textField = TextField(
      controller: _textController,
      focusNode: _textFocusNode,
      autofocus: true,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      textAlign: parsedTextAlign,
      cursorColor: parsedColor,
      style: TextStyle(
        fontFamily: node.fontFamily == 'System' ? null : node.fontFamily,
        fontSize: node.fontSize * screenScale,
        color: parsedColor,
        fontWeight: parsedFontWeight,
        fontStyle: parsedFontStyle,
        decoration: parsedTextDecoration,
        letterSpacing: node.letterSpacing * screenScale,
        height: node.lineHeight,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isCollapsed: true,
      ),
      onSubmitted: (_) {
        _endEditing();
      },
    );
    const double kSelectionPadding = 12.0;
    Widget editorWithBorder = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -kSelectionPadding,
          left: -kSelectionPadding,
          right: -kSelectionPadding,
          bottom: -kSelectionPadding,
          child: IgnorePointer(
            child: DottedBorder(
              options: const RectDottedBorderOptions(
                padding: EdgeInsets.zero,
                color: Colors.blueAccent,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        textField,
      ],
    );

    if (node.transform.rotation != 0.0) {
      final double rotationAngleRad = node.transform.rotation * pi / 180.0;
      editorWithBorder = Transform.rotate(
        angle: rotationAngleRad,
        child: editorWithBorder,
      );
    }

    return Positioned(
      left: sx,
      top: sy,
      width: sw,
      height: sh,
      child: editorWithBorder,
    );
  }

  FontWeight _parseFontWeight(String? weight) {
    if (weight == null) return FontWeight.normal;
    switch (weight.toLowerCase()) {
      case 'bold':
        return FontWeight.bold;
      case 'w100':
      case '100':
        return FontWeight.w100;
      case 'w200':
      case '200':
        return FontWeight.w200;
      case 'w300':
      case '300':
        return FontWeight.w300;
      case 'w400':
      case '400':
        return FontWeight.w400;
      case 'w500':
      case '500':
        return FontWeight.w500;
      case 'w600':
      case '600':
        return FontWeight.w600;
      case 'w700':
      case '700':
        return FontWeight.w700;
      case 'w800':
      case '800':
        return FontWeight.w800;
      case 'w900':
      case '900':
        return FontWeight.w900;
      case 'normal':
      default:
        return FontWeight.normal;
    }
  }

  FontStyle _parseFontStyle(String? style) {
    if (style == null) return FontStyle.normal;
    switch (style.toLowerCase()) {
      case 'italic':
        return FontStyle.italic;
      case 'normal':
      default:
        return FontStyle.normal;
    }
  }

  TextAlign _parseTextAlign(String? align) {
    if (align == null) return TextAlign.left;
    switch (align.toLowerCase()) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      case 'left':
      default:
        return TextAlign.left;
    }
  }

  TextDecoration _parseTextDecoration(String? decoration) {
    if (decoration == null) return TextDecoration.none;
    switch (decoration.toLowerCase()) {
      case 'underline':
        return TextDecoration.underline;
      case 'linethrough':
      case 'line-through':
        return TextDecoration.lineThrough;
      case 'overline':
        return TextDecoration.overline;
      case 'none':
      default:
        return TextDecoration.none;
    }
  }

  double _calculateTextNodeHeight(TextNode node, double virtualWidth) {
    if (node.id.startsWith('logo') || node.id.startsWith('signature')) {
      return node.bounds.height;
    }
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.text,
        style: TextStyle(
          fontFamily: node.fontFamily == 'System' ? null : node.fontFamily,
          fontSize: node.fontSize,
          fontWeight: _parseFontWeight(node.fontWeight),
          fontStyle: _parseFontStyle(node.fontStyle),
          decoration: _parseTextDecoration(node.decoration),
          letterSpacing: node.letterSpacing,
          height: node.lineHeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: virtualWidth);
    return textPainter.height > 0 ? textPainter.height : 10.0;
  }

  int _calculateTextNodeLineCount(TextNode node, double virtualWidth) {
    if (node.id.startsWith('logo') || node.id.startsWith('signature')) {
      return 1;
    }
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.text,
        style: TextStyle(
          fontFamily: node.fontFamily == 'System' ? null : node.fontFamily,
          fontSize: node.fontSize,
          fontWeight: _parseFontWeight(node.fontWeight),
          fontStyle: _parseFontStyle(node.fontStyle),
          decoration: _parseTextDecoration(node.decoration),
          letterSpacing: node.letterSpacing,
          height: node.lineHeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: virtualWidth);
    return textPainter.computeLineMetrics().length;
  }

  Future<void> _loadLayoutAndAssets() async {
    try {
      SceneDocument doc;
      if (widget.savedProjectName != null) {
        final box = Hive.box('saved_projects');
        final projectData = box.get(widget.savedProjectName) as Map<dynamic, dynamic>?;
        if (projectData != null && projectData['document'] != null) {
          final docJson = Map<String, dynamic>.from(projectData['document'] as Map);
          doc = SceneDocument.fromJson(docJson);
        } else {
          final String jsonString = await rootBundle.loadString(widget.layoutPath);
          final Map<String, dynamic> jsonMap = json.decode(jsonString);
          doc = SceneDocument.fromJson(jsonMap);
        }
      } else {
        final String jsonString = await rootBundle.loadString(widget.layoutPath);
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        doc = SceneDocument.fromJson(jsonMap);
      }

      // Preload images and fonts from assets
      for (var entry in doc.assets.entries) {
        final assetId = entry.key;
        final asset = entry.value;
        if (asset.type == 'image') {
          try {
            final ui.Image img = await _loadUiImage(asset.src);
            _imagePool[assetId] = img;
          } catch (e) {
            debugPrint("Failed to load image asset: ${asset.src} ($e)");
          }
        } else if (asset.type == 'svg') {
          try {
            final PictureInfo pictureInfo = await vg.loadPicture(
              SvgAssetLoader(asset.src),
              null,
            );
            _picturePool[assetId] = pictureInfo.picture;
          } catch (e) {
            debugPrint("Failed to load SVG asset: ${asset.src} ($e)");
          }
        } else if (asset.type == 'font') {
          try {
            await DynamicFontManager.instance.loadFont(assetId, asset.src);
            if (!_fontFamilies.contains(assetId)) {
              _fontFamilies.add(assetId);
            }
          } catch (e) {
            debugPrint("Failed to load font asset: ${asset.src} ($e)");
          }
        }
      }

      setState(() {
        _document = doc;
        _isLoading = false;
        _saveToHistory();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error loading editor data: $e");
    }
  }

  Future<ui.Image> _loadUiImage(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _saveToHistory() {
    if (_document == null) return;
    final jsonStr = json.encode(_document!.toJson());

    // Clean any forward history if we are in the middle of undo stack
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    _history.add(jsonStr);
    _historyIndex = _history.length - 1;
  }

  void _undo() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
        final jsonMap = json.decode(_history[_historyIndex]);
        _document = SceneDocument.fromJson(jsonMap);
        _updateSelectedNodeTextField();
      });
    }
  }

  void _redo() {
    if (_historyIndex < _history.length - 1) {
      setState(() {
        _historyIndex++;
        final jsonMap = json.decode(_history[_historyIndex]);
        _document = SceneDocument.fromJson(jsonMap);
        _updateSelectedNodeTextField();
      });
    }
  }

  void _resetToFirstState() {
    if (_history.isNotEmpty && _historyIndex > 0) {
      setState(() {
        _historyIndex = 0;
        final jsonMap = json.decode(_history[_historyIndex]);
        _document = SceneDocument.fromJson(jsonMap);
        _updateSelectedNodeTextField();
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _resetToLastState() {
    if (_history.isNotEmpty && _historyIndex < _history.length - 1) {
      setState(() {
        _historyIndex = _history.length - 1;
        final jsonMap = json.decode(_history[_historyIndex]);
        _document = SceneDocument.fromJson(jsonMap);
        _updateSelectedNodeTextField();
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _onTextChanged() {
    if (_document == null || _selectedNodeId == null) return;
    final int index = _document!.layers.indexWhere(
      (l) => l.id == _selectedNodeId,
    );
    if (index == -1) return;

    final node = _document!.layers[index];
    if (node is TextNode && node.text != _textController.text) {
      // Measure text width and height in virtual coordinates at node.fontSize
      final textPainter = TextPainter(
        text: TextSpan(
          text: _textController.text,
          style: TextStyle(
            fontFamily: node.fontFamily == 'System' ? null : node.fontFamily,
            fontSize: node.fontSize,
            fontWeight: _parseFontWeight(node.fontWeight),
            fontStyle: _parseFontStyle(node.fontStyle),
            decoration: _parseTextDecoration(node.decoration),
            letterSpacing: node.letterSpacing,
            height: node.lineHeight,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Add a small safety buffer (e.g. 10 pixels in virtual coordinates)
      final double newVirtualWidth = textPainter.width > 0 ? textPainter.width + 10.0 : 30.0;
      
      final tempNode = node.copyWith(
        text: _textController.text,
      );
      final double newVirtualHeight = _calculateTextNodeHeight(tempNode, newVirtualWidth);

      // Adjust X position based on alignment to keep the text correctly anchored
      double newX = node.bounds.x;
      if (node.align == 'center') {
        final double centerX = node.bounds.x + (node.bounds.width / 2.0);
        newX = centerX - (newVirtualWidth / 2.0);
      } else if (node.align == 'right') {
        final double rightX = node.bounds.x + node.bounds.width;
        newX = rightX - newVirtualWidth;
      }

      final updatedNode = node.copyWith(
        text: _textController.text,
        bounds: NodeBounds(
          x: newX,
          y: node.bounds.y,
          width: newVirtualWidth,
          height: newVirtualHeight,
        ),
      );

      setState(() {
        _document!.layers[index] = updatedNode;
      });
    }
  }

  void _saveTextEditingState() {
    _saveToHistory();
  }

  void _updateSelectedNodeTextField() {
    if (_selectedNodeId == null || _document == null) {
      _textController.text = "";
      return;
    }
    final node = _document!.layers.firstWhereOrNull(
      (l) => l.id == _selectedNodeId,
    );
    if (node is TextNode) {
      _textController.text = node.text;
    } else {
      _textController.text = "";
    }
  }

  void _selectNode(String? id) {
    if (_editingTextNodeId != null && _editingTextNodeId != id) {
      final oldId = _editingTextNodeId;
      _editingTextNodeId = null;
      _textFocusNode.unfocus();
      _saveToHistory();
    }
    setState(() {
      _selectedNodeId = id;
      _updateSelectedNodeTextField();
      if (id == null) {
        _activeTab = '';
      } else if (_document != null) {
        final node = _document!.layers.firstWhereOrNull((l) => l.id == id);
        if (id.startsWith('logo') || (node?.id.startsWith('logo') ?? false)) {
          _activeTab = 'Logo';
          _lastSelectedLogoId = id;
        } else if (id.startsWith('signature') ||
            (node?.id.startsWith('signature') ?? false)) {
          _activeTab = 'Signature';
        } else if (node is TextNode) {
          _activeTab = 'Text';
        }
      }
    });
  }

  void _deleteLayer(String id) {
    if (_document == null) return;
    setState(() {
      _document!.layers.removeWhere((l) => l.id == id);
      if (_selectedNodeId == id) {
        _selectedNodeId = null;
        _updateSelectedNodeTextField();
      }
      _saveToHistory();
    });
  }

  int _getNextTopZIndex() {
    if (_document == null || _document!.layers.isEmpty) return 1;
    final maxZ = _document!.layers.map((l) => l.zIndex).reduce(max);
    return maxZ + 1;
  }

  void _addNewTextNode() {
    if (_document == null) return;
    final String newId = "text_${DateTime.now().millisecondsSinceEpoch}";
    final newTextNode = TextNode(
      id: newId,
      displayName: "Text Layer",
      text: "New Text",
      fontFamily: 'System',
      fontSize: 16.0,
      color: '#FF1F2937', // Default black/dark grey
      align: 'left',
      fontWeight: '400',
      fontStyle: 'normal',
      decoration: 'none',
      bounds: NodeBounds(
        x: (_document!.canvas.virtualWidth / 2) - 50,
        y: (_document!.canvas.virtualHeight / 2) - 15,
        width: 100,
        height: 30,
      ),
      transform: NodeTransform(rotation: 0.0, pivot: const Offset(0.5, 0.5)),
      state: NodeState(visible: true, locked: false),
      interaction: NodeInteraction(
        selectable: true,
        movable: true,
        editable: true,
      ),
    );

    setState(() {
      _document!.layers.add(newTextNode);
      _selectedNodeId = newId;
      _updateSelectedNodeTextField();
      _saveToHistory();
    });
  }

  void _updateSelectedTextProperty({
    String? fontFamily,
    double? fontSize,
    String? color,
    String? fontWeight,
    String? fontStyle,
    String? decoration,
    String? align,
    bool? saveHistory,
  }) {
    if (_document == null || _selectedNodeId == null) return;
    final int index = _document!.layers.indexWhere(
      (l) => l.id == _selectedNodeId,
    );
    if (index == -1) return;

    final node = _document!.layers[index];
    if (node is TextNode) {
      final double newFontSize = fontSize ?? node.fontSize;
      
      // Calculate updated width based on font size scaling if font size changed
      double newWidth = node.bounds.width;
      if (fontSize != null && node.fontSize > 0) {
        final double scaleFactor = fontSize / node.fontSize;
        newWidth = node.bounds.width * scaleFactor;
      }

      // Create a temporary node to calculate the correct height
      final tempNode = node.copyWith(
        fontFamily: fontFamily ?? node.fontFamily,
        fontSize: newFontSize,
        color: color ?? node.color,
        fontWeight: fontWeight ?? node.fontWeight,
        fontStyle: fontStyle ?? node.fontStyle,
        decoration: decoration ?? node.decoration,
        align: align ?? node.align,
      );

      final double newHeight = _calculateTextNodeHeight(tempNode, newWidth);

      // Keep center fixed
      final double centerX = node.bounds.x + (node.bounds.width / 2.0);
      final double centerY = node.bounds.y + (node.bounds.height / 2.0);
      final double newX = centerX - (newWidth / 2.0);
      final double newY = centerY - (newHeight / 2.0);

      final updatedNode = tempNode.copyWith(
        bounds: NodeBounds(
          x: newX,
          y: newY,
          width: newWidth,
          height: newHeight,
        ),
      );

      setState(() {
        _document!.layers[index] = updatedNode;
      });
      if (saveHistory ?? true) {
        _saveToHistory();
      }
    }
  }

  void _onColorSelected(String hex, Color color) {
    final bool alreadyExists = _colorPalette.any(
      (item) => item['hex'].toString().toUpperCase() == hex.toUpperCase(),
    );
    if (!alreadyExists) {
      setState(() {
        _colorPalette.add({'color': color, 'hex': hex});
      });
    }
    _updateSelectedTextProperty(color: hex);
  }

  void _detectHitTest(Offset localTapPos, Size paintSize) {
    if (_document == null) return;
    final transformer = ViewportTransformer(
      virtualWidth: _document!.canvas.virtualWidth,
      virtualHeight: _document!.canvas.virtualHeight,
      targetSize: paintSize,
    );

    final reversedLayers = List<SceneNode>.from(
      _document!.layers,
    ).reversed.toList();
    for (final node in reversedLayers) {
      if ((node is! TextNode && node is! StickerNode) || !node.state.visible) continue;

      final double sx = transformer.toScreenX(node.bounds.x);
      final double sy = transformer.toScreenY(node.bounds.y);
      final double sw = transformer.toScreenWidth(node.bounds.width);
      final double sh = transformer.toScreenHeight(node.bounds.height);

      final rect = Rect.fromLTWH(sx, sy, sw, sh);

      if (node.transform.rotation != 0.0) {
        final center = rect.center;
        final angleRad = -node.transform.rotation * pi / 180.0;

        final rotatedTapX =
            cos(angleRad) * (localTapPos.dx - center.dx) -
            sin(angleRad) * (localTapPos.dy - center.dy) +
            center.dx;
        final rotatedTapY =
            sin(angleRad) * (localTapPos.dx - center.dx) +
            cos(angleRad) * (localTapPos.dy - center.dy) +
            center.dy;

        if (rect.contains(Offset(rotatedTapX, rotatedTapY))) {
          _selectNode(node.id);
          return;
        }
      } else {
        if (rect.contains(localTapPos)) {
          _selectNode(node.id);
          return;
        }
      }
    }

    _selectNode(null);
  }

  Widget _buildSelectedOverlay(
    SceneNode node,
    ViewportTransformer transformer,
    Size paintSize,
  ) {
    final double sx = transformer.toScreenX(node.bounds.x);
    final double sy = transformer.toScreenY(node.bounds.y);
    final double sw = transformer.toScreenWidth(node.bounds.width);
    final double sh = transformer.toScreenHeight(node.bounds.height);

    final double rotationAngleRad = node.transform.rotation * pi / 180.0;

    final stickerModel = StickerModel(
      left: sx,
      top: sy,
      angle: rotationAngleRad,
      scale: 1.0,
      isSelected: true,
    );

    final bool isLogoOrSigOrSticker = node.id.startsWith('logo') || node.id.startsWith('signature') || node is StickerNode;
    final int lineCount = node is TextNode ? _calculateTextNodeLineCount(node, node.bounds.width) : 1;
    final bool isMultiLine = node is TextNode ? (lineCount > 1 || node.text.contains('\n')) : false;
    final bool showTopBottom = isLogoOrSigOrSticker ? true : isMultiLine;

    return InteractiveOverlay(
      model: stickerModel,
      boundWidth: paintSize.width,
      boundHeight: paintSize.height,
      width: sw,
      height: sh,
      isEditingText: _editingTextNodeId == node.id,
      showTopBottomHandles: showTopBottom,
      onUpdate: () {
        final SceneNode originalNode = (_document != null)
            ? _document!.layers.firstWhereOrNull((l) => l.id == node.id) ?? node
            : node;

        final double currentVirtualW = originalNode.bounds.width;
        final double currentVirtualH = originalNode.bounds.height;
        final double currentVirtualX = originalNode.bounds.x;
        final double currentVirtualY = originalNode.bounds.y;

        final double currentSw = transformer.toScreenWidth(currentVirtualW);
        final double currentSh = transformer.toScreenHeight(currentVirtualH);
        final double currentSx = transformer.toScreenX(currentVirtualX);
        final double currentSy = transformer.toScreenY(currentVirtualY);

        double finalAppliedScale = stickerModel.scale;

        double rotationDeg = stickerModel.angle * 180.0 / pi;
        final double snappedDeg = (rotationDeg / 90.0).round() * 90.0;
        if ((rotationDeg - snappedDeg).abs() < 3.0) {
          rotationDeg = snappedDeg;
          stickerModel.angle = snappedDeg * pi / 180.0;
          if (!_hasVibratedRotation) {
            HapticFeedback.lightImpact();
            _hasVibratedRotation = true;
          }
        } else {
          _hasVibratedRotation = false;
        }

        final double finalScale = finalAppliedScale;

        final double virtualW = currentVirtualW * finalScale;
        final double virtualH = currentVirtualH * finalScale;

        final double snapThresholdScreen = 6.0;
        final double canvasCenterScreenX = transformer.toScreenX(_document!.canvas.virtualWidth / 2.0);
        final double canvasCenterScreenY = transformer.toScreenY(_document!.canvas.virtualHeight / 2.0);
        
        double nodeCenterScreenX = stickerModel.left + (currentSw * finalScale) / 2.0;
        double nodeCenterScreenY = stickerModel.top + (currentSh * finalScale) / 2.0;

        bool showVertical = false;
        bool showHorizontal = false;
        bool isCenterVert = false;
        bool isCenterHoriz = false;

        if ((nodeCenterScreenX - canvasCenterScreenX).abs() < snapThresholdScreen) {
          nodeCenterScreenX = canvasCenterScreenX;
          stickerModel.left = nodeCenterScreenX - (currentSw * finalScale) / 2.0;
          showVertical = true;
          isCenterVert = true;
          
          if (!_hasVibratedX) {
            HapticFeedback.lightImpact();
            _hasVibratedX = true;
          }
        } else {
          _hasVibratedX = false;
        }

        if ((nodeCenterScreenY - canvasCenterScreenY).abs() < snapThresholdScreen) {
          nodeCenterScreenY = canvasCenterScreenY;
          stickerModel.top = nodeCenterScreenY - (currentSh * finalScale) / 2.0;
          showHorizontal = true;
          isCenterHoriz = true;
          
          if (!_hasVibratedY) {
            HapticFeedback.lightImpact();
            _hasVibratedY = true;
          }
        } else {
          _hasVibratedY = false;
        }

        // Calculate position drag offset (if any)
        final double moveDxVirtual = transformer.toVirtualWidth(
          stickerModel.left - currentSx,
        );
        final double moveDyVirtual = transformer.toVirtualHeight(
          stickerModel.top - currentSy,
        );

        // Calculate center of original bounds in virtual coordinates
        final double initialVirtualCenterX =
            currentVirtualX + (currentVirtualW / 2.0);
        final double initialVirtualCenterY =
            currentVirtualY + (currentVirtualH / 2.0);

        final double currentVirtualCenterX =
            initialVirtualCenterX + moveDxVirtual;
        final double currentVirtualCenterY =
            initialVirtualCenterY + moveDyVirtual;

        // Keep center fixed while scaling
        final double newVirtualX = currentVirtualCenterX - (virtualW / 2.0);
        final double newVirtualY = currentVirtualCenterY - (virtualH / 2.0);

        rotationDeg = stickerModel.angle * 180.0 / pi;

        setState(() {
          _showVerticalGuideline = showVertical;
          _showHorizontalGuideline = showHorizontal;
          _isCenterVerticalGuideline = isCenterVert;
          _isCenterHorizontalGuideline = isCenterHoriz;
        });

        if (_document != null) {
          final int index = _document!.layers.indexWhere(
            (l) => l.id == node.id,
          );
          if (index != -1) {
            setState(() {
              if (originalNode is StickerNode) {
                final double scaledW = currentVirtualW * finalScale;
                final double scaledH = currentVirtualH * finalScale;
                final double stickerX = currentVirtualCenterX - (scaledW / 2.0);
                final double stickerY = currentVirtualCenterY - (scaledH / 2.0);

                _document!.layers[index] = originalNode.copyWith(
                  bounds: NodeBounds(
                    x: stickerX,
                    y: stickerY,
                    width: scaledW,
                    height: scaledH,
                  ),
                  transform: NodeTransform(
                    rotation: rotationDeg,
                    pivot: originalNode.transform.pivot,
                  ),
                );
              } else if (originalNode is TextNode) {
                if (originalNode.id.startsWith('logo') || originalNode.id.startsWith('signature')) {
                  // Logos and signatures: proportional scale bounds only
                  final double scaledW = currentVirtualW * finalScale;
                  final double scaledH = currentVirtualH * finalScale;
                  
                  final double logoX = currentVirtualCenterX - (scaledW / 2.0);
                  final double logoY = currentVirtualCenterY - (scaledH / 2.0);

                  _document!.layers[index] = originalNode.copyWith(
                    bounds: NodeBounds(
                      x: logoX,
                      y: logoY,
                      width: scaledW,
                      height: scaledH,
                    ),
                    transform: NodeTransform(
                      rotation: rotationDeg,
                      pivot: originalNode.transform.pivot,
                      skew: originalNode.transform.skew,
                      flipX: originalNode.transform.flipX,
                      flipY: originalNode.transform.flipY,
                    ),
                  );
                } else {
                  // Actual text nodes: dynamic height wrapper based on text layout
                  final double newFontSize = (originalNode.fontSize * finalScale)
                      .clamp(6.0, 72.0);
                  
                  final double textW = currentVirtualW * finalScale;
                  final double textX = currentVirtualCenterX - (textW / 2.0);

                  final tempNode = originalNode.copyWith(
                    fontSize: newFontSize,
                  );
                  final double calculatedVirtualH = _calculateTextNodeHeight(tempNode, textW);
                  final double dynamicVirtualY = currentVirtualCenterY - (calculatedVirtualH / 2.0);

                  _document!.layers[index] = originalNode.copyWith(
                    fontSize: newFontSize,
                    bounds: NodeBounds(
                      x: textX,
                      y: dynamicVirtualY,
                      width: textW,
                      height: calculatedVirtualH,
                    ),
                    transform: NodeTransform(
                      rotation: rotationDeg,
                      pivot: originalNode.transform.pivot,
                      skew: originalNode.transform.skew,
                      flipX: originalNode.transform.flipX,
                      flipY: originalNode.transform.flipY,
                    ),
                  );
                }
              }
            });
          }
        }
      },
      onResize: (newLeft, newTop, newWidth, newHeight) {
        final SceneNode originalNode = (_document != null)
            ? _document!.layers.firstWhereOrNull((l) => l.id == node.id) ?? node
            : node;
        
        final int index = _document!.layers.indexWhere((l) => l.id == node.id);
        if (index != -1) {
          setState(() {
            // Convert to virtual coordinates
            final double virtualX = transformer.toVirtualX(newLeft);
            final double virtualY = transformer.toVirtualY(newTop);
            final double virtualW = transformer.toVirtualWidth(newWidth);
            final double virtualH = transformer.toVirtualHeight(newHeight);

            if (originalNode is StickerNode) {
              _document!.layers[index] = originalNode.copyWith(
                bounds: NodeBounds(
                  x: virtualX,
                  y: virtualY,
                  width: virtualW,
                  height: virtualH,
                ),
              );
            } else if (originalNode is TextNode) {
              // Recalculate wrapping height for text layers dynamically
              double calculatedVirtualH = virtualH;
              if (!originalNode.id.startsWith('logo') && !originalNode.id.startsWith('signature')) {
                calculatedVirtualH = _calculateTextNodeHeight(originalNode, virtualW);
              }

              _document!.layers[index] = originalNode.copyWith(
                bounds: NodeBounds(
                  x: virtualX,
                  y: virtualY,
                  width: virtualW,
                  height: calculatedVirtualH,
                ),
              );
            }
          });
        }
      },
      onInteractionEnd: () {
        _saveToHistory();
      },
      onCancel: () {
        _deleteLayer(node.id);
      },
      onEdit: () {
        _textFocusNode.requestFocus();
      },
      onDoubleTap: () {
        if (node is TextNode) {
          setState(() {
            _selectedNodeId = node.id;
            _editingTextNodeId = node.id;
            _textController.value = _textController.value.copyWith(
              text: node.text,
              selection: TextSelection.collapsed(offset: node.text.length),
              composing: TextRange.empty,
            );
            _activeTab = 'Text';
          });
          _textFocusNode.requestFocus();
        }
      },
      child: const SizedBox.expand(),
    );
  }

  void _closeActiveTab() {
    setState(() {
      _activeTab = '';
      _selectedNodeId = null;
    });
  }

  Widget _buildDynamicControlsPanel(TextNode? selectedTextNode) {
    if (_activeTab == 'Text') {
      return TextControlsPanel(
        selectedNode: selectedTextNode,
        textController: _textController,
        textFocusNode: _textFocusNode,
        colorPalette: _colorPalette,
        fontFamilies: _fontFamilies,
        onAddNewTextNode: _addNewTextNode,
        onSaveTextEditingState: _saveTextEditingState,
        onUpdateProperty: _updateSelectedTextProperty,
        onColorSelected: _onColorSelected,
        onDismiss: _closeActiveTab,
      );
    } else if (_activeTab == 'Logo') {
      final SceneNode? logoNode =
          _selectedNodeId != null && _selectedNodeId!.startsWith('logo')
          ? _document?.layers.firstWhereOrNull((l) => l.id == _selectedNodeId)
          : _document?.layers.firstWhereOrNull((l) => l.id.startsWith('logo'));
      final bool hasLogo = logoNode != null;
      final String currentLogoName = logoNode != null
          ? (_logoNames[logoNode.id] ?? _pickedLogoName)
          : _pickedLogoName;
      final String currentLogoDimensions = logoNode != null
          ? (_logoDimensions[logoNode.id] ?? _pickedLogoDimensions)
          : _pickedLogoDimensions;

      return LogoControlsPanel(
        hasLogo: hasLogo,
        currentLogoName: currentLogoName,
        currentLogoDimensions: currentLogoDimensions,
        onAddNewLogo: _addNewLogo,
        onReplaceSelectedLogo: _replaceSelectedLogo,
        onDismiss: _closeActiveTab,
      );
    } else if (_activeTab == 'Signature') {
      return SignatureControlsPanel(
        onAddNewSignature: _addNewSignature,
        onSignatureExported: _onSignatureExported,
        onSignatureCleared: _clearSignature,
        initialStrokes: _signatureStrokes,
        initialColor: _currentSignatureColor,
        onDismiss: _closeActiveTab,
      );
    } else if (_activeTab == 'Stickers') {
      return StickersControlsPanel(
        onStickerSelected: _addSticker,
      );
    }
    return const SizedBox.shrink();
  }

  void _clearSignature() {
    setState(() {
      _signatureStrokes.clear();
      final sigNode = _document?.layers.firstWhereOrNull(
        (l) => l.id.startsWith('signature'),
      );
      if (sigNode != null) {
        _document?.layers.removeWhere((l) => l.id == sigNode.id);
        _selectedNodeId = null;
      }
      _saveToHistory();
    });
  }

  void _onSignatureExported(ui.Image img) {
    final String newSigId = 'signature_${DateTime.now().millisecondsSinceEpoch}';
    final double aspect = img.height.toDouble() / img.width.toDouble();

    String? oldSigId =
        _selectedNodeId != null && _selectedNodeId!.startsWith('signature')
        ? _selectedNodeId
        : null;

    if (oldSigId == null) {
      const double width = 100.0;
      final double height = width * aspect;
      final newSigNode = TextNode(
        id: newSigId,
        displayName: 'Signature',
        text: 'Signature',
        fontFamily: 'System',
        fontSize: 14.0,
        color: '#FF000000',
        align: 'center',
        fontWeight: 'normal',
        fontStyle: 'normal',
        decoration: 'none',
        zIndex: _getNextTopZIndex(),
        bounds: NodeBounds(
          x: (_document!.canvas.virtualWidth / 2) - (width / 2),
          y: (_document!.canvas.virtualHeight / 2) - (height / 2) + 40,
          width: width,
          height: height,
        ),
        transform: NodeTransform(rotation: 0.0, pivot: const Offset(0.5, 0.5)),
        state: NodeState(visible: true, locked: false),
        interaction: NodeInteraction(
          selectable: true,
          movable: true,
          editable: true,
        ),
      );
      _document!.layers.add(newSigNode);
    } else {
      final int index = _document!.layers.indexWhere((l) => l.id == oldSigId);
      if (index != -1) {
        final node = _document!.layers[index] as TextNode;
        final double newHeight = node.bounds.width * aspect;
        _document!.layers[index] = node.copyWith(
          id: newSigId,
          bounds: NodeBounds(
            x: node.bounds.x,
            y: node.bounds.y + (node.bounds.height - newHeight) / 2.0,
            width: node.bounds.width,
            height: newHeight,
          ),
        );
      }
    }

    _imagePool[newSigId] = img;
    _signatureNames[newSigId] = 'Drawn Signature';
    _signatureDimensions[newSigId] = 'PNG • ${img.width} × ${img.height} px';

    setState(() {
      _selectedNodeId = newSigId;
      _saveToHistory();
    });
  }

  Future<void> _addSticker(String assetPath) async {
    if (_document == null) return;
    try {
      final isSvg = assetPath.toLowerCase().endsWith('.svg');
      final String stickerId = 'sticker_${DateTime.now().millisecondsSinceEpoch}';
      
      double width = 80.0;
      double height = 80.0;

      if (isSvg) {
        final PictureInfo pictureInfo = await vg.loadPicture(
          SvgAssetLoader(assetPath),
          null,
        );
        _picturePool[stickerId] = pictureInfo.picture;
        width = pictureInfo.size.width > 0 ? pictureInfo.size.width : 80.0;
        height = pictureInfo.size.height > 0 ? pictureInfo.size.height : 80.0;
        if (width > 120.0 || height > 120.0) {
          final aspect = height / width;
          width = 80.0;
          height = width * aspect;
        }
      } else {
        final ui.Image img = await _loadUiImage(assetPath);
        _imagePool[stickerId] = img;
        final double aspect = img.height.toDouble() / img.width.toDouble();
        width = 80.0;
        height = width * aspect;
      }
      
      final stickerNode = StickerNode(
        id: stickerId,
        displayName: 'Sticker',
        assetId: stickerId,
        mediaType: isSvg ? 'svg' : 'image',
        zIndex: _getNextTopZIndex(),
        bounds: NodeBounds(
          x: (_document!.canvas.virtualWidth / 2) - (width / 2),
          y: (_document!.canvas.virtualHeight / 2) - (height / 2),
          width: width,
          height: height,
        ),
        transform: NodeTransform(
          rotation: 0.0,
          pivot: const Offset(0.5, 0.5),
        ),
        state: NodeState(visible: true, locked: false),
        interaction: NodeInteraction(
          selectable: true,
          movable: true,
          editable: true,
        ),
      );

      _document!.assets[stickerId] = SceneAsset(
        type: isSvg ? 'svg' : 'image',
        src: assetPath,
      );

      setState(() {
        _document!.layers.add(stickerNode);
        _selectedNodeId = stickerId;
        _saveToHistory();
      });
    } catch (e) {
      debugPrint("Failed to add sticker: $e");
    }
  }

  Future<void> _addNewLogo() async {
    if (_document == null) return;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      final Uint8List bytes = await File(file.path).readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image uiImage = frame.image;

      final String logoId = 'logo_${DateTime.now().millisecondsSinceEpoch}';
      _imagePool[logoId] = uiImage;

      final String name = file.path.split(Platform.isWindows ? '\\' : '/').last;
      final String dimensions = 'PNG • ${uiImage.width} × ${uiImage.height} px';

      final double width = 80.0;
      final double height = (width / uiImage.width) * uiImage.height;

      final newLogoNode = TextNode(
        id: logoId,
        displayName: 'Logo',
        text: 'Logo',
        fontFamily: 'System',
        fontSize: 14.0,
        color: '#FF000000',
        align: 'center',
        fontWeight: 'normal',
        fontStyle: 'normal',
        decoration: 'none',
        zIndex: _getNextTopZIndex(),
        bounds: NodeBounds(
          x: (_document!.canvas.virtualWidth / 2) - (width / 2),
          y: (_document!.canvas.virtualHeight / 2) - (height / 2),
          width: width,
          height: height,
        ),
        transform: NodeTransform(rotation: 0.0, pivot: const Offset(0.5, 0.5)),
        state: NodeState(visible: true, locked: false),
        interaction: NodeInteraction(
          selectable: true,
          movable: true,
          editable: true,
        ),
      );

      setState(() {
        _logoNames[logoId] = name;
        _logoDimensions[logoId] = dimensions;
        _pickedLogoName = name;
        _pickedLogoDimensions = dimensions;
        _document!.layers.add(newLogoNode);
        _selectedNodeId = logoId;
        _activeTab = 'Logo';
        _updateSelectedNodeTextField();
        _saveToHistory();
      });
    } catch (e) {
      debugPrint("Error adding logo: $e");
    }
  }

  Future<void> _replaceSelectedLogo() async {
    if (_document == null ||
        _selectedNodeId == null ||
        !_selectedNodeId!.startsWith('logo'))
      return;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      final Uint8List bytes = await File(file.path).readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image uiImage = frame.image;

      final String newLogoId = 'logo_${DateTime.now().millisecondsSinceEpoch}';
      _imagePool[newLogoId] = uiImage;

      final String name = file.path.split(Platform.isWindows ? '\\' : '/').last;
      final String dimensions = 'PNG • ${uiImage.width} × ${uiImage.height} px';

      final int index = _document!.layers.indexWhere(
        (l) => l.id == _selectedNodeId,
      );
      if (index != -1) {
        setState(() {
          final originalNode = _document!.layers[index] as TextNode;
          final double width = originalNode.bounds.width;
          final double height = (width / uiImage.width) * uiImage.height;
          _document!.layers[index] = originalNode.copyWith(
            id: newLogoId,
            bounds: NodeBounds(
              x: originalNode.bounds.x,
              y: originalNode.bounds.y,
              width: width,
              height: height,
            ),
          );
          _logoNames[newLogoId] = name;
          _logoDimensions[newLogoId] = dimensions;
          _pickedLogoName = name;
          _pickedLogoDimensions = dimensions;
          _selectedNodeId = newLogoId;
          _saveToHistory();
        });
      }
    } catch (e) {
      debugPrint("Error replacing logo: $e");
    }
  }

  Future<void> _addNewSignature() async {
    if (_document == null) return;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      final Uint8List bytes = await File(file.path).readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image uiImage = frame.image;

      final String sigId = 'signature_${DateTime.now().millisecondsSinceEpoch}';
      _imagePool[sigId] = uiImage;

      final String name = file.path.split(Platform.isWindows ? '\\' : '/').last;
      final String dimensions = 'PNG • ${uiImage.width} × ${uiImage.height} px';

      final double width = 80.0;
      final double height = (width / uiImage.width) * uiImage.height;

      final newSigNode = TextNode(
        id: sigId,
        displayName: 'Signature',
        text: 'Signature',
        fontFamily: 'System',
        fontSize: 14.0,
        color: '#FF000000',
        align: 'center',
        fontWeight: 'normal',
        fontStyle: 'normal',
        decoration: 'none',
        bounds: NodeBounds(
          x: (_document!.canvas.virtualWidth / 2) - (width / 2),
          y: (_document!.canvas.virtualHeight / 2) - (height / 2) + 40,
          width: width,
          height: height,
        ),
        transform: NodeTransform(rotation: 0.0, pivot: const Offset(0.5, 0.5)),
        state: NodeState(visible: true, locked: false),
        interaction: NodeInteraction(
          selectable: true,
          movable: true,
          editable: true,
        ),
      );

      setState(() {
        _signatureNames[sigId] = name;
        _signatureDimensions[sigId] = dimensions;
        _document!.layers.add(newSigNode);
        _selectedNodeId = sigId;
        _activeTab = 'Signature';
        _updateSelectedNodeTextField();
        _saveToHistory();
      });
    } catch (e) {
      debugPrint("Error adding signature: $e");
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        color: Colors.white,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildBottomTab(
              Icons.title,
              'Text',
              isActive: _activeTab == 'Text',
              onTap: () {
                setState(() {
                  if (_activeTab == 'Text') {
                    _activeTab = '';
                    _selectedNodeId = null;
                  } else {
                    _activeTab = 'Text';
                    final node = _document?.layers.firstWhereOrNull(
                      (l) => l.id == _selectedNodeId,
                    );
                    if (node is! TextNode) {
                      _selectedNodeId = null;
                    }
                  }
                });
              },
            ),
            _buildBottomTab(
              Icons.verified_user_outlined,
              'Logo',
              isActive: _activeTab == 'Logo',
              onTap: () {
                setState(() {
                  if (_activeTab == 'Logo') {
                    _activeTab = '';
                    _selectedNodeId = null;
                  } else {
                    _activeTab = 'Logo';
                    final bool hasLastLogo =
                        _lastSelectedLogoId != null &&
                        (_document?.layers.any(
                              (l) => l.id == _lastSelectedLogoId,
                            ) ??
                            false);
                    if (hasLastLogo) {
                      _selectedNodeId = _lastSelectedLogoId;
                    } else {
                      final logoNode = _document?.layers.firstWhereOrNull(
                        (l) => l.id.startsWith('logo'),
                      );
                      _selectedNodeId = logoNode?.id;
                    }
                  }
                });
              },
            ),
            _buildBottomTab(
              Icons.gesture,
              'Signature',
              isActive: _activeTab == 'Signature',
              onTap: () {
                setState(() {
                  if (_activeTab == 'Signature') {
                    _activeTab = '';
                    _selectedNodeId = null;
                  } else {
                    _activeTab = 'Signature';
                    if (_selectedNodeId == null || !_selectedNodeId!.startsWith('signature')) {
                      _selectedNodeId = null;
                    }
                  }
                });
              },
            ),
            _buildBottomTab(
              Icons.emoji_emotions_outlined,
              'Stickers',
              isActive: _activeTab == 'Stickers',
              onTap: () {
                setState(() {
                  if (_activeTab == 'Stickers') {
                    _activeTab = '';
                    _selectedNodeId = null;
                  } else {
                    _activeTab = 'Stickers';
                    if (_selectedNodeId == null || !_selectedNodeId!.startsWith('sticker')) {
                      _selectedNodeId = null;
                    }
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomTab(
    IconData icon,
    String label, {
    required bool isActive,
    VoidCallback? onTap,
  }) {
    final Color col = isActive
        ? const Color(0xFF7C3AED)
        : const Color(0xFF64748B);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: col),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: col,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onBackPress() {
    _showExitConfirmationDialog();
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Save Changes?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Would you like to save your project before leaving?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.offAll(() => const Homepage());
              },
              child: const Text('No', style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSaveNameDialog();
              },
              child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showSaveNameDialog() {
    final int projectCount = Hive.box('saved_projects').length;
    final TextEditingController nameController = TextEditingController(
      text: widget.savedProjectName ?? 'Project ${projectCount + 1}',
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Name Project',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Give your project name so you can find it later.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameController,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 16),
                              ),
                              onChanged: (val) {
                                setDialogState(() {});
                              },
                            ),
                          ),
                          if (nameController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                nameController.clear();
                                setDialogState(() {});
                              },
                              child: const Icon(
                                Icons.close,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE5E7EB),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                Get.offAll(() => const Homepage());
                              },
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4C00C6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                final String name = nameController.text.trim().isEmpty
                                    ? 'Project ${projectCount + 1}'
                                    : nameController.text.trim();
                                
                                // Show loading indicator dialog
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4C00C6)),
                                    ),
                                  ),
                                );

                                String? renderedPath;
                                try {
                                  if (_document != null) {
                                    final double aspectDouble = _document!.canvas.virtualWidth / _document!.canvas.virtualHeight;
                                    renderedPath = await SceneExportService().renderSceneToFile(
                                      doc: _document!,
                                      assetImageLoader: (src) async {
                                        final byteData = await rootBundle.load(src);
                                        final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
                                        final frame = await codec.getNextFrame();
                                        return frame.image;
                                      },
                                      fileImageLoader: (path) async {
                                        final bytes = await File(path).readAsBytes();
                                        final codec = await ui.instantiateImageCodec(bytes);
                                        final frame = await codec.getNextFrame();
                                        return frame.image;
                                      },
                                      aspectDouble: aspectDouble,
                                      editorImagePool: _imagePool,
                                      watermarkEnabled: false,
                                    );
                                  }
                                } catch (e) {
                                  debugPrint("Failed to render preview thumbnail: $e");
                                }

                                final box = Hive.box('saved_projects');
                                final projectData = {
                                  'name': name,
                                  'document': _document?.toJson(),
                                  'layoutPath': widget.layoutPath,
                                  'thumbnailPath': renderedPath,
                                  'updatedAt': DateTime.now().toIso8601String(),
                                };
                                if (widget.savedProjectName != null && widget.savedProjectName != name) {
                                  await box.delete(widget.savedProjectName);
                                }
                                await box.put(name, projectData);
                                
                                if (context.mounted) {
                                  // Pop the loading dialog
                                  Navigator.of(context).pop();
                                  // Pop the project naming dialog
                                  Navigator.of(context).pop();
                                }
                                Get.offAll(() => const Homepage());
                              },
                              child: const Text(
                                'Save name',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class GuidelinePainter extends CustomPainter {
  final bool showHorizontal;
  final bool showVertical;
  final double horizontalY;
  final double verticalX;
  final bool isCenterHorizontal;
  final bool isCenterVertical;
  final bool showGrid;

  GuidelinePainter({
    required this.showHorizontal,
    required this.showVertical,
    required this.horizontalY,
    required this.verticalX,
    required this.isCenterHorizontal,
    required this.isCenterVertical,
    this.showGrid = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint normalPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final Paint centerPaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Rule-of-thirds grid paint — very subtle
    final Paint gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const double dashWidth = 5.0;
    const double dashSpace = 4.0;

    void drawDottedLine(Offset p1, Offset p2, Paint paint) {
      final double totalLength = (p2 - p1).distance;
      if (totalLength <= 0) return;
      final Offset direction = (p2 - p1) / totalLength;
      double currentLength = 0.0;
      while (currentLength < totalLength) {
        final double end = (currentLength + dashWidth).clamp(0.0, totalLength);
        canvas.drawLine(
          p1 + direction * currentLength,
          p1 + direction * end,
          paint,
        );
        currentLength += dashWidth + dashSpace;
      }
    }

    // Draw rule-of-thirds grid (3x3) when interacting
    if (showGrid) {
      final double thirdW = size.width / 3.0;
      final double thirdH = size.height / 3.0;
      // 2 vertical lines
      drawDottedLine(Offset(thirdW, 0), Offset(thirdW, size.height), gridPaint);
      drawDottedLine(Offset(thirdW * 2, 0), Offset(thirdW * 2, size.height), gridPaint);
      // 2 horizontal lines
      drawDottedLine(Offset(0, thirdH), Offset(size.width, thirdH), gridPaint);
      drawDottedLine(Offset(0, thirdH * 2), Offset(size.width, thirdH * 2), gridPaint);
    }

    // Center snap vertical guideline
    if (showVertical && verticalX >= 0 && verticalX <= size.width) {
      final paint = isCenterVertical ? centerPaint : normalPaint;
      drawDottedLine(Offset(verticalX, 0), Offset(verticalX, size.height), paint);
    }

    // Center snap horizontal guideline
    if (showHorizontal && horizontalY >= 0 && horizontalY <= size.height) {
      final paint = isCenterHorizontal ? centerPaint : normalPaint;
      drawDottedLine(Offset(0, horizontalY), Offset(size.width, horizontalY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GuidelinePainter oldDelegate) {
    return oldDelegate.showHorizontal != showHorizontal ||
        oldDelegate.showVertical != showVertical ||
        oldDelegate.horizontalY != horizontalY ||
        oldDelegate.verticalX != verticalX ||
        oldDelegate.isCenterHorizontal != isCenterHorizontal ||
        oldDelegate.isCenterVertical != isCenterVertical ||
        oldDelegate.showGrid != showGrid;
  }
}

