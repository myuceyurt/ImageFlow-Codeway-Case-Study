import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_flow/core/services/file_service.dart';
import 'package:image_flow/core/services/image_processing_service.dart';
import 'package:image_flow/core/theme/app_theme.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/routes/app_pages.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  Hive
    ..registerAdapter(ScanModelAdapter())
    ..registerAdapter(ScanTypeAdapter());
  await Hive.openBox<ScanModel>('scans');
  
  final fileService = Get.put(FileService());
  Get.put(ImageProcessingService(fileService));

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

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
        Get.offNamed<void>(Routes.HOME);
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_enhance_rounded,
              size: 80,
              color: AppTheme.tawnyOwl,
            ),
            const SizedBox(height: 24),
            Text(
              'ImageFlow',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppTheme.tawnyOwl,
                  ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              color: AppTheme.greatHornedOwl,
            ),
          ],
        ),
      ),
    );
  }
}
