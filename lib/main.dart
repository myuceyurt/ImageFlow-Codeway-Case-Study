import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_flow/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();

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
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
