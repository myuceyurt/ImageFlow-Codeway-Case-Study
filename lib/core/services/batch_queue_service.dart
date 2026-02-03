import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:image_flow/core/errors/app_exception.dart';
import 'package:image_flow/core/services/background_task_service.dart';
import 'package:image_flow/core/services/batch_foreground_service.dart';
import 'package:image_flow/core/services/batch_repository.dart';
import 'package:image_flow/core/services/file_service.dart';
import 'package:image_flow/core/services/image_processing_service.dart';
import 'package:image_flow/core/services/pdf_service.dart';
import 'package:image_flow/data/models/batch_item.dart';
import 'package:image_flow/data/models/batch_job.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:uuid/uuid.dart';

class BatchQueueService extends GetxService {
  BatchQueueService({
    required BatchRepository repository,
    required FileService fileService,
    required ImageProcessingService imageProcessingService,
    required PdfService pdfService,
    BatchForegroundService? foregroundService,
    BackgroundTaskService? backgroundTaskService,
  })  : _repository = repository,
        _fileService = fileService,
        _imageProcessingService = imageProcessingService,
        _pdfService = pdfService,
        _foregroundService = foregroundService ?? BatchForegroundService(),
        _backgroundTaskService =
            backgroundTaskService ?? BackgroundTaskService();

  final BatchRepository _repository;
  final FileService _fileService;
  final ImageProcessingService _imageProcessingService;
  final PdfService _pdfService;
  final BatchForegroundService _foregroundService;
  final BackgroundTaskService _backgroundTaskService;
  final Uuid _uuid = const Uuid();

  final Rxn<BatchJob> activeJob = Rxn<BatchJob>();
  final RxList<BatchItem> items = <BatchItem>[].obs;

  final Queue<String> _pendingQueue = Queue<String>();
  final Set<String> _activeItems = <String>{};

  bool _cancelRequested = false;

  int get maxConcurrent => activeJob.value?.maxConcurrent ?? 2;
  int get maxSelection => 20;

  int get totalCount => items.length;
  int get completedCount => items
      .where(
        (item) =>
            item.status == BatchItemStatus.success ||
            item.status == BatchItemStatus.failed ||
            item.status == BatchItemStatus.canceled,
      )
      .length;
  int get failedCount =>
      items.where((item) => item.status == BatchItemStatus.failed).length;
  int get processingCount =>
      items.where((item) => item.status == BatchItemStatus.processing).length;

  Future<void> restoreIncompleteBatches() async {
    final jobs = await _repository.loadIncompleteJobs();
    if (jobs.isEmpty) return;

    _cancelRequested = false;
    final job = jobs.first;
    final loadedItems = await _repository.loadItemsForJob(job.batchId);
    final normalized = <BatchItem>[];
    for (final item in loadedItems) {
      if (item.status == BatchItemStatus.processing) {
        final reset = item.copyWith(status: BatchItemStatus.pending);
        await _repository.updateItem(reset);
        normalized.add(reset);
      } else {
        normalized.add(item);
      }
    }

    activeJob.value = job.copyWith(
      status: BatchJobStatus.running,
      updatedAt: DateTime.now(),
    );
    await _repository.updateJob(activeJob.value!);

    items.assignAll(normalized);
    _activeItems.clear();
    _rebuildPendingQueue();
    await _startBackgroundWork();
    _pump();
    await _checkForCompletion();
  }

  Future<String?> startBatch(
    List<String> sourcePaths,
    BatchIntent intent,
  ) async {
    if (sourcePaths.isEmpty) return null;
    if (activeJob.value != null &&
        activeJob.value!.status == BatchJobStatus.running) {
      return null;
    }

    final now = DateTime.now();
    final batchId = _uuid.v4();
    final job = BatchJob(
      batchId: batchId,
      intent: intent,
      status: BatchJobStatus.pending,
      createdAt: now,
      updatedAt: now,
      maxConcurrent: 2,
      totalCount: sourcePaths.length,
    );

    await _repository.createJob(job);

    final newItems = <BatchItem>[];
    for (final path in sourcePaths) {
      final itemId = _uuid.v4();
      File cached;
      try {
        cached = await _fileService.copyToBatchCache(
          source: File(path),
          batchId: batchId,
          itemId: itemId,
        );
      } catch (_) {
        cached = File(path);
      }
      newItems.add(
        BatchItem(
          id: itemId,
          batchId: batchId,
          originalPath: cached.path,
          status: BatchItemStatus.pending,
          requestedType: intent,
          createdAt: DateTime.now(),
        ),
      );
    }

    await _repository.createItems(newItems);

    final runningJob = job.copyWith(
      status: BatchJobStatus.running,
      updatedAt: DateTime.now(),
    );
    await _repository.updateJob(runningJob);

    activeJob.value = runningJob;
    items.assignAll(newItems);
    _cancelRequested = false;
    _activeItems.clear();
    _rebuildPendingQueue();
    await _startBackgroundWork();
    _pump();
    return batchId;
  }

