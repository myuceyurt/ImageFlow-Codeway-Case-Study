import 'package:get/get.dart';
import 'package:image_flow/presentation/pages/batch_processing/batch_processing_controller.dart';

class BatchProcessingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BatchProcessingController>(
      BatchProcessingController.new,
    );
  }
}
