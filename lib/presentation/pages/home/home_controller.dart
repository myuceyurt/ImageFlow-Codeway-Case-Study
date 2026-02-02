import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';

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

  void navigateToScan() {
    Get.toNamed<void>(Routes.SCAN);
  }
}
