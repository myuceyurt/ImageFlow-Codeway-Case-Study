import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_flow/core/theme/app_theme.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/pages/scan/scan_controller.dart';
import 'package:image_flow/presentation/pages/scan/widgets/face_painter.dart';
import 'package:image_flow/presentation/pages/scan/widgets/scanner_guide_painter.dart';
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
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.tawnyOwl),
            );
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
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
              Obx(() {
                  final imageSize = Size(
                    camera.value.previewSize!.width,
                    camera.value.previewSize!.height,
                  );

                  if (controller.scanType.value == ScanType.face) {
                    if (controller.detectedFaces.isEmpty) {
                      return const SizedBox();
                    }
                    return CustomPaint(
                      painter: FacePainter(
                        faces: controller.detectedFaces,
                        imageSize: imageSize,
                        rotation: InputImageRotation.rotation90deg,
                        cameraLensDirection: camera.description.lensDirection,
                      ),
                    );
                } else {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: ScannerGuidePainter(),
                    );
                }
              }),
              Positioned(
                top: 18,
                left: 12,
                right: 12,
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Get.back<void>(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Obx(() {
                          final label = controller.scanType.value ==
                                  ScanType.face
                              ? 'Face'
                              : 'Document';
                          final icon = controller.scanType.value ==
                                  ScanType.face
                              ? Icons.face_rounded
                              : Icons.description_rounded;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.bgElevated.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 18, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: controller.pickImageFromGallery,
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
                              await Get.toNamed<dynamic>(
                                Routes.processing,
                                arguments: {
                                  'imagePath': path,
                                  'type': controller.scanType.value,
                                },
                              );
                            }
                          },
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.accentGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
