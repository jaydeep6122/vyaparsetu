import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vyaparsetu/global/themes.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color dotColor;

  const StatusChip({
    super.key,
    required this.label,
    required this.dotColor,
  });

  factory StatusChip.paid() {
    return const StatusChip(
      label: 'Paid',
      dotColor: AppTheme.success,
    );
  }

  factory StatusChip.unpaid() {
    return const StatusChip(
      label: 'Unpaid',
      dotColor: AppTheme.error,
    );
  }

  factory StatusChip.partiallyPaid() {
    return const StatusChip(
      label: 'Partially Paid',
      dotColor: AppTheme.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray500,
          ),
        ),
      ],
    );
  }
}
