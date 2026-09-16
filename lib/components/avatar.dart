import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vyaparsetu/global/themes.dart';

/// Decodes `data:image/...;base64,...`, keeping the last few results so lists
/// do not decode the same logo on every rebuild.
Uint8List? decodeImageDataUri(String? uri) {
  if (uri == null || !uri.startsWith('data:image')) return null;
  final cached = _decodedImages[uri.hashCode];
  if (cached != null) return cached;

  final comma = uri.indexOf(',');
  if (comma < 0) return null;
  try {
    final bytes = base64Decode(uri.substring(comma + 1));
    if (_decodedImages.length >= 8) _decodedImages.remove(_decodedImages.keys.first);
    _decodedImages[uri.hashCode] = bytes;
    return bytes;
  } catch (_) {
    return null;
  }
}

final Map<int, Uint8List> _decodedImages = {};

String initialsOf(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final letters = words.take(2).map((w) => w.characters.first.toUpperCase()).join();
  return letters.isEmpty ? '?' : letters;
}

/// Coloured circle with a person's or business's initials.
class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;

  const InitialsAvatar({super.key, required this.name, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = [
      (colors.primarySoft, colors.primary),
      (colors.infoSoft, colors.info),
      (colors.warningSoft, colors.warning),
      (colors.successSoft, colors.success),
      (colors.dangerSoft, colors.danger),
    ];
    final (background, foreground) =
        palette[name.codeUnits.fold<int>(0, (sum, unit) => sum + unit) % palette.length];

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        initialsOf(name),
        style: context.text.labelLarge?.copyWith(
          color: foreground,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The business logo (inline data URI or web URL), or its initials.
class BusinessLogo extends StatelessWidget {
  final String? logoUrl;
  final String name;
  final double size;

  const BusinessLogo({super.key, required this.logoUrl, required this.name, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final fallback = InitialsAvatar(name: name, size: size);
    final radius = BorderRadius.circular(size * 0.28);

    final bytes = decodeImageDataUri(logoUrl);
    if (bytes != null) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    }

    if (logoUrl != null && logoUrl!.startsWith('http')) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          logoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    }
    return fallback;
  }
}
