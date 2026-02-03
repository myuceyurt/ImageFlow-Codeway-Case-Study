import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_flow/data/models/batch_item.dart';
import 'package:image_flow/data/models/batch_job.dart';

class BatchRepository {
  BatchRepository({
    required Box<BatchJob> jobBox,
    required Box<BatchItem> itemBox,
  })  : _jobBox = jobBox,
        _itemBox = itemBox;

  final Box<BatchJob> _jobBox;
  final Box<BatchItem> _itemBox;

  Future<void> createJob(BatchJob job) async {
    await _jobBox.put(job.batchId, job);
  }

  Future<void> updateJob(BatchJob job) async {
    await _jobBox.put(job.batchId, job);
  }

  Future<BatchJob?> loadJob(String batchId) async {
    return _jobBox.get(batchId);
  }

  Future<void> createItems(List<BatchItem> items) async {
    final map = <String, BatchItem>{
      for (final item in items) item.id: item,
    };
    await _itemBox.putAll(map);
  }

  Future<void> updateItem(BatchItem item) async {
    await _itemBox.put(item.id, item);
  }

  Future<List<BatchItem>> loadItemsForJob(String batchId) async {
    return _itemBox.values
        .where((item) => item.batchId == batchId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<List<BatchJob>> loadIncompleteJobs() async {
    return _jobBox.values
        .where(
          (job) =>
              job.status == BatchJobStatus.pending ||
              job.status == BatchJobStatus.running,
        )
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<List<BatchJob>> loadAllJobs() async {
    return _jobBox.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> deleteJobAndItems(String batchId) async {
    final items = _itemBox.values
        .where((item) => item.batchId == batchId)
        .toList();
    for (final item in items) {
      await _itemBox.delete(item.id);
    }
    await _jobBox.delete(batchId);
  }

  ValueListenable<Box<BatchItem>> watchItems() => _itemBox.listenable();
}
