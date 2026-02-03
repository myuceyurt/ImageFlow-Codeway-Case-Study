import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_flow/core/services/batch_queue_service.dart';
import 'package:image_flow/core/services/batch_repository.dart';
import 'package:image_flow/data/models/batch_item.dart';
import 'package:image_flow/data/models/batch_job.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';
import 'package:open_file/open_file.dart';

class BatchSummaryController extends GetxController {
  final BatchRepository _repository = Get.find();
  final BatchQueueService _queue = Get.find();
  final RxList<BatchItem> items = <BatchItem>[].obs;

  late String batchId;
  ValueListenable<Box<BatchItem>>? _listener;

  int get failedCount =>
      items.where((item) => item.status == BatchItemStatus.failed).length;

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
    _loadItems();
    _listener = Hive.box<BatchItem>('batch_items').listenable();
    _listener?.addListener(_loadItems);
  }

  @override
  void onClose() {
    _listener?.removeListener(_loadItems);
    super.onClose();
  }

  Future<void> retryFailed() async {
    final attached = await _queue.attachToBatch(batchId);
    if (!attached) return;
    await _queue.retryFailed();
    await Get.offNamed<void>(
      Routes.batchProcessing,
      arguments: {'batchId': batchId},
    );
  }

  Future<void> retryItem(BatchItem item, BatchIntent intent) async {
    final attached = await _queue.attachToBatch(batchId);
    if (!attached) return;
    await _queue.retryItem(item.id, intent);
    await Get.offNamed<void>(
      Routes.batchProcessing,
      arguments: {'batchId': batchId},
    );
  }

  Future<void> openItem(BatchItem item) async {
    final processedPath = item.processedFilePath;
    final detectedType = item.detectedType;
    if (processedPath == null || detectedType == null) return;
    if (detectedType == ScanType.document) {
      await OpenFile.open(processedPath);
      return;
    }
    await Get.toNamed<void>(
      Routes.result,
      arguments: {
        'imagePath': item.originalPath,
        'processedFile': File(processedPath),
        'thumbnailFile': File(item.thumbnailPath ?? processedPath),
        'type': detectedType,
      },
    );
  }

  Future<void> done() async {
    await _queue.cleanupBatch(batchId);
    await Get.offAllNamed<void>(Routes.home);
  }

  void _loadItems() {
    _repository.loadItemsForJob(batchId).then(items.assignAll);
  }
}
