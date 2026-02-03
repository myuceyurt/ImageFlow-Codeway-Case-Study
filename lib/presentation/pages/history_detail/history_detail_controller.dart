import 'package:get/get.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class HistoryDetailController extends GetxController {
  late ScanModel scan;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is ScanModel) {
      scan = Get.arguments as ScanModel;
    } else {
      Get
        ..back<void>()
        ..snackbar('Error', 'Invalid arguments');
    }
  }

  Future<void> openFile() async {
    final result = await OpenFile.open(scan.resultFilePath);
    if (result.type != ResultType.done) {
      Get.snackbar('Error', 'Could not open file: ${result.message}');
    }
  }

  Future<void> shareFile() async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(scan.resultFilePath)]),
    );
  }

  Future<void> deleteScan() async {
    await scan.delete();
    Get.back<void>();
    Get.offAllNamed<void>(Routes.home);
    Get.snackbar('Success', 'Scan deleted');
  }
}
