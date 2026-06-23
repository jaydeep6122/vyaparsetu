import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/party.dart';
import 'package:vyaparsetu/components/searchBar.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/errorWidget.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/screens/parties/form.dart';
import 'package:vyaparsetu/screens/parties/detail.dart';
import 'package:vyaparsetu/core/Core.dart';

class PartyListScreen extends StatefulWidget {
  const PartyListScreen({super.key});

  @override
  State<PartyListScreen> createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen> {
  String _searchQuery = '';
  String _filterType = 'customer';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId != null) {
context.read<Core>().party.fetchParties(businessId);
    }
  }

  List<Party> _filterParties(List<Party> list) {
    return list.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.phone != null && p.phone!.contains(_searchQuery));

      if (!matchesSearch) return false;

      if (_filterType == 'customer') {
        return p.partyType == PartyType.customer || p.partyType == PartyType.both;
      }
      return p.partyType == PartyType.supplier || p.partyType == PartyType.both;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final businessId = context.select<Core, String?>((c) => c.business.selectedBusiness?.id);
    final isLoading = context.select<Core, bool>((c) => c.party.isLoading);
    final parties = context.select<Core, List<Party>>((c) => c.party.parties);
    final error = context.select<Core, String?>((c) => c.party.error);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: AppSearchBar(
              hintText: 'Search parties by name or phone...',
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterButton('customers'.tr(), 'customer'),
                const SizedBox(width: 8),
                _buildFilterButton('suppliers'.tr(), 'supplier'),
              ],
            ),
          ),
          if (isLoading && parties.isNotEmpty)
            const LinearProgressIndicator(),
          Expanded(
            child: RefreshIndicator(
              color: isDark ? Colors.white : AppTheme.primary,
              onRefresh: () async {
                if (businessId != null) {
                  await context.read<Core>().party.fetchParties(businessId);
                }
              },
              child: _buildPartyList(isDark, theme, isLoading, parties, error, businessId),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'parties_fab',
        onPressed: () {
          final initialType =
              _filterType == 'customer' ? PartyType.customer : PartyType.supplier;
          Navigator.of(context).push(
            getPageRoute(PartyFormScreen(initialPartyType: initialType)),
          ).then((_) {
            if (mounted) _loadData();
          });
        },
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
    );
  }

  Widget _buildPartyList(bool isDark, ThemeData theme, bool isLoading, List<Party> parties, String? error, String? businessId) {
    if (isLoading && parties.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: const LoadingIndicator(message: 'Loading parties...', isShimmer: true),
        ),
      );
    }

    if (error != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: AppErrorWidget(errorMessage: error, onRetry: _loadData),
        ),
      );
    }

    final filtered = _filterParties(parties);

    if (filtered.isEmpty) {
      final isCustomer = _filterType == 'customer';
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: EmptyState(
            icon: isCustomer ? Icons.person_outline_rounded : Icons.business_outlined,
            title: isCustomer ? 'No customers found' : 'No suppliers found',
            description: _searchQuery.isNotEmpty
                ? 'No match for "$_searchQuery" inside this category.'
                : isCustomer
                    ? 'No customer contacts found. Use the "+" button to add one.'
                    : 'No supplier contacts found. Use the "+" button to add one.',
            buttonText: null,
            onButtonPressed: null,
          ),
        ),
      );
    }

    return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final party = filtered[index];
          final isPositive = party.currentBalance > 0;
          final isNegative = party.currentBalance < 0;
          final balanceLabel = isPositive
              ? 'To Receive'
              : isNegative
                  ? 'To Pay'
                  : 'Settled';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: isDark ? AppTheme.gray800 : AppTheme.slate50,
                width: 1.5,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              onTap: () {
                Navigator.of(context).push(
                  getPageRoute(PartyDetailScreen(party: party)),
                ).then((_) {
                  if (mounted) _loadData();
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Icon(
                        party.partyType == PartyType.customer
                            ? Icons.person_outline_rounded
                            : party.partyType == PartyType.supplier
                                ? Icons.business_outlined
                                : Icons.handshake_outlined,
                        color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            party.name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : AppTheme.gray900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            party.phone ?? 'No phone',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isNegative ? '-' : ''}${Formatters.formatCurrency(party.currentBalance.abs())}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark ? Colors.white : AppTheme.gray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isPositive
                                    ? AppTheme.success
                                    : isNegative
                                        ? AppTheme.error
                                        : AppTheme.gray400,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              balanceLabel,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.gray500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
  }

  Widget _buildFilterButton(String text, String type) {
    final theme = Theme.of(context);
    final isSelected = _filterType == type;
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filterType = type;
          });
          _loadData();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: isSelected
                      ? (isDark ? Colors.white : AppTheme.primary)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : AppTheme.primary)
                    : (isDark ? AppTheme.gray400 : AppTheme.gray400),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
