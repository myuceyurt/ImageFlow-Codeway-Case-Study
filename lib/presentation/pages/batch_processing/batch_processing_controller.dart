import 'package:get/get.dart';
import 'package:image_flow/core/services/batch_queue_service.dart';
import 'package:image_flow/data/models/batch_item.dart';
import 'package:image_flow/data/models/batch_job.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';

class BatchProcessingController extends GetxController {
  final BatchQueueService _queue = Get.find();
  late String batchId;
  Worker? _jobWorker;
  Worker? _itemsWorker;

  List<BatchItem> get items => _queue.items;
  BatchJob? get job => _queue.activeJob.value;

  int get totalCount => _queue.totalCount;
  int get completedCount => _queue.completedCount;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['batchId'] is String) {
      batchId = args['batchId'] as String;
    } else {
      batchId = _queue.activeJob.value?.batchId ?? '';
    }
    if (batchId.isEmpty) {
      Get.back<void>();
      return;
    }

    _jobWorker = ever<BatchJob?>(_queue.activeJob, (_) => _maybeNavigate());
    _itemsWorker = ever<List<BatchItem>>(_queue.items, (_) => _maybeNavigate());
  }

  @override
  void onClose() {
    _jobWorker?.dispose();
    _itemsWorker?.dispose();
    super.onClose();
  }

  Future<void> cancelAll() async {
    await _queue.cancelAll();
  }

  void _maybeNavigate() {
    final job = _queue.activeJob.value;
    if (job == null || job.batchId != batchId) return;
    if (job.status != BatchJobStatus.completed &&
        job.status != BatchJobStatus.canceled) {
      return;
    }
    if (_queue.processingCount == 0 &&
        _queue.completedCount == _queue.totalCount) {
      Get.offNamed<void>(
        Routes.batchSummary,
        arguments: {'batchId': batchId},
      );
    }
  }
}
