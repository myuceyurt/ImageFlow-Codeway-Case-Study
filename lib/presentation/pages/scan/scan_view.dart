import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_flow/core/theme/app_theme.dart';
import 'package:image_flow/presentation/pages/scan/scan_controller.dart';
import 'package:image_flow/presentation/pages/scan/widgets/face_painter.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';

class ScanView extends StatelessWidget {
  const ScanView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScanController());

    return Scaffold(
      backgroundColor: Colors.black,
      body: GetBuilder<ScanController>(
        builder: (_) {
          if (!controller.isInitialized ||
              controller.cameraController == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final camera = controller.cameraController!;
          final size = MediaQuery.of(context).size;
          var scale = size.aspectRatio * camera.value.aspectRatio;

          if (scale < 1) scale = 1 / scale;

          return Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: scale,
                child: Center(
                  child: CameraPreview(camera),
                ),
              ),
              Obx(() {
                if (controller.detectedFaces.isEmpty) return const SizedBox();

                final imageSize = Size(
                  camera.value.previewSize!.width,
                  camera.value.previewSize!.height
                );

                return CustomPaint(
                  painter: FacePainter(
                    faces: controller.detectedFaces,
                    imageSize: imageSize,
                    rotation: InputImageRotation.rotation90deg,
                    cameraLensDirection: camera.description.lensDirection,
                  ),
                );
              }),
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () {

                      },
                      icon: const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final path = await controller.captureImage();
                        if (path != null) {
                          Get.toNamed(
                            Routes.RESULT,
                            arguments: {
                              'imagePath': path,
                              'faces': controller.detectedFaces,
                            },
                          );
                        }
                      },
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.tawnyOwl,
                              AppTheme.greatHornedOwl,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: controller.toggleCamera,
                      icon: const Icon(
                        Icons.cameraswitch,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 50,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Get.back<void>(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
