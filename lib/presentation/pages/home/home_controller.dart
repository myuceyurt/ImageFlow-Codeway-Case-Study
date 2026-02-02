import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_flow/core/theme/app_theme.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';
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
      Get.toNamed<void>(
        Routes.PROCESSING,
        arguments: {
          'imagePath': image.path,
          'type': ScanType.face, // Default to face, or let user decide? 
          // For now, let's assume face flow for gallery import or prompt user.
          // The requirement says "Automatically routes to appropriate flow (Face/Document)".
          // So we might need to detect what it is. For now let's pass it to processing and let processing decide or default to face.
        },
      );
    }
  }

  void showCaptureOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppTheme.bgElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.tawnyOwl),
              title: const Text('Camera', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Get.back<void>();
                navigateToScan();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.tawnyOwl),
              title: const Text('Gallery', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Get.back<void>();
                pickImageFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  void navigateToScan() {
    Get.toNamed<void>(Routes.SCAN);
  }

  void navigateToDetail(ScanModel scan) {
    Get.toNamed<void>(Routes.HISTORY_DETAIL, arguments: scan);
  }
}
