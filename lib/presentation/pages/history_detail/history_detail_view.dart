import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_flow/core/theme/app_theme.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/pages/history_detail/history_detail_controller.dart';
import 'package:image_flow/presentation/widgets/app_background.dart';
import 'package:image_flow/presentation/widgets/gradient_button.dart';
import 'package:image_flow/presentation/widgets/looping_gradient_progress_bar.dart';
import 'package:intl/intl.dart';

class HistoryDetailView extends GetView<HistoryDetailController> {
  const HistoryDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final title =
        controller.scan.type == ScanType.face ? 'Face Scan' : 'Document';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back<void>(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: controller.shareFile,
                      icon: const Icon(
                        Icons.share_rounded,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: controller.scan.type == ScanType.face
                      ? _BeforeAfterSlider(
                          originalPath: controller.scan.originalFilePath,
                          processedPath: controller.scan.resultFilePath,
                        )
                      : _PdfPreview(
                          title: controller.scan.resultFilePath
                              .split('/')
                              .last,
                          onOpen: controller.openFile,
                        ),
                ),
                const SizedBox(height: 18),
                _InfoPanel(scan: controller.scan),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    Get.dialog<void>(
       AlertDialog(
         title: const Text('Delete Scan'),
         content: const Text(
           'Are you sure you want to delete this scan? '
           'This action cannot be undone.',
         ),
         actions: [
           TextButton(
             onPressed: () => Get.back<void>(),
             child: const Text('Cancel'),
           ),
           TextButton(
             onPressed: controller.deleteScan,
             child: const Text('Delete', style: TextStyle(color: Colors.red)),
           ),
         ],
       ),
    );
  }
}

class _PdfPreview extends StatelessWidget {
  const _PdfPreview({required this.title, required this.onOpen});

  final String title;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 140,
            height: 180,
            decoration: BoxDecoration(
              color: AppTheme.bgElevated.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppTheme.greatHornedOwl.withValues(alpha: 0.85),
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
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              label: 'Open PDF',
              icon: Icons.open_in_new_rounded,
              onPressed: onOpen,
            ),
          ),
        ],
      ),
    );
  }
}

class _BeforeAfterSlider extends StatefulWidget {
  const _BeforeAfterSlider({
    required this.originalPath,
    required this.processedPath,
  });

  final String originalPath;
  final String processedPath;

  @override
  State<_BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<_BeforeAfterSlider> {
  double _position = 0.5;
  bool _ready = false;
  late ImageProvider _beforeImage;
  late ImageProvider _afterImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareImages();
    });
  }

  @override
  void didUpdateWidget(covariant _BeforeAfterSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originalPath != widget.originalPath ||
        oldWidget.processedPath != widget.processedPath) {
      setState(() => _ready = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _prepareImages();
      });
    }
  }

  Future<void> _prepareImages() async {
    final before = FileImage(File(widget.originalPath));
    final after = FileImage(File(widget.processedPath));
    _beforeImage = before;
    _afterImage = after;
    try {
      await Future.wait([
        precacheImage(before, context),
        precacheImage(after, context),
      ]);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _ready = true);
  }

  void _updatePosition(Offset localPosition, double width) {
    final next = (localPosition.dx / width).clamp(0.0, 1.0);
    setState(() => _position = next);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgElevated.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(22),
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: const ColoredBox(
              color: AppTheme.bgSecondary,
              child: Center(
                child: SizedBox(
                  width: 140,
                  child: LoopingGradientProgressBar(),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final handleX = (width * _position).clamp(0.0, width);

            return GestureDetector(
              onTapDown: (details) =>
                  _updatePosition(details.localPosition, width),
              onHorizontalDragUpdate: (details) =>
                  _updatePosition(details.localPosition, width),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _CompareImage(image: _afterImage),
                    ),
                    Positioned.fill(
                      child: ClipRect(
                        clipper: _SliderClipper(position: _position),
                        child: _CompareImage(image: _beforeImage),
                      ),
                    ),
                    Positioned(
                      left: handleX - 1,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    Positioned(
                      left: handleX - 18,
                      top: (height / 2) - 18,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.accentGradient,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chevron_left_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 12,
                      top: 12,
                      child: _CompareLabel(text: 'Before'),
                    ),
                    const Positioned(
                      right: 12,
                      top: 12,
                      child: _CompareLabel(text: 'After'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SliderClipper extends CustomClipper<Rect> {
  _SliderClipper({required this.position});

  final double position;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * position, size.height);
  }

  @override
  bool shouldReclip(covariant _SliderClipper oldClipper) {
    return oldClipper.position != position;
  }
}

class _CompareImage extends StatelessWidget {
  const _CompareImage({required this.image});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: image,
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
    );
  }
}

class _CompareLabel extends StatelessWidget {
  const _CompareLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.scan});

  final ScanModel scan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _InfoRow(
            label: 'Date',
            value: DateFormat.yMMMMd().format(scan.date),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Type',
            value: scan.type == ScanType.face ? 'Face' : 'Document',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'File Size',
            value: _formatBytes(_safeFileSize(scan.resultFilePath)),
          ),
        ],
      ),
    );
  }

  int _safeFileSize(String path) {
    try {
      return File(path).lengthSync();
    } catch (_) {
      return 0;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '—';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final text = unitIndex == 0
        ? size.toStringAsFixed(0)
        : size.toStringAsFixed(1);
    return '$text ${units[unitIndex]}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}
