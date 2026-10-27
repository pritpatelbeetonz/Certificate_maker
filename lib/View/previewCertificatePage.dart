import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../rendering_engine/models/scene_node.dart';
import '../rendering_engine/export/scene_export_service.dart';
import 'package:hive/hive.dart';
import 'HomePage.dart';
import '../Services/fetch_data_from_server_service.dart';
import 'fullScreenViewerPage.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../for_ads/ads/ads_variable.dart';
import '../for_ads/ads/ads_splash_utils.dart';

class PreviewCertificatePage extends StatefulWidget {
  final SceneDocument document;
  final Map<String, ui.Image> imagePool;
  final Map<String, ui.Picture>? picturePool;
  final String layoutPath;
  final String? savedProjectName;

  const PreviewCertificatePage({
    super.key,
    required this.document,
    required this.imagePool,
    this.picturePool,
    required this.layoutPath,
    this.savedProjectName,
  });

  @override
  State<PreviewCertificatePage> createState() => _PreviewCertificatePageState();
}

class _PreviewCertificatePageState extends State<PreviewCertificatePage> {
  bool _isRendering = true;
  String? _renderedImagePath;
  bool _hasExported = false;

  @override
  void initState() {
    super.initState();
    _renderPreview();
  }

  Future<void> _renderPreview() async {
    try {
      final double aspectDouble =
          widget.document.canvas.virtualWidth / widget.document.canvas.virtualHeight;
      final path = await SceneExportService().renderSceneToFile(
        doc: widget.document,
        assetImageLoader: (src) async {
          return await FetchDataFromServerServices.loadUiImage(src);
        },
        fileImageLoader: (path) async {
          final bytes = await File(path).readAsBytes();
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          return frame.image;
        },
        aspectDouble: aspectDouble,
        editorImagePool: widget.imagePool,
        watermarkEnabled: false,
      );
      setState(() {
        _renderedImagePath = path;
        _isRendering = false;
      });

      // Ask for a review once the user can see their finished certificate (once per install).
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) checkAndShowInAppReview('preview_screen_review');
      });
    } catch (e) {
      debugPrint("Error rendering certificate: $e");
      setState(() {
        _isRendering = false;
      });
    }
  }

  void _showSaveNameDialog() {
    final TextEditingController nameController = TextEditingController(
      text: 'Certificate_Design',
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
                                final String pdfName = nameController.text.trim().isEmpty
                                    ? 'Certificate_Design'
                                    : nameController.text.trim();
                                
                                Navigator.of(context).pop(); // pop naming dialog
                                _exportToPdf(pdfName);
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

  Future<void> _exportToPdf(String pdfFileName) async {
    if (_renderedImagePath == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4C00C6)),
        ),
      ),
    );

    try {
      final pdf = pw.Document();
      final image = pw.MemoryImage(
        File(_renderedImagePath!).readAsBytesSync(),
      );


      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            image.width!.toDouble(),
            image.height!.toDouble(),
          ),
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Image(image, fit: pw.BoxFit.fill);
          },
        ),
      );

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        throw Exception("Could not find user storage directory.");
      }

      // Check if file already exists, and increment name to avoid overwriting
      String finalPath = '${directory.path}/$pdfFileName.pdf';
      int count = 1;
      while (await File(finalPath).exists()) {
        finalPath = '${directory.path}/$pdfFileName ($count).pdf';
        count++;
      }

      final file = File(finalPath);
      await file.writeAsBytes(await pdf.save());
      _hasExported = true;

      if (mounted) {
        Navigator.of(context).pop(); // pop loader
        _showExportSuccessModal(file);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // pop loader
        Get.snackbar(
          'Error',
          'Failed to export PDF: $e',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    }
  }

  void _showExportSuccessModal(File file) {
    final String fileName = file.path.split('/').last;
    final String locationHint = Platform.isIOS
        ? 'Tap "Share / Save" to store in Files, iCloud, or send'
        : 'Saved to Downloads folder';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'PDF Saved Successfully!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                fileName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4C00C6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                locationHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          final result = await OpenFilex.open(file.path);
                          if (result.type != ResultType.done) {
                            Get.snackbar(
                              'Error',
                              'Could not open PDF file: ${result.message}',
                              backgroundColor: Colors.redAccent,
                              colorText: Colors.white,
                            );
                          }
                        } catch (e) {
                          Get.snackbar(
                            'Error',
                            'No compatible PDF viewer found: $e',
                            backgroundColor: Colors.redAccent,
                            colorText: Colors.white,
                          );
                        }
                      },
                      icon: const Icon(Icons.visibility_outlined, color: Color(0xFF0F172A), size: 20),
                      label: const Text(
                        'View PDF',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C00C6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final RenderBox? box = ctx.findRenderObject() as RenderBox?;
                        final Rect? origin = box != null
                            ? box.localToGlobal(Offset.zero) & box.size
                            : null;
                        await Share.shareXFiles(
                          [XFile(file.path)],
                          text: fileName,
                          sharePositionOrigin: origin,
                        );
                      },
                      icon: const Icon(Icons.ios_share, color: Colors.white, size: 20),
                      label: const Text(
                        'Share / Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProject(String name) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4C00C6)),
        ),
      ),
    );

    try {
      final box = Hive.box('saved_projects');
      final projectData = {
        'name': name,
        'document': widget.document.toJson(),
        'layoutPath': widget.layoutPath,
        'thumbnailPath': _renderedImagePath,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (widget.savedProjectName != null && widget.savedProjectName != name) {
        await box.delete(widget.savedProjectName);
      }
      await box.put(name, projectData);
    } catch (e) {
      debugPrint("Failed to save project: $e");
    } finally {
      if (mounted) {
        Navigator.of(context).pop(); // pop loader
      }
    }
  }

  void _showSaveProjectNameDialog() {
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
                borderRadius: BorderRadius.circular(16),
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Give your project name so you can find it later.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontFamily: 'Inter',
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
                                fontFamily: 'Inter',
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
                                color: Color(0xFFCBD5E1),
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
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final String name = nameController.text.trim().isEmpty
                                  ? 'Project ${projectCount + 1}'
                                  : nameController.text.trim();
                              
                              Navigator.of(context).pop(); // pop dialog
                              await _saveProject(name);
                              Get.offAll(() => const Homepage());
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4200AD),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Save name',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter',
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

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            'Unsaved Changes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF0F172A),
              fontFamily: 'Inter',
            ),
          ),
          content: const Text(
            'Save your certificate before leaving the editor?',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontFamily: 'Inter',
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      Get.offAll(() => const Homepage());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Don’t Save',
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      _showSaveProjectNameDialog();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4200AD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
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

  void _onBackPress() async {
    if (_hasExported) {
      final String name = widget.savedProjectName ?? () {
        final int projectCount = Hive.box('saved_projects').length;
        return 'Project ${projectCount + 1}';
      }();
      await _saveProject(name);
      Get.offAll(() => const Homepage());
    } else {
      _showExitConfirmationDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: const Color(0xFFF9FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
              onPressed: () {
                AdsVariable.onShowAds(context, onComplete: () {
                  _onBackPress();
                });
              },
            ),
            title: const Text(
              'Preview Certificate',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: [
              GestureDetector(
                child: const Icon(Icons.fullscreen, color: Color(0xFF0F172A)),
                onTap: () async {
                  await SystemChrome.setPreferredOrientations([
                    DeviceOrientation.landscapeLeft,
                    DeviceOrientation.landscapeRight,
                  ]);
                  await Get.to(() => FullScreenViewerPage(
                        document: widget.document,
                        imagePool: widget.imagePool,
                        picturePool: widget.picturePool ?? const {},
                      ));
                  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                  await SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                  ]);
                  setState(() {});
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
        body: _isRendering
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4C00C6))))
            : _renderedImagePath == null
                ? const Center(child: Text("Failed to render preview"))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        // Certificate Preview Card
                        Expanded(
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  File(_renderedImagePath!),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Bottom actions
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 5.w),
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE2E8F0),
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => Get.back(),
                                    icon: const Icon(Icons.edit_outlined, color: Colors.black),
                                    label: const Text(
                                      'Edit',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4C00C6),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: _showSaveNameDialog,
                                    icon: const Icon(Icons.save_outlined, color: Colors.white),
                                    label: const Text(
                                      'Save to PDF',
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
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 22),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
