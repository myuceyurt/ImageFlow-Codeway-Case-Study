import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/core/services/image_processing_service.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';
import 'package:image_flow/presentation/widgets/choose_source_dialog.dart';
import 'package:image_picker/image_picker.dart';

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
  }

  Future<void> pickImageFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final processingService = Get.find<ImageProcessingService>();
      final file = File(image.path);
      final hasFaces = await processingService.hasFaces(file);
      if (hasFaces) {
        await Get.toNamed<void>(
          Routes.processing,
          arguments: {
            'imagePath': image.path,
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
          'imagePath': image.path,
          'type': ScanType.document,
        },
      );
    }
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
