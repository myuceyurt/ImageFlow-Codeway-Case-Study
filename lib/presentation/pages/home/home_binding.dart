import 'package:get/get.dart';
import 'package:image_flow/presentation/pages/home/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      HomeController.new,
    );
  }
}
