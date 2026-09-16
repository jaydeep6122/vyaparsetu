import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hand_signature/signature.dart';
import 'package:vyaparsetu/components/avatar.dart';
import 'package:vyaparsetu/global/themes.dart';

/// Pad to draw a signature. Reports PNG bytes when a stroke ends, or null
/// when cleared.
class SignaturePadWidget extends StatefulWidget {
  final String label;
  final String? initialSignatureUrl;
  final ValueChanged<Uint8List?> onSignatureSaved;
  final VoidCallback? onClear;

  /// Called when drawing starts/ends, so a parent scroll view can be locked
  /// while the user signs.
  final VoidCallback? onDrawStart;
  final VoidCallback? onDrawEnd;

  const SignaturePadWidget({
    super.key,
    required this.label,
    this.initialSignatureUrl,
    required this.onSignatureSaved,
    this.onClear,
    this.onDrawStart,
    this.onDrawEnd,
  });

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  final HandSignatureControl _control = HandSignatureControl();
  bool _hasDrawing = false;
  bool _showSaved = true;

  @override
  void initState() {
    super.initState();
    _control.addListener(_onDrawChanged);
  }

  @override
  void dispose() {
    _control.removeListener(_onDrawChanged);
    super.dispose();
  }

  void _onDrawChanged() {
    if (_control.isFilled != _hasDrawing) {
      setState(() => _hasDrawing = _control.isFilled);
    }
  }

  void _clear() {
    _control.clear();
    setState(() {
      _hasDrawing = false;
      _showSaved = false;
    });
    widget.onSignatureSaved(null);
    widget.onClear?.call();
  }

  Future<void> _save() async {
    if (!_control.isFilled) {
      widget.onSignatureSaved(null);
      return;
    }
    try {
      final image = await _control.toImage(
        color: Colors.black,
        background: Colors.white,
        width: 400,
        height: 200,
      );
      if (image != null) widget.onSignatureSaved(image.buffer.asUint8List());
    } catch (_) {
      // Keep the drawing on screen; the user can try again.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final savedUrl = widget.initialSignatureUrl;
    final showingSaved =
        _showSaved && !_hasDrawing && savedUrl != null && savedUrl.isNotEmpty;

    Widget canvas;
    if (showingSaved) {
      final bytes = decodeImageDataUri(savedUrl);
      canvas = Center(
        child: bytes != null
            ? Image.memory(bytes, fit: BoxFit.contain)
            : Image.network(
                savedUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Text(
                  'signature_none'.tr(),
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
      );
    } else {
      canvas = Listener(
        onPointerDown: (_) => widget.onDrawStart?.call(),
        onPointerUp: (_) {
          widget.onDrawEnd?.call();
          _save();
        },
        onPointerCancel: (_) {
          widget.onDrawEnd?.call();
          _save();
        },
        child: HandSignature(
          control: _control,
          drawer: const ShapeSignatureDrawer(width: 3.0, maxWidth: 6.0),
        ),
      );
    }

    final (IconData statusIcon, String statusText, Color statusColor) = showingSaved
        ? (Icons.verified_rounded, 'signature_saved_loaded'.tr(), colors.success)
        : _hasDrawing
        ? (Icons.check_circle_rounded, 'signature_captured'.tr(), colors.primary)
        : (Icons.gesture_rounded, 'signature_draw_hint'.tr(), colors.muted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: context.text.labelMedium),
        const SizedBox(height: AppTheme.spaceSm),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            // Always white: the signature is printed on white paper.
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: canvas,
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Row(
          children: [
            Icon(statusIcon, size: 16, color: statusColor),
            const SizedBox(width: AppTheme.spaceXs),
            Expanded(
              child: Text(
                statusText,
                style: context.text.bodySmall?.copyWith(color: statusColor),
              ),
            ),
            if (_hasDrawing || showingSaved)
              TextButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('clear'.tr()),
                style: TextButton.styleFrom(foregroundColor: colors.danger),
              ),
          ],
        ),
      ],
    );
  }
}
