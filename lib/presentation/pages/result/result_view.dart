import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_flow/core/theme/app_theme.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/pages/result/result_controller.dart';
import 'package:image_flow/presentation/widgets/app_background.dart';
import 'package:image_flow/presentation/widgets/gradient_button.dart';

class ResultView extends GetView<ResultController> {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final title = controller.scanType == ScanType.face
        ? 'Face Result'
        : 'PDF Created';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
            child: GetBuilder<ResultController>(
              builder: (_) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(title: title, onBack: controller.goBack),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Center(
                        child: controller.errorMessage != null
                            ? Text(
                                controller.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              )
                            : controller.scanType == ScanType.face
                                ? _FaceCompare(
                                    originalPath: controller.originalImagePath,
                                    processedPath: controller.resultFilePath,
                                  )
                                : _DocumentResult(
                                    filePath: controller.resultFilePath,
                                  ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GradientButton(
                      label: controller.scanType == ScanType.face
                          ? 'Done'
                          : 'Open PDF',
                      icon: controller.scanType == ScanType.face
                          ? null
                          : Icons.open_in_new_rounded,
                      isLoading: controller.isLoading,
                      onPressed: controller.errorMessage != null
                          ? null
                          : controller.scanType == ScanType.face
                              ? controller.complete
                              : controller.openPdf,
                    ),
                    if (controller.scanType == ScanType.document)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TextButton(
                          onPressed: controller.isLoading ||
                                  controller.errorMessage != null
                              ? null
                              : controller.complete,
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _FaceCompare extends StatelessWidget {
  const _FaceCompare({
    required this.originalPath,
    required this.processedPath,
  });

  final String originalPath;
  final String processedPath;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PreviewPanel(label: 'Before', imagePath: originalPath),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _PreviewPanel(label: 'After', imagePath: processedPath),
        ),
      ],
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.label, required this.imagePath});

  final String label;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 14),
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: AppTheme.bgSecondary,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: AppTheme.textSecondary,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentResult extends StatelessWidget {
  const _DocumentResult({required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    final name = File(filePath).uri.pathSegments.last;
    final title = name.toLowerCase().endsWith('.pdf')
        ? name.substring(0, name.length - 4)
        : name;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 132,
          height: 172,
          decoration: BoxDecoration(
            color: AppTheme.bgElevated.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.greatHornedOwl.withValues(alpha: 0.8),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              'PDF',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.greatHornedOwl,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}
