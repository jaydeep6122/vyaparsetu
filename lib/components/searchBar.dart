import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vyaparsetu/global/themes.dart';

class AppSearchBar extends StatefulWidget {
  final String hintText;
  final void Function(String) onChanged;
  final Duration debounceDuration;

  const AppSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.debounceDuration = const Duration(milliseconds: 350),
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      style: GoogleFonts.outfit(fontSize: 13, color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: GoogleFonts.outfit(
          fontSize: 13,
          color: isDark ? AppTheme.gray400 : AppTheme.gray400,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: isDark ? AppTheme.gray400 : AppTheme.gray400,
          size: 16,
        ),
        suffixIcon: _hasText
            ? IconButton(
                icon: Icon(Icons.close_rounded, size: 16, color: isDark ? AppTheme.gray400 : AppTheme.gray500),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                  FocusScope.of(context).unfocus();
                },
              )
            : null,
        filled: true,
        fillColor: isDark ? AppTheme.gray700 : AppTheme.gray100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppTheme.primaryDark : AppTheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
