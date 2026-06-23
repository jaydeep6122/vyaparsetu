import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/factorySetup/factory.dart';
import 'package:vyaparsetu/components/searchBar.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/errorWidget.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/factorySetup/factory/form.dart';
import 'package:vyaparsetu/screens/factorySetup/factory/detail.dart';
import 'package:vyaparsetu/core/Core.dart';

class FactoryListScreen extends StatefulWidget {
  final bool selectionMode;
  const FactoryListScreen({super.key, this.selectionMode = false});

  @override
  State<FactoryListScreen> createState() => _FactoryListScreenState();
}

class _FactoryListScreenState extends State<FactoryListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    context.read<Core>().factory.fetchFactories(search: _searchQuery);
  }

  void _onFactoryTap(Factory factory) {
    if (widget.selectionMode) {
      context.read<Core>().factory.selectFactory(factory);
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).push(
        getPageRoute(FactoryDetailScreen(factoryId: factory.id)),
      ).then((_) {
        if (mounted) _loadData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading = context.select<Core, bool>((c) => c.factory.isLoadingFactories);
    final factories = context.select<Core, List<Factory>>((c) => c.factory.factories);
    final error = context.select<Core, String?>((c) => c.factory.factoriesError);
    final selectedId = context.select<Core, String?>(
      (c) => c.factory.selectedFactory?.id,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.selectionMode ? 'factory.select_factory'.tr() : 'factory.manage_factories'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: AppSearchBar(
              hintText: 'factory.search_factories'.tr(),
              onChanged: (val) {
                setState(() => _searchQuery = val);
                _loadData();
              },
            ),
          ),
          if (isLoading && factories.isNotEmpty)
            const LinearProgressIndicator(),
          Expanded(
            child: RefreshIndicator(
              color: isDark ? Colors.white : AppTheme.primary,
              onRefresh: () async => _loadData(),
              child: _buildBody(isDark, isLoading, factories, error, selectedId),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'factory_fab',
        onPressed: () {
          Navigator.of(context).push(
            getPageRoute(const FactoryFormScreen()),
          ).then((_) {
            if (mounted) _loadData();
          });
        },
        child: const Icon(Icons.add_business_rounded),
      ),
    );
  }

  Widget _buildBody(bool isDark, bool isLoading, List<Factory> factories, String? error, String? selectedId) {
    if (isLoading && factories.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: LoadingIndicator(message: 'factory.loading_factories'.tr(), isShimmer: true),
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

    if (factories.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: EmptyState(
            icon: Icons.factory_outlined,
            title: 'factory.no_factories'.tr(),
            description: 'factory.add_factory_started'.tr(),
            buttonText: 'factory.add_factory'.tr(),
            onButtonPressed: () {
              Navigator.of(context).push(
                getPageRoute(const FactoryFormScreen()),
              ).then((_) {
                if (mounted) _loadData();
              });
            },
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: factories.length,
      itemBuilder: (context, index) {
        final factory = factories[index];
        final isSelected = factory.id == selectedId;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primary
                  : isDark
                      ? AppTheme.gray800
                      : AppTheme.slate50,
              width: isSelected ? 2.0 : 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            onTap: () => _onFactoryTap(factory),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.15)
                          : (isDark ? AppTheme.gray800 : AppTheme.gray100),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      isSelected ? Icons.factory_rounded : Icons.factory_outlined,
                      color: isSelected ? AppTheme.primary : (isDark ? AppTheme.gray400 : AppTheme.gray500),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          factory.name,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : AppTheme.gray900,
                          ),
                        ),
                        if (factory.location != null && factory.location!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            factory.location!,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSelected && widget.selectionMode)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    )
                  else ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${factory.workerCount} ${'factory.worker_count'.tr()}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? Colors.white : AppTheme.gray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusChip(factory.status, isDark),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status, bool isDark) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.success.withValues(alpha: isDark ? 0.2 : 0.1)
            : AppTheme.gray400.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? 'factory.active'.tr() : 'factory.inactive'.tr(),
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isActive ? AppTheme.success : AppTheme.gray500,
        ),
      ),
    );
  }
}
