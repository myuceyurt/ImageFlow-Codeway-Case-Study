import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_flow/presentation/pages/result/result_controller.dart';

class ResultView extends GetView<ResultController> {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: controller.goBack,
        ),
      ),
      body: GetBuilder<ResultController>(
        builder: (_) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Text(
                controller.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (controller.processedImagePath == null && 
              controller.originalImagePath == null) {
            return const Center(
              child: Text(
                'No image data',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Show processed image if available, otherwise original
          final displayPath = controller.processedImagePath ?? 
                            controller.originalImagePath!;

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: Image.file(
                    File(displayPath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  controller.processedImagePath != null 
                      ? 'Process Complete: Grayscale Face Crop' 
                      : 'Processing...',
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 18, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
