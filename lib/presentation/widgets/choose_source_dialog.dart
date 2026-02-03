import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_flow/core/theme/app_theme.dart';

class ChooseSourceDialog extends StatelessWidget {
  const ChooseSourceDialog({
    required this.onCamera,
    required this.onGallery,
    super.key,
  });

  final Future<void> Function() onCamera;
  final Future<void> Function() onGallery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.78,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Choose Source',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _ChooseSourceItem(
                    emoji: '📷',
                    label: 'Camera',
                    onTap: () async {
                      Get.back<void>();
                      await onCamera();
                    },
                  ),
                  const SizedBox(height: 16),
                  _ChooseSourceItem(
                    emoji: '🖼️',
                    label: 'Gallery',
                    onTap: () async {
                      Get.back<void>();
                      await onGallery();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChooseSourceItem extends StatelessWidget {
  const _ChooseSourceItem({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: Material(
        color: AppTheme.bgElevated.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
