import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final bool isOutlined;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.isOutlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isSecondary) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.error,
            textStyle: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
          child: _buildChild(isDark),
        ),
      );
    }

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? AppTheme.primaryDark : AppTheme.primary,
            side: BorderSide(
              color: isDark ? AppTheme.primaryDark : AppTheme.primary,
            ),
            textStyle: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
          child: _buildChild(isDark),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: (isDark ? AppTheme.primaryDark : AppTheme.primary)
              .withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: _buildChild(isDark),
      ),
    );
  }

  Widget _buildChild(bool isDark) {
    if (isLoading) {
      final Color spinnerColor;
      if (isSecondary) {
        spinnerColor = AppTheme.error;
      } else if (isOutlined) {
        spinnerColor = isDark ? AppTheme.primaryDark : AppTheme.primary;
      } else {
        spinnerColor = Colors.white;
      }
      return SizedBox(
        height: 20,
        width: 20,
        child: AppSpinner(
          size: 20,
          color: spinnerColor,
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Text(text),
      ],
    );
  }
}
