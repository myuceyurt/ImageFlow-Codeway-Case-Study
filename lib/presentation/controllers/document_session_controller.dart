import 'package:get/get.dart';

class DocumentPage {
  DocumentPage({
    required this.id,
    required this.originalPath,
    required this.processedPath,
    required this.thumbnailPath,
  });

  final String id;
  final String originalPath;
  final String processedPath;
  final String thumbnailPath;
}

class DocumentSessionController extends GetxService {
  final RxList<DocumentPage> pages = <DocumentPage>[].obs;

  void startNewSession() {
    pages.clear();
  }

  void addPage(DocumentPage page) {
    pages.add(page);
  }

  void removeById(String id) {
    pages.removeWhere((page) => page.id == id);
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = pages.removeAt(oldIndex);
    pages.insert(newIndex, item);
  }

  void clear() {
    pages.clear();
  }
}
