import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/global/themes.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String? cancelText;
  final bool isDestructive;
  final IconData? icon;
  final Widget? additionalContent;

  ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    String? confirmText,
    this.cancelText,
    this.isDestructive = false,
    this.icon,
    this.additionalContent,
  }) : confirmText = confirmText ?? 'confirm'.tr();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      icon: icon != null
          ? Padding(
              padding: const EdgeInsets.only(top: AppTheme.spaceSm),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: isDestructive
                    ? AppTheme.error.withOpacity(0.1)
                    : AppTheme.primary.withOpacity(0.1),
                child: Icon(
                  icon,
                  size: 28,
                  color: isDestructive
                      ? AppTheme.error
                      : (isDark ? Colors.white : AppTheme.primary),
                ),
              ),
            )
          : null,
      title: Padding(
        padding: const EdgeInsets.only(top: AppTheme.spaceXs),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: theme.textTheme.bodyMedium?.color,
                height: 1.4,
              ),
            ),
            if (additionalContent != null) ...[
              const SizedBox(height: AppTheme.spaceMd),
              additionalContent!,
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      actions: [
        Padding(
          padding: const EdgeInsets.only(top: AppTheme.spaceSm),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textTheme.bodyMedium?.color,
                    side: BorderSide(
                      color: isDark ? AppTheme.gray600 : AppTheme.gray300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    cancelText ?? 'cancel'.tr(),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: isDestructive
                        ? AppTheme.error
                        : AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    confirmText,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
