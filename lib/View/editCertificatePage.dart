// ignore_for_file: deprecated_member_use, unused_local_variable
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../rendering_engine/models/scene_node.dart';
import '../rendering_engine/canvas/viewport_transformer.dart';
import '../rendering_engine/models/sticker_model.dart';
import '../rendering_engine/widgets/interactive_overlay.dart';

import 'widgets/realtime_certificate_painter.dart';
import 'widgets/text_controls_panel.dart';
import 'widgets/logo_controls_panel.dart';
import 'widgets/signature_controls_panel.dart';

class EditCertificatePage extends StatefulWidget {
  final String layoutPath;

  const EditCertificatePage({
    super.key,
    required this.layoutPath,
  });

  @override
  State<EditCertificatePage> createState() => _EditCertificatePageState();
}

class _EditCertificatePageState extends State<EditCertificatePage> {
  SceneDocument? _document;
  bool _isLoading = true;
  String? _selectedNodeId;
  String _activeTab = 'Text';
  double _zoomScale = 1.0;
  String? _lastSelectedLogoId;

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
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadLayoutAndAssets() async {
    try {
      final String jsonString = await rootBundle.loadString(widget.layoutPath);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final doc = SceneDocument.fromJson(jsonMap);

      // Preload images from assets
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

  void _onTextChanged() {
    if (_document == null || _selectedNodeId == null) return;
    final int index = _document!.layers.indexWhere((l) => l.id == _selectedNodeId);
    if (index == -1) return;

    final node = _document!.layers[index];
    if (node is TextNode && node.text != _textController.text) {
      final updatedNode = node.copyWith(text: _textController.text);
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
    final node = _document!.layers.firstWhereOrNull((l) => l.id == _selectedNodeId);
    if (node is TextNode) {
      _textController.text = node.text;
    } else {
      _textController.text = "";
    }
  }

  void _selectNode(String? id) {
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
        } else if (id.startsWith('signature') || (node?.id.startsWith('signature') ?? false)) {
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
      transform: NodeTransform(
        rotation: 0.0,
        pivot: const Offset(0.5, 0.5),
      ),
      state: NodeState(visible: true, locked: false),
      interaction: NodeInteraction(selectable: true, movable: true, editable: true),
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
  }) {
    if (_document == null || _selectedNodeId == null) return;
    final int index = _document!.layers.indexWhere((l) => l.id == _selectedNodeId);
    if (index == -1) return;

    final node = _document!.layers[index];
    if (node is TextNode) {
      NodeBounds updatedBounds = node.bounds;
      if (fontSize != null && node.fontSize > 0) {
        final double scaleFactor = fontSize / node.fontSize;
        final double newWidth = node.bounds.width * scaleFactor;
        final double newHeight = node.bounds.height * scaleFactor;
        
        final double centerX = node.bounds.x + (node.bounds.width / 2.0);
        final double centerY = node.bounds.y + (node.bounds.height / 2.0);
        final double newX = centerX - (newWidth / 2.0);
        final double newY = centerY - (newHeight / 2.0);
        
        updatedBounds = NodeBounds(
          x: newX,
          y: newY,
          width: newWidth,
          height: newHeight,
        );
      }

      final updatedNode = node.copyWith(
        fontFamily: fontFamily ?? node.fontFamily,
        fontSize: fontSize ?? node.fontSize,
        color: color ?? node.color,
        fontWeight: fontWeight ?? node.fontWeight,
        fontStyle: fontStyle ?? node.fontStyle,
        decoration: decoration ?? node.decoration,
        bounds: updatedBounds,
      );

      setState(() {
        _document!.layers[index] = updatedNode;
      });
    }
  }



  void _onColorSelected(String hex, Color color) {
    final bool alreadyExists = _colorPalette.any((item) => item['hex'].toString().toUpperCase() == hex.toUpperCase());
    if (!alreadyExists) {
      setState(() {
        _colorPalette.add({'color': color, 'hex': hex});
      });
    }
    _updateSelectedTextProperty(color: hex);
    _saveToHistory();
  }



  void _detectHitTest(Offset localTapPos, Size paintSize) {
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

      if (node.transform.rotation != 0.0) {
        final center = rect.center;
        final angleRad = -node.transform.rotation * pi / 180.0;
        
        final rotatedTapX = cos(angleRad) * (localTapPos.dx - center.dx) -
            sin(angleRad) * (localTapPos.dy - center.dy) +
            center.dx;
        final rotatedTapY = sin(angleRad) * (localTapPos.dx - center.dx) +
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final TextNode? selectedNode = (_selectedNodeId != null && _document != null)
        ? _document!.layers.firstWhereOrNull((l) => l.id == _selectedNodeId) as TextNode?
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Get.back(),
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
          IconButton(
            icon: Icon(
              Icons.undo,
              color: _historyIndex > 0 ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
            ),
            onPressed: _historyIndex > 0 ? _undo : null,
          ),
          IconButton(
            icon: Icon(
              Icons.redo,
              color: _historyIndex < _history.length - 1 ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
            ),
            onPressed: _historyIndex < _history.length - 1 ? _redo : null,
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: ElevatedButton(
              onPressed: () {
                Get.back(result: _document);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B21B6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'Save',
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
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double canvasRatio =
                                _document!.canvas.virtualWidth / _document!.canvas.virtualHeight;

                            double targetW = constraints.maxWidth * _zoomScale;
                            double targetH = (constraints.maxWidth / canvasRatio) * _zoomScale;

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

                            return Center(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Container(
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
                                            _detectHitTest(details.localPosition, canvasPaintSize);
                                          },
                                          child: CustomPaint(
                                            size: canvasPaintSize,
                                            painter: RealtimeCertificatePainter(
                                              document: _document!,
                                              loadedImages: _imagePool,
                                              selectedNodeId: _selectedNodeId,
                                            ),
                                          ),
                                        ),
                                        if (selectedNode != null) ...[
                                          _buildSelectedOverlay(selectedNode, transformer, canvasPaintSize),
                                        ],
                                      ],
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
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              icon: const Icon(Icons.remove, size: 20, color: Color(0xFF64748B)),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                setState(() {
                                  _zoomScale = (_zoomScale - 0.25).clamp(0.5, 2.0);
                                });
                              },
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(_zoomScale * 100).round()}%',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20, color: Color(0xFF64748B)),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                setState(() {
                                  _zoomScale = (_zoomScale + 0.25).clamp(0.5, 2.0);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _buildDynamicControlsPanel(selectedNode),
                    ),
                    _buildBottomNavigationBar(),
                  ],
                ),
    );
  }

  Widget _buildSelectedOverlay(TextNode node, ViewportTransformer transformer, Size paintSize) {
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

    return InteractiveOverlay(
      model: stickerModel,
      boundWidth: paintSize.width,
      boundHeight: paintSize.height,
      width: sw,
      height: sh,
      onUpdate: () {
        final double finalScale = stickerModel.scale;
        
        final double virtualW = transformer.toVirtualWidth(sw * finalScale);
        final double virtualH = transformer.toVirtualHeight(sh * finalScale);
        
        // Calculate center of original bounds in virtual coordinates
        final double initialVirtualCenterX = node.bounds.x + (node.bounds.width / 2.0);
        final double initialVirtualCenterY = node.bounds.y + (node.bounds.height / 2.0);
        
        // Calculate position drag offset (if any)
        final double moveDxVirtual = transformer.toVirtualWidth(stickerModel.left - sx);
        final double moveDyVirtual = transformer.toVirtualHeight(stickerModel.top - sy);
        
        final double currentVirtualCenterX = initialVirtualCenterX + moveDxVirtual;
        final double currentVirtualCenterY = initialVirtualCenterY + moveDyVirtual;
        
        // Keep center fixed while scaling
        final double newVirtualX = currentVirtualCenterX - (virtualW / 2.0);
        final double newVirtualY = currentVirtualCenterY - (virtualH / 2.0);
        
        final double rotationDeg = stickerModel.angle * 180.0 / pi;

        if (_document != null) {
          final int index = _document!.layers.indexWhere((l) => l.id == node.id);
          if (index != -1) {
            setState(() {
              final originalNode = _document!.layers[index] as TextNode;
              final double newFontSize = (originalNode.fontSize * finalScale).clamp(6.0, 72.0);
              _document!.layers[index] = originalNode.copyWith(
                fontSize: newFontSize,
                bounds: NodeBounds(
                  x: newVirtualX,
                  y: newVirtualY,
                  width: virtualW,
                  height: virtualH,
                ),
                transform: NodeTransform(
                  rotation: rotationDeg,
                  pivot: originalNode.transform.pivot,
                  skew: originalNode.transform.skew,
                  flipX: originalNode.transform.flipX,
                  flipY: originalNode.transform.flipY,
                ),
              );
            });
          }
        }
      },
      onCancel: () {
        _deleteLayer(node.id);
      },
      onEdit: () {
        _textFocusNode.requestFocus();
      },
      child: const SizedBox.expand(),
    );
  }

  Widget _buildDynamicControlsPanel(TextNode? selectedTextNode) {
    if (_activeTab == 'Text') {
      if (selectedTextNode != null) {
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
        );
      }
      return const SizedBox.shrink();
    } else if (_activeTab == 'Logo') {
      final SceneNode? logoNode = _selectedNodeId != null && _selectedNodeId!.startsWith('logo')
          ? _document?.layers.firstWhereOrNull((l) => l.id == _selectedNodeId)
          : _document?.layers.firstWhereOrNull((l) => l.id.startsWith('logo'));
      final bool hasLogo = logoNode != null;
      final String currentLogoName = logoNode != null ? (_logoNames[logoNode.id] ?? _pickedLogoName) : _pickedLogoName;
      final String currentLogoDimensions = logoNode != null ? (_logoDimensions[logoNode.id] ?? _pickedLogoDimensions) : _pickedLogoDimensions;

      return LogoControlsPanel(
        hasLogo: hasLogo,
        currentLogoName: currentLogoName,
        currentLogoDimensions: currentLogoDimensions,
        onAddNewLogo: _addNewLogo,
        onReplaceSelectedLogo: _replaceSelectedLogo,
      );
    } else if (_activeTab == 'Signature') {
      return SignatureControlsPanel(
        onAddNewSignature: _addNewSignature,
        onSignatureExported: _onSignatureExported,
        onSignatureCleared: _clearSignature,
        initialStrokes: _signatureStrokes,
        initialColor: _currentSignatureColor,
      );
    }
    return const SizedBox.shrink();
  }

  void _clearSignature() {
    setState(() {
      _signatureStrokes.clear();
      final sigNode = _document?.layers.firstWhereOrNull((l) => l.id.startsWith('signature'));
      if (sigNode != null) {
        _document?.layers.removeWhere((l) => l.id == sigNode.id);
        _selectedNodeId = null;
      }
      _saveToHistory();
    });
  }

  void _onSignatureExported(ui.Image img) {
    String? sigId = _selectedNodeId != null && _selectedNodeId!.startsWith('signature')
        ? _selectedNodeId
        : _document!.layers.firstWhereOrNull((l) => l.id.startsWith('signature'))?.id;

    if (sigId == null) {
      sigId = 'signature_${DateTime.now().millisecondsSinceEpoch}';
      const double padW = 320.0;
      const double padH = 160.0;
      const double width = 100.0;
      final double height = (width / padW) * padH;
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
        transform: NodeTransform(
          rotation: 0.0,
          pivot: const Offset(0.5, 0.5),
        ),
        state: NodeState(visible: true, locked: false),
        interaction: NodeInteraction(selectable: true, movable: true, editable: true),
      );
      _document!.layers.add(newSigNode);
    }

    _imagePool[sigId] = img;
    _signatureNames[sigId] = 'Drawn Signature';
    _signatureDimensions[sigId] = 'PNG • ${img.width} × ${img.height} px';

    setState(() {
      _selectedNodeId = sigId;
      _saveToHistory();
    });
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
        interaction: NodeInteraction(selectable: true, movable: true, editable: true),
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
    if (_document == null || _selectedNodeId == null || !_selectedNodeId!.startsWith('logo')) return;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      final Uint8List bytes = await File(file.path).readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image uiImage = frame.image;

      _imagePool[_selectedNodeId!] = uiImage;

      final String name = file.path.split(Platform.isWindows ? '\\' : '/').last;
      final String dimensions = 'PNG • ${uiImage.width} × ${uiImage.height} px';

      final int index = _document!.layers.indexWhere((l) => l.id == _selectedNodeId);
      if (index != -1) {
        setState(() {
          final originalNode = _document!.layers[index] as TextNode;
          final double width = originalNode.bounds.width;
          final double height = (width / uiImage.width) * uiImage.height;
          _document!.layers[index] = originalNode.copyWith(
            bounds: NodeBounds(
              x: originalNode.bounds.x,
              y: originalNode.bounds.y,
              width: width,
              height: height,
            ),
          );
          _logoNames[_selectedNodeId!] = name;
          _logoDimensions[_selectedNodeId!] = dimensions;
          _pickedLogoName = name;
          _pickedLogoDimensions = dimensions;
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
        transform: NodeTransform(
          rotation: 0.0,
          pivot: const Offset(0.5, 0.5),
        ),
        state: NodeState(visible: true, locked: false),
        interaction: NodeInteraction(selectable: true, movable: true, editable: true),
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
                  _activeTab = 'Text';
                  final node = _document?.layers.firstWhereOrNull((l) => l.id == _selectedNodeId);
                  if (node is! TextNode) {
                    _selectedNodeId = null;
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
                  _activeTab = 'Logo';
                  final bool hasLastLogo = _lastSelectedLogoId != null &&
                      (_document?.layers.any((l) => l.id == _lastSelectedLogoId) ?? false);
                  if (hasLastLogo) {
                    _selectedNodeId = _lastSelectedLogoId;
                  } else {
                    final logoNode = _document?.layers.firstWhereOrNull((l) => l.id.startsWith('logo'));
                    _selectedNodeId = logoNode?.id;
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
                  _activeTab = 'Signature';
                  final sigNode = _document?.layers.firstWhereOrNull((l) => l.id.startsWith('signature'));
                  _selectedNodeId = sigNode?.id;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomTab(IconData icon, String label, {required bool isActive, VoidCallback? onTap}) {
    final Color col = isActive ? const Color(0xFF7C3AED) : const Color(0xFF64748B);
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
}


