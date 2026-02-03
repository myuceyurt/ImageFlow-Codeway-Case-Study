import 'package:get/get.dart';
import 'package:image_flow/presentation/pages/processing/processing_controller.dart';

class ProcessingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProcessingController>(
      ProcessingController.new,
    );
  }
}
