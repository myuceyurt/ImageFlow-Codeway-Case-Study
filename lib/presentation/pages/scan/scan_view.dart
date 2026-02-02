import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
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
                bottom: 30,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    _buildModeSelector(controller),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                Routes.PROCESSING,
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

  Widget _buildModeSelector(ScanController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Obx(() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(
            context: Get.context!,
            title: 'Face',
            isSelected: controller.scanType.value == ScanType.face,
          ),
          const SizedBox(width: 16),
          _buildModeButton(
            context: Get.context!,
            title: 'Document',
            isSelected: controller.scanType.value == ScanType.document,
          ),
        ],
      ),),
    );
  }

  Widget _buildModeButton({
    required BuildContext context,
    required String title,
    required bool isSelected,
  }) {
    return Text(
      title,
      style: TextStyle(
        color: isSelected ? AppTheme.tawnyOwl : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 16,
      ),
    );
  }
}
