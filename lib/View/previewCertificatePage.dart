import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../rendering_engine/models/scene_node.dart';
import '../rendering_engine/export/scene_export_service.dart';
import 'package:open_filex/open_filex.dart';

class PreviewCertificatePage extends StatefulWidget {
  final SceneDocument document;
  final Map<String, ui.Image> imagePool;
  final String layoutPath;

  const PreviewCertificatePage({
    super.key,
    required this.document,
    required this.imagePool,
    required this.layoutPath,
  });

  @override
  State<PreviewCertificatePage> createState() => _PreviewCertificatePageState();
}

class _PreviewCertificatePageState extends State<PreviewCertificatePage> {
  bool _isRendering = true;
  String? _renderedImagePath;

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
        editorImagePool: widget.imagePool,
        watermarkEnabled: false,
      );
      setState(() {
        _renderedImagePath = path;
        _isRendering = false;
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

      if (mounted) {
        Navigator.of(context).pop(); // pop loader
        
        Get.snackbar(
          '✓ PDF saved successfully',
          'Location: ${file.path}',
          duration: const Duration(seconds: 8),
          mainButton: TextButton(
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
            child: const Text(
              'VIEW',
              style: TextStyle(
                color: Colors.yellowAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          backgroundColor: const Color(0xFF1E293B),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
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

  @override
  Widget build(BuildContext context) {
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
          'Preview Certificate',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isRendering
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4C00C6))))
          : _renderedImagePath == null
              ? const Center(child: Text("Failed to render preview"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Certificate Preview Card
                      Container(
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
                      const SizedBox(height: 24),

                      // Capture Details Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Capture Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              icon: Icons.assignment_outlined,
                              label: 'Type',
                              value: 'Achievement',
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              icon: Icons.brush_outlined,
                              label: 'Style',
                              value: 'Morden',
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              icon: Icons.palette_outlined,
                              label: 'Color Theme',
                              value: 'Purple',
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              icon: Icons.crop_rotate_outlined,
                              label: 'Orientation',
                              value: 'Landscape',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Bottom actions
                      Row(
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
                      const SizedBox(height: 16),
                    ],
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
