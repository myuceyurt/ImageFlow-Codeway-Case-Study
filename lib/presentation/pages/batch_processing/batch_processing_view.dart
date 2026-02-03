import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_flow/core/theme/app_theme.dart';
import 'package:image_flow/data/models/batch_item.dart';
import 'package:image_flow/presentation/pages/batch_processing/batch_processing_controller.dart';
import 'package:image_flow/presentation/widgets/app_background.dart';
import 'package:image_flow/presentation/widgets/gradient_progress_bar.dart';

class BatchProcessingView extends GetView<BatchProcessingController> {
  const BatchProcessingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
            child: Obx(() {
              final total = controller.totalCount;
              final completed = controller.completedCount;
              final progress = total == 0 ? 0.0 : completed / total;
              final items = controller.items;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: controller.cancelAll,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Batch Processing',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: controller.cancelAll,
                        child: const Text(
                          'Cancel All',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Processing $completed of $total',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  GradientProgressBar(value: progress),
                  const SizedBox(height: 18),
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _BatchItemRow(
                          index: index,
                          item: item,
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BatchItemRow extends StatelessWidget {
  const _BatchItemRow({
    required this.index,
    required this.item,
  });

  final int index;
  final BatchItem item;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);
    final statusLabel = _statusLabel(item.status);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.bgSecondary.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          _Thumb(path: item.thumbnailPath ?? item.originalPath),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image ${index + 1}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            _statusIcon(item.status),
            color: statusColor,
          ),
        ],
      ),
    );
  }

  Color _statusColor(BatchItemStatus status) {
    switch (status) {
      case BatchItemStatus.processing:
        return AppTheme.tawnyOwl;
      case BatchItemStatus.success:
        return Colors.greenAccent;
      case BatchItemStatus.failed:
        return Colors.redAccent;
      case BatchItemStatus.canceled:
        return AppTheme.textSecondary;
      case BatchItemStatus.pending:
        return AppTheme.textSecondary;
    }
  }

  String _statusLabel(BatchItemStatus status) {
    switch (status) {
      case BatchItemStatus.processing:
        return 'Processing';
      case BatchItemStatus.success:
        return 'Completed';
      case BatchItemStatus.failed:
        return 'Failed';
      case BatchItemStatus.canceled:
        return 'Canceled';
      case BatchItemStatus.pending:
        return 'Pending';
    }
  }

  IconData _statusIcon(BatchItemStatus status) {
    switch (status) {
      case BatchItemStatus.processing:
        return Icons.hourglass_top_rounded;
      case BatchItemStatus.success:
        return Icons.check_circle_rounded;
      case BatchItemStatus.failed:
        return Icons.error_rounded;
      case BatchItemStatus.canceled:
        return Icons.cancel_rounded;
      case BatchItemStatus.pending:
        return Icons.schedule_rounded;
    }
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          cacheWidth: 140,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.image_not_supported_outlined,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
