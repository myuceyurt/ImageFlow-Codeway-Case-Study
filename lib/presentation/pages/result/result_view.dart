import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_flow/core/theme/app_theme.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/pages/result/result_controller.dart';

class ResultView extends GetView<ResultController> {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Result'),
        backgroundColor: AppTheme.bgSecondary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: controller.goBack,
        ),
      ),
      body: GetBuilder<ResultController>(
        builder: (_) {
          if (controller.errorMessage != null) {
            return Center(
              child: Text(
                controller.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          
          if (controller.isLoading) {
             return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: controller.scanType == ScanType.face
                      ? _buildFaceCompareView()
                      : _buildDocumentView(),
                ),
              ),
              _buildBottomBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFaceCompareView() {
    return _SwipeCompareWidget(
      originalPath: controller.originalImagePath,
      processedPath: controller.processedImagePath,
    );
  }
  
  Widget _buildDocumentView() {
    return Image.file(
      File(controller.processedImagePath),
      fit: BoxFit.contain,
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppTheme.bgSecondary,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.scanType == ScanType.document)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Your document has been enhanced and is ready to save as '
                  'PDF.',
                  textAlign: TextAlign.center,
                  style: Get.textTheme.bodyMedium,
                ),
              ),
              
             if (controller.scanType == ScanType.face)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Drag the slider to compare original vs processed.',
                  textAlign: TextAlign.center,
                  style: Get.textTheme.bodyMedium,
                ),
              ),

            ElevatedButton(
              onPressed: controller.saveResult,
               style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tawnyOwl,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                controller.scanType == ScanType.document
                    ? 'Save as PDF'
                    : 'Save to Gallery',
                 style: const TextStyle(
                   fontSize: 16,
                   fontWeight: FontWeight.bold,
                   color: Colors.white,
                 ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeCompareWidget extends StatefulWidget {
  const _SwipeCompareWidget({
    required this.originalPath,
    required this.processedPath,
  });

  final String originalPath;
  final String processedPath;

  @override
  State<_SwipeCompareWidget> createState() => _SwipeCompareWidgetState();
}

class _SwipeCompareWidgetState extends State<_SwipeCompareWidget> {
  double _splitPosition = 0.5; // 0.0 to 1.0

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return Stack(
          children: [
            // Processed Image (Values 0.0 to split) - Left Side? Or Right? 
            // Typically "Before" is Left, "After" is Right.
            // Let's say Original is Background (Left), Processed is Foreground (Right) or vice versa.
            // Requirement: "Original vs B&W Face Composite".
            // Let's put Original on Left, Processed on Right.
            
            // Bottom Layer: Processed Image (Full width, but revealed by slider)
            Positioned.fill(
              child: Image.file(
                File(widget.processedPath),
                fit: BoxFit.contain,
              ),
            ),
            
            // Top Layer: Original Image (Clipped)
            Positioned.fill(
              child: ClipRect(
                clipper: _SplitClipper(_splitPosition),
                child: Image.file(
                  File(widget.originalPath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            // Slider Handle
            Positioned(
              left: width * _splitPosition - 15, // Center the 30px handle
              top: 0,
              bottom: 0,
              width: 30,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _splitPosition += details.delta.dx / width;
                    _splitPosition = _splitPosition.clamp(0.0, 1.0);
                  });
                },
                child: Container(
                  color: Colors.transparent, // Hit test target
                  child: Center(
                    child: Container(
                      width: 4,
                      color: Colors.white,
                      child: Center(
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                               BoxShadow(
                                color: Colors.black26, 
                                blurRadius: 4,
                                offset: Offset(0, 2),
                               ),
                            ],
                          ),
                          child: const Icon(
                            Icons.compare_arrows, 
                            size: 16, 
                            color: AppTheme.tawnyOwl,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Labels (Optional but helpful)
            Positioned(
              bottom: 10,
              left: 10,
              child: Opacity(
                 opacity: _splitPosition > 0.1 ? 1.0 : 0.0,
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(
                     color: Colors.black54,
                     borderRadius: BorderRadius.circular(4),
                   ),
                   child: const Text('Original', style: TextStyle(color: Colors.white, fontSize: 12)),
                 ),
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Opacity(
                 opacity: _splitPosition < 0.9 ? 1.0 : 0.0,
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(
                     color: Colors.black54,
                     borderRadius: BorderRadius.circular(4),
                   ),
                   child: const Text('Processed', style: TextStyle(color: Colors.white, fontSize: 12)),
                 ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SplitClipper extends CustomClipper<Rect> {
  _SplitClipper(this.splitPosition);

  final double splitPosition;

  @override
  Rect getClip(Size size) {
    // Clip the left part (Original)
    return Rect.fromLTWH(0, 0, size.width * splitPosition, size.height);
  }

  @override
  bool shouldReclip(_SplitClipper oldClipper) {
    return oldClipper.splitPosition != splitPosition;
  }
}
