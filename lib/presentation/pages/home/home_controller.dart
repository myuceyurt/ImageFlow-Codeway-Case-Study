import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_flow/core/services/batch_queue_service.dart';
import 'package:image_flow/core/services/image_processing_service.dart';
import 'package:image_flow/data/models/batch_job.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';
import 'package:image_flow/presentation/widgets/batch_intent_dialog.dart';
import 'package:image_flow/presentation/widgets/choose_source_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeController extends GetxController {
  late Box<ScanModel> _box;
  final RxList<ScanModel> scans = <ScanModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadScans();
  }

  Future<void> _loadScans() async {
    if (Hive.isBoxOpen('scans')) {
      _box = Hive.box<ScanModel>('scans');
    } else {
      _box = await Hive.openBox<ScanModel>('scans');
    }
    
    scans.assignAll(_box.values.toList().reversed);
    
    _box.listenable().addListener(() {
      scans.assignAll(_box.values.toList().reversed);
    });
  }

  Future<void> deleteScan(ScanModel scan) async {
    await scan.delete();
    Get.snackbar('Success', 'Scan deleted');
  }

  Future<void> confirmDelete(ScanModel scan) async {
    await Get.dialog<void>(
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
            onPressed: () async {
              Get.back<void>();
              await deleteScan(scan);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> pickImageFromGallery() async {
    final hasPermission = await _requestGalleryPermission();
    if (!hasPermission) {
      Get.snackbar('Permission', 'Gallery access is required.');
      return;
    }

    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isEmpty) return;

    if (images.length == 1) {
      await _processSingleImage(images.first.path);
      return;
    }

    final intent = await Get.dialog<BatchIntent>(
      const BatchIntentDialog(),
    );
    if (intent == null) return;

    final queue = Get.find<BatchQueueService>();
    final limit = queue.maxSelection;
    final limited = images.take(limit).toList();
    if (images.length > limited.length) {
      Get.snackbar('Limit', 'You can select up to $limit images.');
    }

    final batchId = await queue.startBatch(
      limited.map((e) => e.path).toList(),
      intent,
    );
    if (batchId == null) {
      Get.snackbar('Batch busy', 'A batch is already running.');
      return;
    }

    await Get.toNamed<void>(
      Routes.batchProcessing,
      arguments: {'batchId': batchId},
    );
  }

  Future<void> _processSingleImage(String path) async {
    final processingService = Get.find<ImageProcessingService>();
    final file = File(path);
    final hasFaces = await processingService.hasFaces(file);
    if (hasFaces) {
      await Get.toNamed<void>(
        Routes.processing,
        arguments: {
          'imagePath': path,
          'type': ScanType.face,
        },
      );
      return;
    }

    final text = await processingService.detectText(file);
    if (text.blocks.isEmpty) {
      Get.snackbar('Error', 'No face or document detected');
      return;
    }

    await Get.toNamed<void>(
      Routes.processing,
      arguments: {
        'imagePath': path,
        'type': ScanType.document,
        'documentSession': true,
        'startNewSession': true,
      },
    );
  }

  Future<bool> _requestGalleryPermission() async {
    PermissionStatus status;
    if (Platform.isIOS) {
      status = await Permission.photos.request();
    } else {
      await Permission.notification.request();
      status = await Permission.photos.request();
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
    }
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    return status.isGranted;
  }

  void showCaptureOptions() {
    Get.generalDialog<void>(
      barrierDismissible: true,
      barrierLabel: 'Choose Source',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Get.back<void>(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
            FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
                child: ChooseSourceDialog(
                  onCamera: navigateToScan,
                  onGallery: pickImageFromGallery,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> navigateToScan() async {
    await Get.toNamed<void>(Routes.scan);
  }

  Future<void> navigateToDetail(ScanModel scan) async {
    await Get.toNamed<void>(Routes.historyDetail, arguments: scan);
  }
}
