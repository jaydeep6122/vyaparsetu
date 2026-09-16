
import 'package:flutter/material.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';

enum AmountTone {
  /// Plain text colour.
  neutral,

  /// Green: money received.
  positive,

  /// Red: money owed or going out.
  negative,

  /// Green above zero, red below zero.
  bySign,
}

/// A rupee amount with digits that line up in columns.
class AmountDisplay extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final AmountTone tone;

  /// Prefix negative amounts with "-" (otherwise the absolute value is shown).
  final bool showMinus;

  const AmountDisplay({
    super.key,
    required this.amount,
    this.style,
    this.tone = AmountTone.neutral,
    this.showMinus = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = style ?? context.text.titleMedium!;
    final color = switch (tone) {
      AmountTone.neutral => base.color ?? colors.ink,
      AmountTone.positive => colors.success,
      AmountTone.negative => colors.danger,
      AmountTone.bySign => amount > 0.004
          ? colors.success
          : amount < -0.004
          ? colors.danger
          : colors.ink,
    };

    final sign = showMinus && amount < -0.004 ? '-' : '';
    return Text(
      '$sign${Formatters.formatCurrency(amount.abs())}',
      style: base.copyWith(
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
