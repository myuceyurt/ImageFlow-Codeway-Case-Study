import 'package:get/get.dart';
import 'package:image_flow/presentation/pages/batch_summary/batch_summary_controller.dart';

class BatchSummaryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BatchSummaryController>(
      BatchSummaryController.new,
    );
  }
}
