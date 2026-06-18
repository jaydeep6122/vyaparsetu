import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/errorWidget.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/business/form.dart';
import 'package:vyaparsetu/screens/home/home.dart';
import 'package:vyaparsetu/core/Core.dart';

class BusinessListScreen extends StatefulWidget {
  const BusinessListScreen({super.key});

  @override
  State<BusinessListScreen> createState() => _BusinessListScreenState();
}

class _BusinessListScreenState extends State<BusinessListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<Core>().business.fetchBusinesses();
    });
  }

  void _onBusinessSelected(Business business) async {
    final businessProvider = context.read<Core>().business;
    await businessProvider.selectBusiness(business);
    if (mounted) {
      Navigator.of(context).pushReplacement(getPageRoute(const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading = context.select<Core, bool>((c) => c.business.isLoading);
    final error = context.select<Core, String?>((c) => c.business.error);
    final businesses = context.select<Core, List<Business>>((c) => c.business.businesses);
    final selectedBusinessId = context.select<Core, String?>((c) => c.business.selectedBusiness?.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'select_business'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(getPageRoute(const BusinessFormScreen()));
            },
          ),
        ],
      ),
      body: _buildList(isLoading, error, businesses, selectedBusinessId, theme, isDark),
    );
  }

  Widget _buildList(bool isLoading, String? error, List<Business> businesses, String? selectedBusinessId, ThemeData theme, bool isDark) {
    final sorted = List<Business>.from(businesses)..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    businesses = sorted;
    if (isLoading) {
      return const LoadingIndicator(message: 'Loading businesses...', isShimmer: true);
    }
    if (error != null) {
      return AppErrorWidget(
        errorMessage: error,
        onRetry: () => context.read<Core>().business.fetchBusinesses(),
      );
    }
    if (businesses.isEmpty) {
      return EmptyState(
        icon: Icons.store_rounded,
        title: 'no_businesses_found'.tr(),
        description: 'Create your first business profile to get started.',
        buttonText: 'add_business'.tr(),
        onButtonPressed: () {
          Navigator.of(context).push(getPageRoute(const BusinessFormScreen()));
        },
      );
    }
    return RefreshIndicator(
      color: isDark ? Colors.white : AppTheme.primary,
      onRefresh: () => context.read<Core>().business.fetchBusinesses(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: businesses.length,
        itemBuilder: (context, index) {
          final b = businesses[index];
          final isSelected = selectedBusinessId == b.id;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              side: BorderSide(
                color: isSelected
                    ? (isDark ? Colors.white : AppTheme.primary)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              onTap: () => _onBusinessSelected(b),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.primary.withValues(alpha: 0.08))
                            : (isDark ? AppTheme.gray800 : AppTheme.gray100),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: b.logoUrl != null && b.logoUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              child: Image.network(
                                b.logoUrl!,
                                fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.store_rounded,
                                    color: isSelected ? (isDark ? Colors.white : AppTheme.primary) : AppTheme.gray400,
                                  ),
                              ),
                            )
                          : Icon(
                              Icons.store_rounded,
                              color: isSelected ? (isDark ? Colors.white : AppTheme.primary) : AppTheme.gray400,
                              size: 28,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: theme.textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${b.city}, ${b.state}',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                            ),
                          ),
                          if (b.gstin != null && b.gstin!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'GSTIN: ${b.gstin}',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: isDark ? Colors.white : AppTheme.primary,
                        size: 28,
                      )
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.iconTheme.color?.withValues(alpha: 0.4),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
