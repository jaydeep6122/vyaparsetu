import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// The server accepts image data URIs up to 500,000 characters. Logos and
/// signatures are kept far below that: they only ever print at a few
/// centimetres, and a small bill payload keeps saving quick on mobile data.
const maxImageDataUriLength = 200000;

enum ImageFailure {
  /// The file could not be decoded (an unsupported format such as HEIC, or a
  /// damaged file).
  unreadable,

  /// Even at the lowest quality the image stays over the limit.
  tooLarge,
}

class ImageResult {
  /// `data:image/...;base64,...`, ready to send.
  final String? uri;
  final ImageFailure? failure;

  const ImageResult.success(String this.uri) : failure = null;
  const ImageResult.failed(ImageFailure this.failure) : uri = null;
}

/// Shrinks a picked image and returns it as a data URI small enough to store
/// on the business.
Future<ImageResult> imageFileToDataUri(File file, {int maxSize = 512}) async {
  final bytes = await file.readAsBytes();
  return Isolate.run(() => _encode(bytes, maxSize));
}

ImageResult _encode(Uint8List bytes, int maxSize) {
  var image = img.decodeImage(bytes);
  if (image == null) return const ImageResult.failed(ImageFailure.unreadable);

  if (image.width > maxSize || image.height > maxSize) {
    image = image.width >= image.height
        ? img.copyResize(image, width: maxSize)
        : img.copyResize(image, height: maxSize);
  }

  // Keep transparency (logos) when the PNG is small enough.
  if (image.hasAlpha) {
    final png = 'data:image/png;base64,${base64Encode(img.encodePng(image))}';
    if (png.length <= maxImageDataUriLength) return ImageResult.success(png);

    final flat = img.Image(width: image.width, height: image.height);
    img.fill(flat, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(flat, image);
    image = flat;
  }

  for (final quality in const [85, 70, 55, 40]) {
    final jpg = 'data:image/jpeg;base64,${base64Encode(img.encodeJpg(image, quality: quality))}';
    if (jpg.length <= maxImageDataUriLength) return ImageResult.success(jpg);
  }
  return const ImageResult.failed(ImageFailure.tooLarge);
}

String pngBytesToDataUri(Uint8List bytes) => 'data:image/png;base64,${base64Encode(bytes)}';
