import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/avatar.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/parties/detail.dart';
import 'package:vyaparsetu/types/party.dart';

/// "You'll get ₹500" / "You'll give ₹200" / "Settled".
class PartyBalance extends StatelessWidget {
  final double balance;
  final CrossAxisAlignment alignment;
  final TextStyle? amountStyle;

  const PartyBalance({
    super.key,
    required this.balance,
    this.alignment = CrossAxisAlignment.end,
    this.amountStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (balance.abs() < 0.005) {
      return Text('settled'.tr(), style: context.text.bodySmall);
    }
    final receivable = balance > 0;
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          receivable ? 'you_will_get'.tr() : 'you_will_give'.tr(),
          style: context.text.labelSmall,
        ),
        AmountDisplay(
          amount: balance.abs(),
          tone: receivable ? AmountTone.positive : AmountTone.negative,
          style: amountStyle ?? context.text.titleSmall,
        ),
      ],
    );
  }
}

class PartyTile extends StatelessWidget {
  final Party party;

  const PartyTile({super.key, required this.party});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceMd,
      ),
      onTap: () => Navigator.of(context).push(
        getPageRoute(PartyDetailScreen(partyId: party.id)),
      ),
      child: Row(
        children: [
          InitialsAvatar(name: party.name),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  party.name,
                  style: context.text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        [party.partyType.displayName, ?party.phone].join(' · '),
                        style: context.text.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (party.isArchived) ...[
                      const SizedBox(width: AppTheme.spaceSm),
                      StatusChip(label: 'archived'.tr()),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          PartyBalance(balance: party.balance),
        ],
      ),
    );
  }
}
