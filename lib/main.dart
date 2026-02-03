import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_flow/core/services/batch_queue_service.dart';
import 'package:image_flow/core/services/batch_repository.dart';
import 'package:image_flow/core/services/detection_service.dart';
import 'package:image_flow/core/services/file_service.dart';
import 'package:image_flow/core/services/image_processing_service.dart';
import 'package:image_flow/core/services/pdf_service.dart';
import 'package:image_flow/core/theme/app_theme.dart';
import 'package:image_flow/data/models/batch_item.dart';
import 'package:image_flow/data/models/batch_job.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/data/repositories/image_processing_repository_impl.dart';
import 'package:image_flow/data/repositories/scan_repository_impl.dart';
import 'package:image_flow/domain/repositories/image_processing_repository.dart';
import 'package:image_flow/domain/repositories/scan_repository.dart';
import 'package:image_flow/domain/usecases/get_scans_use_case.dart';
import 'package:image_flow/domain/usecases/process_document_use_case.dart';
import 'package:image_flow/domain/usecases/process_face_use_case.dart';
import 'package:image_flow/domain/usecases/save_scan_use_case.dart';
import 'package:image_flow/presentation/controllers/document_session_controller.dart';
import 'package:image_flow/presentation/routes/app_pages.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';
import 'package:image_flow/presentation/widgets/app_background.dart';
import 'package:image_flow/presentation/widgets/looping_gradient_progress_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  Hive
    ..registerAdapter(ScanModelAdapter())
    ..registerAdapter(ScanTypeAdapter())
    ..registerAdapter(BatchJobAdapter())
    ..registerAdapter(BatchItemAdapter())
    ..registerAdapter(BatchIntentAdapter())
    ..registerAdapter(BatchItemStatusAdapter())
    ..registerAdapter(BatchJobStatusAdapter());
  await Hive.openBox<ScanModel>('scans');
  await Hive.openBox<BatchJob>('batch_jobs');
  await Hive.openBox<BatchItem>('batch_items');
  
  final fileService = Get.put(FileService());
  final pdfService = Get.put(PdfService());
  final imageProcessingService = Get.put(ImageProcessingService(fileService));
  Get.put(DetectionService());

  final ScanRepository scanRepository = Get.put<ScanRepository>(
    ScanRepositoryImpl(Hive.box<ScanModel>('scans')),
  );
  final ImageProcessingRepository imageProcessingRepository =
      Get.put<ImageProcessingRepository>(
    ImageProcessingRepositoryImpl(
      imageProcessingService: imageProcessingService,
      fileService: fileService,
    ),
  );

  Get.put(ProcessFaceUseCase(imageProcessingRepository));
  Get.put(ProcessDocumentUseCase(imageProcessingRepository));
  Get.put(SaveScanUseCase(scanRepository));
  Get.put(GetScansUseCase(scanRepository));

  final batchRepository = Get.put(
    BatchRepository(
      jobBox: Hive.box<BatchJob>('batch_jobs'),
      itemBox: Hive.box<BatchItem>('batch_items'),
    ),
  );
  final batchQueue = Get.put(
    BatchQueueService(
      repository: batchRepository,
      fileService: fileService,
      imageProcessingService: imageProcessingService,
      pdfService: pdfService,
    ),
  );
  Get.put(DocumentSessionController());
  await batchQueue.restoreIncompleteBatches();
  await batchQueue.cleanupStaleBatches(const Duration(days: 2));

  runApp(const ImageFlowApp());
}

class ImageFlowApp extends StatelessWidget {
  const ImageFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ImageFlow',
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      Get.offNamed<void>(Routes.home);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              const _SplashLogo(),
              const SizedBox(height: 28),
              Text(
                'ImageFlow',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
              ),
              const SizedBox(height: 22),
              const SizedBox(
                width: 160,
                child: LoopingGradientProgressBar(
                  fullHoldDuration: Duration(milliseconds: 160),
                  blankDuration: Duration(milliseconds: 240),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.accentGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.burrowingOwl.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Icon(
        Icons.camera_enhance_rounded,
        size: 56,
        color: Colors.white,
      ),
    );
  }
}
