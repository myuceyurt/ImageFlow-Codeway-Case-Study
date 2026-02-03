import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_flow/core/theme/app_theme.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/pages/home/home_controller.dart';
import 'package:image_flow/presentation/widgets/app_background.dart';
import 'package:intl/intl.dart';

const _cardRadius = 22.0;
const _thumbRadius = 18.0;
const _cardColor = Color(0xFF202033);
const _cardBorder = Color(0x14FFFFFF);
const _cardShadows = [
  BoxShadow(
    color: Color(0x33000000),
    blurRadius: 20,
    offset: Offset(0, 12),
  ),
  BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 6,
    offset: Offset(0, 2),
  ),
];
const _faceGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF15B6C), Color(0xFFF47D63)],
);
const _docGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF5C3E72), Color(0xFF384162)],
);
const _fabGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF15B6C), Color(0xFFF1736A)],
);

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        animated: true,
        child: Stack(
          children: [
            const _BlurWarmup(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Text(
                      'ImageFlow',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Obx(() {
                      if (controller.scans.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 60,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No history yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Tap + to process your first image.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(22, 6, 22, 130),
                        itemCount: controller.scans.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final scan = controller.scans[index];
                          return _HistoryItem(
                            scan: scan,
                            onOpen: () async =>
                                controller.navigateToDetail(scan),
                            onDelete: () async => controller.deleteScan(scan),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _GradientFab(onTap: controller.showCaptureOptions),
    );
  }
}

class _BlurWarmup extends StatelessWidget {
  const _BlurWarmup();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.001,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: const SizedBox(width: 1, height: 1),
        ),
      ),
    );
  }
}

class _GradientFab extends StatelessWidget {
  const _GradientFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Material(
              type: MaterialType.circle,
              color: Colors.transparent,
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: const ShapeDecoration(
                  shape: CircleBorder(),
                  gradient: _fabGradient,
                ),
                child: InkResponse(
                  onTap: onTap,
                  containedInkWell: true,
                  highlightShape: BoxShape.circle,
                  child: const Center(
                    child: Icon(Icons.add, color: Colors.white, size: 32),
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

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.scan,
    required this.onOpen,
    required this.onDelete,
  });

  final ScanModel scan;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title =
        scan.type == ScanType.face ? 'Face Processed' : 'Document Scan';
    final dateText = DateFormat.yMMMd().format(scan.date);
    final thumbPath = scan.thumbnailPath ?? scan.resultFilePath;
    final thumbGradient =
        scan.type == ScanType.face ? _faceGradient : _docGradient;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(color: _cardBorder),
          boxShadow: _cardShadows,
        ),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(_cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                _Thumbnail(
                  path: thumbPath,
                  gradient: thumbGradient,
                  fallbackIcon: scan.type == ScanType.face
                      ? Icons.face_rounded
                      : Icons.picture_as_pdf_rounded,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dateText,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.path,
    required this.fallbackIcon,
    required this.gradient,
  });

  final String path;
  final IconData fallbackIcon;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final isPdf = path.toLowerCase().endsWith('.pdf');
    return Container(
      width: 60,
      height: 60,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(_thumbRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_thumbRadius - 2),
        child: ColoredBox(
          color: AppTheme.bgSecondary,
          child: isPdf
              ? Icon(
                  fallbackIcon,
                  color: AppTheme.textSecondary,
                )
              : Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(fallbackIcon, color: AppTheme.textSecondary),
                ),
        ),
      ),
    );
  }
}
