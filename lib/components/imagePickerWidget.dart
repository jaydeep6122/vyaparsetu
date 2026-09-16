import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vyaparsetu/components/avatar.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';

/// Picks a square image (logo) from the gallery or camera, with cropping.
class ImagePickerWidget extends StatefulWidget {
  final String label;
  final String? initialImageUrl;
  final File? selectedImageFile;
  final ValueChanged<File> onImageSelected;
  final VoidCallback? onImageRemoved;

  const ImagePickerWidget({
    super.key,
    required this.label,
    this.initialImageUrl,
    this.selectedImageFile,
    required this.onImageSelected,
    this.onImageRemoved,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;

      try {
        final cropped = await ImageCropper().cropImage(
          sourcePath: picked.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 70,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'image_crop_title'.tr(),
              toolbarColor: AppTheme.primary,
              toolbarWidgetColor: Colors.white,
              statusBarLight: false,
              aspectRatioPresets: const [CropAspectRatioPreset.square],
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'image_crop_title'.tr(),
              aspectRatioPresets: const [CropAspectRatioPreset.square],
              aspectRatioLockEnabled: true,
            ),
          ],
        );
        if (cropped != null) {
          widget.onImageSelected(File(cropped.path));
          return;
        }
      } catch (_) {
        // Cropping is optional; fall back to the picked image.
      }
      widget.onImageSelected(File(picked.path));
    } catch (_) {
      showErrorToast('image_pick_failed'.tr());
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLg,
                0,
                AppTheme.spaceLg,
                AppTheme.spaceSm,
              ),
              child: Text(widget.label, style: sheetContext.text.titleLarge),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('image_gallery'.tr()),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('image_camera'.tr()),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: AppTheme.spaceSm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasImage = widget.selectedImageFile != null ||
        (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty);

    Widget preview;
    if (widget.selectedImageFile != null) {
      preview = Image.file(widget.selectedImageFile!, fit: BoxFit.contain);
    } else if (decodeImageDataUri(widget.initialImageUrl) case final bytes?) {
      preview = Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true);
    } else if (hasImage) {
      preview = Image.network(
        widget.initialImageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            Icon(Icons.broken_image_outlined, size: 36, color: colors.danger),
      );
    } else {
      preview = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 32, color: colors.primary),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            'image_add'.tr(namedArgs: {'label': widget.label}),
            style: context.text.labelLarge?.copyWith(color: colors.primary),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: context.text.labelMedium),
        const SizedBox(height: AppTheme.spaceSm),
        Material(
          color: colors.surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            side: BorderSide(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _showSourceSheet,
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceMd),
                      child: preview,
                    ),
                  ),
                  if (hasImage && widget.onImageRemoved != null)
                    Positioned(
                      top: AppTheme.spaceSm,
                      right: AppTheme.spaceSm,
                      child: IconButton.filledTonal(
                        tooltip: 'remove'.tr(),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: widget.onImageRemoved,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