  Future<void> cancelAll() async {
    _cancelRequested = true;
    final job = activeJob.value;
    if (job == null) return;

    for (final item in items) {
      if (item.status == BatchItemStatus.pending) {
        final canceled = item.copyWith(
          status: BatchItemStatus.canceled,
          completedAt: DateTime.now(),
        );
        await _repository.updateItem(canceled);
        _replaceItem(canceled);
      }
    }

    await _cleanupCanceledItems();
    final canceledJob = job.copyWith(
      status: BatchJobStatus.canceled,
      updatedAt: DateTime.now(),
    );
    await _repository.updateJob(canceledJob);
    activeJob.value = canceledJob;
    _pendingQueue.clear();
    await _checkForCompletion();
  }

  Future<void> _cleanupCanceledItems() async {
    final canceledItems =
        items.where((item) => item.status == BatchItemStatus.canceled).toList();
    for (final item in canceledItems) {
      await _fileService.deleteIfExists(item.processedFilePath);
      await _fileService.deleteIfExists(item.thumbnailPath);
      await _fileService.deleteIfExists(item.originalPath);
    }
  }

  Future<void> retryFailed({BatchIntent? overrideIntent}) async {
    final job = activeJob.value;
    if (job == null) return;

    final failedItems =
        items.where((item) => item.status == BatchItemStatus.failed).toList();
    if (failedItems.isEmpty) return;

    for (final item in failedItems) {
      final updated = item.copyWith(
        status: BatchItemStatus.pending,
        requestedType: overrideIntent ?? item.requestedType,
        detectedType: null,
        processedFilePath: null,
        thumbnailPath: null,
        errorMessage: null,
        startedAt: null,
        completedAt: null,
      );
      await _repository.updateItem(updated);
      _replaceItem(updated);
    }

    _rebuildPendingQueue();
    _cancelRequested = false;
    final runningJob = job.copyWith(
      status: BatchJobStatus.running,
      updatedAt: DateTime.now(),
    );
    await _repository.updateJob(runningJob);
    activeJob.value = runningJob;
    await _startBackgroundWork();
    _pump();
  }

  Future<bool> attachToBatch(String batchId) async {
    if (activeJob.value?.batchId == batchId) return true;
    final job = await _repository.loadJob(batchId);
    if (job == null) return false;
    final loadedItems = await _repository.loadItemsForJob(batchId);
    activeJob.value = job;
    items.assignAll(loadedItems);
    _activeItems.clear();
    _rebuildPendingQueue();
    return true;
  }

  Future<void> retryItem(String itemId, BatchIntent newIntent) async {
    final job = activeJob.value;
    if (job == null) return;
    final item = items.firstWhereOrNull((value) => value.id == itemId);
    if (item == null) return;

    final updated = item.copyWith(
      status: BatchItemStatus.pending,
      requestedType: newIntent,
      detectedType: null,
      processedFilePath: null,
      thumbnailPath: null,
      errorMessage: null,
      startedAt: null,
      completedAt: null,
    );
    await _repository.updateItem(updated);
    _replaceItem(updated);
    _rebuildPendingQueue();

    final runningJob = job.copyWith(
      status: BatchJobStatus.running,
      updatedAt: DateTime.now(),
    );
    await _repository.updateJob(runningJob);
    activeJob.value = runningJob;
    _cancelRequested = false;
    await _startBackgroundWork();
    _pump();
  }

