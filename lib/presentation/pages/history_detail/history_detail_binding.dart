import 'package:get/get.dart';
import 'package:image_flow/presentation/pages/history_detail/history_detail_controller.dart';

class HistoryDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HistoryDetailController>(
      () => HistoryDetailController(),
    );
  }
}
