import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_signature/signature.dart';
import 'package:vyaparsetu/global/themes.dart';

class SignaturePadWidget extends StatefulWidget {
  final String label;
  final String? initialSignatureUrl;
  final ValueChanged<Uint8List?> onSignatureSaved;
  final VoidCallback? onClear;
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
    final isEmpty = !_control.isFilled;
    if (isEmpty == _hasDrawing) {
      setState(() {
        _hasDrawing = !isEmpty;
      });
    }
  }

  void _clear() {
    _control.clear();
    setState(() {
      _hasDrawing = false;
    });
    widget.onSignatureSaved(null);
    if (widget.onClear != null) {
      widget.onClear!();
    }
  }

  Future<void> _autoSaveSignature() async {
    if (!_control.isFilled) {
      widget.onSignatureSaved(null);
      return;
    }

    try {
      final img = await _control.toImage(
        color: Colors.black,
        background: Colors.white,
        width: 400,
        height: 200,
      );

      if (img != null) {
        final bytes = img.buffer.asUint8List();
        widget.onSignatureSaved(bytes);
      }
    } catch (e) {
      debugPrint('Error converting signature to image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget canvasWidget;

    if (widget.initialSignatureUrl != null &&
        widget.initialSignatureUrl!.isNotEmpty &&
        !_hasDrawing) {
      canvasWidget = Container(
        color: Colors.white,
        child: Center(
          child: Image.network(
            widget.initialSignatureUrl!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Try parsing as data URI if network load fails
              if (widget.initialSignatureUrl!.startsWith('data:image')) {
                try {
                  final base64String =
                      widget.initialSignatureUrl!.split(',')[1];
                  return Image.memory(
                    Uint8List.fromList(base64Decode(base64String)),
                    fit: BoxFit.contain,
                  );
                } catch (_) {}
              }
              return Center(
                child: Text(
                  'No signature saved',
                  style: GoogleFonts.outfit(color: Colors.black54),
                ),
              );
            },
          ),
        ),
      );
    } else {
      canvasWidget = Listener(
        onPointerDown: (_) {
          if (widget.onDrawStart != null) {
            widget.onDrawStart!();
          }
        },
        onPointerUp: (_) {
          if (widget.onDrawEnd != null) {
            widget.onDrawEnd!();
          }
          _autoSaveSignature();
        },
        onPointerCancel: (_) {
          if (widget.onDrawEnd != null) {
            widget.onDrawEnd!();
          }
          _autoSaveSignature();
        },
        child: HandSignature(
          control: _control,
          color: Colors.black,
          width: 3.0,
          maxWidth: 6.0,
          type: SignatureDrawType.shape,
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
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white, // Draw signatures always on white background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.gray700 : AppTheme.gray200,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: canvasWidget,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (widget.initialSignatureUrl != null &&
                    widget.initialSignatureUrl!.isNotEmpty &&
                    !_hasDrawing) ...[
                  const Icon(
                    Icons.verified_user_rounded,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Saved signature loaded',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ] else if (_hasDrawing) ...[
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.indigo,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Signature captured',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.indigo,
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.gesture_rounded,
                    color: Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Draw signature inside box',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
            if (_hasDrawing ||
                (widget.initialSignatureUrl != null &&
                    widget.initialSignatureUrl!.isNotEmpty))
              TextButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.clear, size: 18),
                label: Text('Clear', style: GoogleFonts.outfit(fontSize: 14)),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