  Future<void> cleanupBatch(String batchId) async {
    final loadedItems = await _repository.loadItemsForJob(batchId);
    for (final item in loadedItems) {
      if (item.status != BatchItemStatus.success) {
        await _fileService.deleteIfExists(item.processedFilePath);
        await _fileService.deleteIfExists(item.thumbnailPath);
        await _fileService.deleteIfExists(item.originalPath);
      }
    }
    final dir = await _fileService.ensureBatchDirectory(batchId);
    await _fileService.deleteDirectoryIfExists(dir.path);
    await _repository.deleteJobAndItems(batchId);
    if (activeJob.value?.batchId == batchId) {
      await _stopBackgroundWork();
      activeJob.value = null;
      items.clear();
      _pendingQueue.clear();
      _activeItems.clear();
    }
  }

  Future<void> cleanupStaleBatches(Duration maxAge) async {
    final now = DateTime.now();
    final jobs = await _repository.loadAllJobs();
    for (final job in jobs) {
      if (now.difference(job.updatedAt) > maxAge &&
          job.status != BatchJobStatus.running) {
        await cleanupBatch(job.batchId);
      }
    }
  }

  void _rebuildPendingQueue() {
    _pendingQueue.clear();
    final pending = items
        .where((item) => item.status == BatchItemStatus.pending)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final item in pending) {
      _pendingQueue.add(item.id);
    }
  }

  void _pump() {
    if (_cancelRequested) return;
    while (_activeItems.length < maxConcurrent && _pendingQueue.isNotEmpty) {
      final itemId = _pendingQueue.removeFirst();
      final item = items.firstWhereOrNull((value) => value.id == itemId);
      if (item == null) continue;
      if (item.status != BatchItemStatus.pending) continue;

      _activeItems.add(itemId);
      _processItem(item).whenComplete(() async {
        _activeItems.remove(itemId);
        await _checkForCompletion();
        _pump();
      });
    }
  }

  Future<void> _processItem(BatchItem item) async {
    final started = item.copyWith(
      status: BatchItemStatus.processing,
      startedAt: DateTime.now(),
      errorMessage: null,
    );
    await _repository.updateItem(started);
    _replaceItem(started);

    try {
      final processed = await _runFlow(started);
      final completed = processed.copyWith(
        status: BatchItemStatus.success,
        completedAt: DateTime.now(),
      );
      await _repository.updateItem(completed);
      _replaceItem(completed);
      await _saveToHistory(completed);
    } catch (e) {
      final failed = started.copyWith(
        status: BatchItemStatus.failed,
        errorMessage: e.toString(),
        completedAt: DateTime.now(),
      );
      await _repository.updateItem(failed);
      _replaceItem(failed);
    } finally {
      await _updateForegroundProgress();
    }
  }

  Future<BatchItem> _runFlow(BatchItem item) async {
    final originalFile = File(item.originalPath);
    if (!originalFile.existsSync()) {
      throw const AppException('Original image not found.');
    }

    var detectionFile = originalFile;
    if (item.requestedType == BatchIntent.auto) {
      detectionFile = await _prepareDetectionCopy(item);
    }
    ScanType? detectedType;
    try {
      if (item.requestedType == BatchIntent.auto) {
        final hasFaces = await _imageProcessingService.hasFaces(detectionFile);
        if (hasFaces) {
          detectedType = ScanType.face;
        } else {
          final text = await _imageProcessingService.detectText(detectionFile);
          if (text.blocks.isNotEmpty) {
            detectedType = ScanType.document;
          }
        }
        if (detectedType == null) {
          throw const AppException('No face or document detected.');
        }
      } else if (item.requestedType == BatchIntent.face) {
        detectedType = ScanType.face;
      } else {
        detectedType = ScanType.document;
      }
    } finally {
      if (detectionFile.path != originalFile.path) {
        await _fileService.deleteIfExists(detectionFile.path);
      }
    }

    if (detectedType == ScanType.face) {
      File? processed;
      try {
        processed = await _imageProcessingService.processFaceFlow(originalFile);
        final movedOriginal = await _fileService.moveToDocuments(originalFile);
        return item.copyWith(
          originalPath: movedOriginal.path,
          detectedType: detectedType,
          processedFilePath: processed.path,
          thumbnailPath: processed.path,
        );
      } catch (e) {
        if (processed != null) {
          await _fileService.deleteIfExists(processed.path);
        }
        rethrow;
      }
    }

    File? enhanced;
    try {
      enhanced =
          await _imageProcessingService.processDocumentFlow(originalFile);
      final pdf = await _pdfService.generatePdfFromImage(enhanced);
      final movedOriginal = await _fileService.moveToDocuments(originalFile);
      return item.copyWith(
        originalPath: movedOriginal.path,
        detectedType: detectedType,
        processedFilePath: pdf.path,
        thumbnailPath: enhanced.path,
      );
    } catch (e) {
      if (enhanced != null) {
        await _fileService.deleteIfExists(enhanced.path);
      }
      rethrow;
    }
  }

  Future<void> _saveToHistory(BatchItem item) async {
    final processedPath = item.processedFilePath;
    if (processedPath == null || item.detectedType == null) return;

    final box = Hive.box<ScanModel>('scans');
    final scan = ScanModel(
      id: _uuid.v4(),
      date: DateTime.now(),
      type: item.detectedType!,
      resultFilePath: processedPath,
      originalFilePath: item.originalPath,
      thumbnailPath: item.thumbnailPath ?? processedPath,
    );
    await box.add(scan);
  }

  Future<File> _prepareDetectionCopy(BatchItem item) async {
    final original = File(item.originalPath);
    try {
      final bytes = await original.readAsBytes();
      final resizedBytes = await compute(
        _downsampleImage,
        _DownsampleRequest(bytes, 1600, 80),
      );
      final dir = await _fileService.ensureBatchDirectory(item.batchId);
      final path = '${dir.path}/${item.id}_detect.jpg';
      return _fileService.writeBytesToFile(resizedBytes, path);
    } catch (e) {
      return original;
    }
  }

  void _replaceItem(BatchItem updated) {
    final index = items.indexWhere((value) => value.id == updated.id);
    if (index == -1) return;
    items[index] = updated;
    items.refresh();
  }

  Future<void> _checkForCompletion() async {
    if (_activeItems.isNotEmpty) return;
    if (items.any(
      (item) =>
          item.status == BatchItemStatus.pending ||
          item.status == BatchItemStatus.processing,
    )) {
      return;
    }

    final job = activeJob.value;
    if (job == null) return;
    final nextStatus =
        _cancelRequested ? BatchJobStatus.canceled : BatchJobStatus.completed;
    final updated = job.copyWith(
      status: nextStatus,
      updatedAt: DateTime.now(),
    );
    await _repository.updateJob(updated);
    activeJob.value = updated;
    await _stopBackgroundWork();
  }

  Future<void> _startBackgroundWork() async {
    await _backgroundTaskService.begin();
    await _updateForegroundProgress(startIfNeeded: true);
  }

  Future<void> _updateForegroundProgress({bool startIfNeeded = false}) async {
    final job = activeJob.value;
    if (job == null) return;
    final total = job.totalCount;
    final completed = completedCount;
    if (startIfNeeded) {
      await _foregroundService.start(total: total, completed: completed);
    } else {
      await _foregroundService.update(total: total, completed: completed);
    }
  }

  Future<void> _stopBackgroundWork() async {
    await _foregroundService.stop();
    await _backgroundTaskService.end();
  }
}

class _DownsampleRequest {
  const _DownsampleRequest(this.bytes, this.maxDimension, this.quality);

  final Uint8List bytes;
  final int maxDimension;
  final int quality;
}

Uint8List _downsampleImage(_DownsampleRequest request) {
  final decoded = img.decodeImage(request.bytes);
  if (decoded == null) {
    throw Exception('Failed to decode image');
  }

  final oriented = img.bakeOrientation(decoded);
  var resized = oriented;
  if (oriented.width > request.maxDimension ||
      oriented.height > request.maxDimension) {
    final ratio = oriented.width / oriented.height;
    final width = oriented.width >= oriented.height
        ? request.maxDimension
        : (request.maxDimension * ratio).round();
    final height = oriented.height > oriented.width
        ? request.maxDimension
        : (request.maxDimension / ratio).round();
    resized = img.copyResize(
      oriented,
      width: width,
      height: height,
      interpolation: img.Interpolation.average,
    );
  }
  return Uint8List.fromList(img.encodeJpg(resized, quality: request.quality));
}

extension _BatchItemListHelpers on List<BatchItem> {
  BatchItem? firstWhereOrNull(bool Function(BatchItem) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}
