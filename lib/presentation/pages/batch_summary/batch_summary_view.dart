import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_flow/core/theme/app_theme.dart';
import 'package:image_flow/data/models/batch_item.dart';
import 'package:image_flow/data/models/batch_job.dart';
import 'package:image_flow/presentation/pages/batch_summary/batch_summary_controller.dart';
import 'package:image_flow/presentation/widgets/app_background.dart';
import 'package:image_flow/presentation/widgets/gradient_button.dart';

class BatchSummaryView extends GetView<BatchSummaryController> {
  const BatchSummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
            child: Obx(() {
              final items = controller.items;
              final failedCount = controller.failedCount;
              final summaryText =
                  '${items.length - failedCount} succeeded · '
                  '$failedCount failed';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: controller.done,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Batch Summary',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    summaryText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.92,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _SummaryTile(
                          item: item,
                          onTap: () => _handleTap(item),
                          onLongPress: () => _showRetrySheet(item),
                        );
                      },
                    ),
                  ),
                  if (failedCount > 0) ...[
                    const SizedBox(height: 12),
                    GradientButton(
                      label: 'Retry All Failed',
                      icon: Icons.refresh_rounded,
                      onPressed: controller.retryFailed,
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: controller.done,
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
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

  void _handleTap(BatchItem item) {
    if (item.status == BatchItemStatus.failed) {
      _showRetrySheet(item);
      return;
    }
    if (item.status == BatchItemStatus.success) {
      controller.openItem(item);
      return;
    }
  }

  void _showRetrySheet(BatchItem item) {
    if (item.status == BatchItemStatus.processing ||
        item.status == BatchItemStatus.pending) {
      return;
    }
    Get.bottomSheet<void>(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
        decoration: const BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Retry as...',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _RetryOption(
              label: 'Auto',
              onTap: () {
                Get.back<void>();
                controller.retryItem(item, BatchIntent.auto);
              },
            ),
            const SizedBox(height: 10),
            _RetryOption(
              label: 'Document',
              onTap: () {
                Get.back<void>();
                controller.retryItem(item, BatchIntent.document);
              },
            ),
            const SizedBox(height: 10),
            _RetryOption(
              label: 'Face',
              onTap: () {
                Get.back<void>();
                controller.retryItem(item, BatchIntent.face);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  final BatchItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);
    final statusLabel = _statusLabel(item.status);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppTheme.bgElevated.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.file(
                    File(item.thumbnailPath ?? item.originalPath),
                    fit: BoxFit.cover,
                    cacheWidth: 320,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: AppTheme.bgSecondary,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: AppTheme.textSecondary,
                        size: 38,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      _statusIcon(item.status),
                      color: statusColor,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

class _RetryOption extends StatelessWidget {
  const _RetryOption({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.bgElevated,
          foregroundColor: AppTheme.textPrimary,
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
