import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_flow/core/theme/app_theme.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/pages/history_detail/history_detail_controller.dart';
import 'package:intl/intl.dart';

class HistoryDetailView extends GetView<HistoryDetailController> {
  const HistoryDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSecondary,
        title: Text(
          controller.scan.type == ScanType.face ? 'Face Scan' : 'Document',
        ),
        actions: [
          IconButton(
            onPressed: controller.shareFile,
            icon: const Icon(Icons.share),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: controller.scan.type == ScanType.face
                ? _buildImagePreview()
                : _buildDocumentPreview(),
          ),
          _buildInfoPanel(context),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return InteractiveViewer(
      child: Center(
        child: Image.file(
          File(controller.scan.resultFilePath),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildDocumentPreview() {
    // For PDF, we can show a placeholder icon or thumbnail if available
    // Since we don't have a PDF viewer widget in dependencies (only open_file),
    // we show a big icon and a button to open it.
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
             Icons.picture_as_pdf,
             size: 100,
             color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 24),
          const Text(
            'PDF Document',
            style: TextStyle(
              fontSize: 20,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
           const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: controller.openFile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tawnyOwl,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            label: const Text(
              'Open PDF',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    return Container(
       padding: const EdgeInsets.all(24),
       decoration: const BoxDecoration(
         color: AppTheme.bgSecondary,
         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
         mainAxisSize: MainAxisSize.min,
         children: [
           _buildInfoRow(
             'Date',
             DateFormat.yMMMMEEEEd().format(controller.scan.date),
           ),
           const SizedBox(height: 16),
           _buildInfoRow(
             'Type',
             controller.scan.type == ScanType.face ? 'Face Processing' : 'Document Scan',
           ),
           const SizedBox(height: 16),
           _buildInfoRow(
             'File Path',
             controller.scan.resultFilePath.split('/').last,
           ),
            const SizedBox(height: 32), // Safe Area padding
         ],
       ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
             color: AppTheme.textSecondary,
             fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    Get.dialog<void>(
       AlertDialog(
         title: const Text('Delete Scan'),
         content: const Text('Are you sure you want to delete this scan? This action cannot be undone.'),
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
