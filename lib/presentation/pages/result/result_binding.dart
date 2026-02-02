import 'package:get/get.dart';
import 'package:image_flow/presentation/pages/result/result_controller.dart';

class ResultBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ResultController>(
      () => ResultController(),
    );
  }
}
