import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_flow/core/theme/app_theme.dart';
import 'package:image_flow/presentation/controllers/document_session_controller.dart';
import 'package:image_flow/presentation/pages/document_pages/document_pages_controller.dart';
import 'package:image_flow/presentation/widgets/app_background.dart';
import 'package:image_flow/presentation/widgets/gradient_button.dart';

class DocumentPagesView extends GetView<DocumentPagesController> {
  const DocumentPagesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: WillPopScope(
            onWillPop: () async {
              controller.cancel();
              return false;
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: controller.cancel,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Document Pages',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      Obx(() {
                        final count = controller.pages.length;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.bgElevated.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$count pages',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Obx(() {
                      final pages = controller.pages;
                      if (pages.isEmpty) {
                        return _EmptyState(onAdd: controller.addPage);
                      }
                      return ReorderableListView.builder(
                        itemCount: pages.length,
                        onReorder: controller.reorder,
                        buildDefaultDragHandles: false,
                        proxyDecorator: (child, _, __) {
                          return Material(
                            color: Colors.transparent,
                            child: child,
                          );
                        },
                        itemBuilder: (context, index) {
                          final page = pages[index];
                          return _PageTile(
                            key: ValueKey(page.id),
                            index: index,
                            page: page,
                            onRemove: () => controller.removePage(page),
                            onPreview: () => _showPreview(context, page),
                          );
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    final hasPages = controller.pages.isNotEmpty;
                    return GradientButton(
                      label: 'Export PDF',
                      icon: Icons.picture_as_pdf_rounded,
                      isLoading: controller.isExporting.value,
                      onPressed: hasPages ? controller.exportPdf : null,
                    );
                  }),
                  Obx(() {
                    if (controller.pages.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return TextButton.icon(
                      onPressed: controller.addPage,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'Add Page',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPreview(BuildContext context, DocumentPage page) {
    Get.dialog<void>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.file(
            File(page.processedPath),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: AppTheme.bgSecondary,
              child: SizedBox(
                height: 240,
                child: Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: AppTheme.textSecondary,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({
    required this.index,
    required this.page,
    required this.onRemove,
    required this.onPreview,
    super.key,
  });

  final int index;
  final DocumentPage page;
  final VoidCallback onRemove;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.bgElevated.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onPreview,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 80,
                    height: 110,
                    child: Image.file(
                      File(page.thumbnailPath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: AppTheme.bgSecondary,
                        child: Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: AppTheme.textSecondary,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Page ${index + 1}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap to preview',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.textSecondary,
                  ),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(
                    Icons.drag_indicator_rounded,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.picture_as_pdf_rounded,
            size: 52,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'No pages yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a page to start your PDF.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Add Page',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
