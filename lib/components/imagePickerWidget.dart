import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:vyaparsetu/global/themes.dart';

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
  Uint8List? _decodedBytes;
  String? _lastLoadedUrl;

  @override
  void initState() {
    super.initState();
    _decodeInitialImage();
  }

  @override
  void didUpdateWidget(covariant ImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImageUrl != oldWidget.initialImageUrl) {
      _decodeInitialImage();
    }
  }

  void _decodeInitialImage() {
    final url = widget.initialImageUrl;
    if (url != null && url.isNotEmpty && url.startsWith('data:image')) {
      if (url != _lastLoadedUrl) {
        try {
          final base64String = url.split(',')[1];
          setState(() {
            _decodedBytes = base64Decode(base64String);
            _lastLoadedUrl = url;
          });
        } catch (e) {
          debugPrint('Error decoding base64 image: $e');
          setState(() {
            _decodedBytes = null;
            _lastLoadedUrl = null;
          });
        }
      }
    } else {
      setState(() {
        _decodedBytes = null;
        _lastLoadedUrl = null;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        try {
          final croppedFile = await ImageCropper().cropImage(
            sourcePath: pickedFile.path,
            compressFormat: ImageCompressFormat.jpg,
            compressQuality: 70,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Crop Logo',
                toolbarColor: const Color(0xFF37474F),
                toolbarWidgetColor: Colors.white,
                statusBarLight: false,
                aspectRatioPresets: const [CropAspectRatioPreset.square],
                initAspectRatio: CropAspectRatioPreset.square,
                lockAspectRatio: true,
              ),
              IOSUiSettings(
                aspectRatioPresets: const [CropAspectRatioPreset.square],
                aspectRatioLockEnabled: true,
              ),
            ],
          );
          if (croppedFile != null) {
            widget.onImageSelected(File(croppedFile.path));
            return;
          }
        } catch (e) {
          debugPrint('Error cropping image: $e');
        }
        widget.onImageSelected(File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showPickerOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Select source for ${widget.label}',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('Gallery', style: GoogleFonts.outfit()),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text('Camera', style: GoogleFonts.outfit()),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget imageContent = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 36,
            color: theme.colorScheme.primary.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 8),
          Text(
            'Add ${widget.label}',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );

    if (widget.selectedImageFile != null) {
      imageContent = Padding(
        padding: const EdgeInsets.all(12),
        child: Image.file(
          widget.selectedImageFile!,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (_decodedBytes != null) {
      imageContent = Padding(
        padding: const EdgeInsets.all(12),
        child: Image.memory(
          _decodedBytes!,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (widget.initialImageUrl != null &&
        widget.initialImageUrl!.isNotEmpty) {
      imageContent = Padding(
        padding: const EdgeInsets.all(12),
        child: Image.network(
          widget.initialImageUrl!,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 36,
                color: theme.colorScheme.error,
              ),
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _showPickerOptions(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.primaryDark : AppTheme.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isDark ? AppTheme.gray700 : AppTheme.gray200,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  imageContent,
                  if (widget.selectedImageFile != null ||
                      (widget.initialImageUrl != null &&
                          widget.initialImageUrl!.isNotEmpty))
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: widget.onImageRemoved,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
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
