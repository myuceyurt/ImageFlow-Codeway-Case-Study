import 'package:get/get.dart';
import 'package:image_flow/presentation/pages/document_pages/document_pages_controller.dart';

class DocumentPagesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DocumentPagesController>(
      DocumentPagesController.new,
    );
  }
}
