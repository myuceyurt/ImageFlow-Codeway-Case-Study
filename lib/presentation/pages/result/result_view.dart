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
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Text(
                controller.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (controller.processedImagePath == null) {
             return const Center(child: Text('No image processed'));
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
    return GestureDetector(
      onLongPressStart: (_) {
      },
      child: _CompareWidget(
        originalPath: controller.originalImagePath!,
        processedPath: controller.processedImagePath!,
      ),
    );
  }
  
  Widget _buildDocumentView() {
    return Image.file(
      File(controller.processedImagePath!),
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
                  'Press and hold image to compare with original.',
                  textAlign: TextAlign.center,
                  style: Get.textTheme.bodyMedium,
                ),
              ),

            ElevatedButton(
              onPressed: controller.saveResult,
              child: Text(
                controller.scanType == ScanType.document
                    ? 'Save as PDF'
                    : 'Save to Gallery',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareWidget extends StatefulWidget {
  const _CompareWidget({
    required this.originalPath,
    required this.processedPath,
  });

  final String originalPath;
  final String processedPath;

  @override
  State<_CompareWidget> createState() => _CompareWidgetState();
}

class _CompareWidgetState extends State<_CompareWidget> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => setState(() => _showOriginal = true),
      onLongPressEnd: (_) => setState(() => _showOriginal = false),
      child: Image.file(
        File(_showOriginal ? widget.originalPath : widget.processedPath),
        fit: BoxFit.contain,
      ),
    );
  }
}
