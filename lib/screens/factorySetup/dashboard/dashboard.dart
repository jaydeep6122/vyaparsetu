import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/types/factorySetup/factory.dart';
import 'package:vyaparsetu/types/factorySetup/factorySummary.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/components/errorWidget.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/screens/factorySetup/factory/form.dart';
import 'package:vyaparsetu/screens/factorySetup/transactions/handoffForm.dart';
import 'package:vyaparsetu/screens/factorySetup/transactions/directForm.dart';
import 'package:vyaparsetu/screens/factorySetup/transactions/truckDistForm.dart';
import 'package:vyaparsetu/screens/factorySetup/transactions/moneyGivenForm.dart';
import 'package:vyaparsetu/screens/factorySetup/workers/form.dart';
import 'package:vyaparsetu/screens/home/home.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/api/api.dart';

class FactoryDashboardScreen extends StatefulWidget {
  const FactoryDashboardScreen({super.key});

  @override
  State<FactoryDashboardScreen> createState() => _FactoryDashboardScreenState();
}

class _FactoryDashboardScreenState extends State<FactoryDashboardScreen> {
  bool _showAllFactoriesStats = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    try {
      await context.read<Core>().factory.fetchDashboardData();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final factoryModule = context.watch<Core>().factory;
    final selectedFactory = factoryModule.selectedFactory;
    final factories = factoryModule.factories;
    final summaries = factoryModule.summaries;
    final isLoading = factoryModule.isLoadingFactories;
    final error = factoryModule.factoriesError;

    if (isLoading && factories.isEmpty) {
      return LoadingIndicator(message: 'factory.loading_dashboard'.tr());
    }

    if (error != null) {
      return AppErrorWidget(errorMessage: error, onRetry: _loadData);
    }

    if (factories.isEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(
                      alpha: isDark ? 0.15 : 0.08,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.factory_rounded,
                    size: 48,
                    color: isDark ? AppTheme.gray300 : AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'factory.welcome_dashboard'.tr(),
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'factory.dashboard_intro'.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(
                      context,
                    ).push<bool>(getPageRoute(const FactoryFormScreen()));
                    if (result == true && mounted) {
                      _loadData();
                    }
                  },
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text('factory.add_first_factory'.tr()),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Determine metrics depending on scope toggle
    int displayBricks = 0;

    if (_showAllFactoriesStats || selectedFactory == null) {
      displayBricks = summaries.values.fold<int>(
        0,
        (sum, s) => sum + s.totalBricks,
      );
    } else {
      final activeSummary = summaries[selectedFactory.id];
      displayBricks = activeSummary?.totalBricks ?? 0;
    }

    return Scaffold(
      body: RefreshIndicator(
        color: isDark ? Colors.white : AppTheme.primary,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScopeToggle(isDark, selectedFactory),
              _buildSummaryCards(isDark, factories.length, displayBricks),
              const SizedBox(height: 24),
              _buildQuickActions(isDark, selectedFactory),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScopeToggle(bool isDark, Factory? selectedFactory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray800 : AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _showAllFactoriesStats = true);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _showAllFactoriesStats
                      ? (isDark ? AppTheme.primaryDark : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  boxShadow: _showAllFactoriesStats ? AppTheme.shadowSm : null,
                ),
                child: Text(
                  'factory.all_factories'.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _showAllFactoriesStats
                        ? (isDark ? Colors.white : AppTheme.primary)
                        : (isDark ? AppTheme.gray400 : AppTheme.gray600),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: selectedFactory != null
                  ? () {
                      setState(() => _showAllFactoriesStats = false);
                    }
                  : () {
                      showFactorySelectionBottomSheet(context);
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_showAllFactoriesStats && selectedFactory != null
                      ? (isDark ? AppTheme.primaryDark : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  boxShadow: !_showAllFactoriesStats && selectedFactory != null
                      ? AppTheme.shadowSm
                      : null,
                ),
                child: Text(
                  selectedFactory != null
                      ? selectedFactory.name
                      : 'factory.selected_factory'.tr(),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: !_showAllFactoriesStats && selectedFactory != null
                        ? (isDark ? Colors.white : AppTheme.primary)
                        : (isDark ? AppTheme.gray400 : AppTheme.gray600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(bool isDark, int factoryCount, int totalBricks) {
    return Column(
      children: [
        _buildRedesignedStatCard(
          isDark,
          icon: Icons.factory_rounded,
          label: 'factory.factories'.tr(),
          value: '$factoryCount',
          accentColor: const Color(0xFF4F46E5), // Indigo
          subtext: 'factory.chimneys_active'.tr(),
        ),
        const SizedBox(height: 12),
        _buildRedesignedStatCard(
          isDark,
          icon: Icons.inventory_2_rounded,
          label: 'factory.total_bricks'.tr(),
          value: '$totalBricks',
          accentColor: const Color(0xFF0EA5E9), // Cyan
          subtext: 'factory.total_produced'.tr(),
        ),
      ],
    );
  }

  Widget _buildRedesignedStatCard(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? accentColor.withValues(alpha: 0.12)
            : accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gray500,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtext,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.gray500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildQuickActions(bool isDark, Factory? selectedFactory) {
    final actions = [
      ('factory.handoff'.tr(), Icons.compare_arrows_rounded, 'handoff', AppTheme.primary),
      ('factory.direct'.tr(), Icons.edit_note_rounded, 'direct', AppTheme.secondary),
      (
        'factory.truck_distribution'.tr(),
        Icons.local_shipping_rounded,
        'truck_dist',
        AppTheme.accent,
      ),
      ('factory.give_money'.tr(), Icons.payments_rounded, 'money_given', AppTheme.warning),
      (
        'factory.add_worker'.tr(),
        Icons.person_add_alt_1_rounded,
        'add_worker',
        AppTheme.success,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'factory.quick_actions'.tr(),
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.gray900,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions.map((a) {
            final double cardWidth =
                (MediaQuery.of(context).size.width - 44) / 2;
            return SizedBox(
              width: cardWidth,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: isDark ? AppTheme.gray800 : AppTheme.gray200,
                  ),
                  boxShadow: AppTheme.shadowSm,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (selectedFactory == null) {
                        showErrorToast('factory.select_factory_first'.tr());
                        showFactorySelectionBottomSheet(context);
                        return;
                      }

                      Widget form;
                      switch (a.$3) {
                        case 'handoff':
                          form = HandoffFormScreen(
                            factoryId: selectedFactory.id,
                          );
                          break;
                        case 'direct':
                          form = DirectFormScreen(
                            factoryId: selectedFactory.id,
                          );
                          break;
                        case 'truck_dist':
                          form = TruckDistFormScreen(
                            factoryId: selectedFactory.id,
                          );
                          break;
                        case 'money_given':
                          form = MoneyGivenFormScreen(
                            factoryId: selectedFactory.id,
                          );
                          break;
                        case 'add_worker':
                          form = WorkerFormScreen(
                            factoryId: selectedFactory.id,
                          );
                          break;
                        default:
                          return;
                      }

                      Navigator.of(context)
                          .push<Map<String, dynamic>>(getPageRoute(form))
                          .then((change) {
                            if (change != null && mounted) {
                              context.read<Core>().factory.updateLocalStats(selectedFactory.id, change);
                            }
                          });
                    },
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: a.$4.withValues(
                                alpha: isDark ? 0.15 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusXs,
                              ),
                            ),
                            child: Icon(a.$2, size: 16, color: a.$4),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              a.$1,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : AppTheme.gray900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
