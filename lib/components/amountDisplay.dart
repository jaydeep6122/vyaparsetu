import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';

class AmountDisplay extends StatelessWidget {
  final double amount;
  final double fontSize;
  final FontWeight fontWeight;
  final bool isReceivableStyle;
  final bool isExpenseStyle;

  const AmountDisplay({
    super.key,
    required this.amount,
    this.fontSize = 16,
    this.fontWeight = FontWeight.bold,
    this.isReceivableStyle = false,
    this.isExpenseStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    if (isReceivableStyle) {
      if (amount > 0) {
        color = AppTheme.success;
      } else if (amount < 0) {
        color = AppTheme.error;
      }
    } else if (isExpenseStyle) {
      color = AppTheme.error;
    }

    final displayValue = Formatters.formatCurrency(amount.abs());
    final displaySign = amount < 0 && isReceivableStyle ? '-' : '';

    return Text(
      '$displaySign$displayValue',
      style: GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}
