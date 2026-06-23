import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/factorySetup/worker.dart';
import 'package:vyaparsetu/components/searchBar.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/errorWidget.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/screens/factorySetup/workers/form.dart';
import 'package:vyaparsetu/screens/factorySetup/workers/detail.dart';
import 'package:vyaparsetu/core/Core.dart';

class WorkerListScreen extends StatefulWidget {
  final String factoryId;
  const WorkerListScreen({super.key, required this.factoryId});

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  String _searchQuery = '';
  String _filterType = 'producer_molder';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData({bool force = false}) {
    final module = context.read<Core>().factory;
    if (force || module.workers.isEmpty) {
      module.fetchWorkers(widget.factoryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading = context.select<Core, bool>(
      (c) => c.factory.isLoadingWorkers,
    );
    final workers = context.select<Core, List<Worker>>(
      (c) => c.factory.workers,
    );
    final error = context.select<Core, String?>(
      (c) => c.factory.workersError,
    );

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: AppSearchBar(
              hintText: 'factory.search_workers'.tr(),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilter('producer_molder', WorkerType.producer_molder.displayName),
                const SizedBox(width: 8),
                _buildFilter('kiln_worker', WorkerType.kiln_worker.displayName),
                const SizedBox(width: 8),
                _buildFilter('truck_worker', WorkerType.truck_worker.displayName),
              ],
            ),
          ),
          if (isLoading && workers.isNotEmpty)
            const LinearProgressIndicator(),
          Expanded(
            child: RefreshIndicator(
              color: isDark ? Colors.white : AppTheme.primary,
              onRefresh: () async => _loadData(force: true),
              child: _buildBody(isDark, isLoading, workers, error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter(String type, String label) {
    final isSelected = _filterType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        setState(() => _filterType = type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.primaryDark : AppTheme.primary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppTheme.primaryDark : AppTheme.primary)
                : (isDark ? AppTheme.gray600 : AppTheme.gray300),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? AppTheme.gray400 : AppTheme.gray600),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    bool isDark, bool isLoading, List<Worker> workers, String? error,
  ) {
    if (isLoading && workers.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: LoadingIndicator(
            message: 'factory.loading_workers'.tr(), isShimmer: true,
          ),
        ),
      );
    }

    if (error != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: AppErrorWidget(errorMessage: error, onRetry: () => _loadData(force: true)),
        ),
      );
    }

    if (workers.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: EmptyState(
            icon: Icons.people_outline_rounded,
            title: 'factory.no_workers'.tr(),
            description: 'factory.add_workers_started'.tr(),
            buttonText: 'factory.add_worker'.tr(),
            onButtonPressed: () {
              Navigator.of(context).push(
                getPageRoute(WorkerFormScreen(factoryId: widget.factoryId)),
              ).then((_) {
                if (mounted) _loadData(force: true);
              });
            },
          ),
        ),
      );
    }

    final filtered = workers.where((w) {
      final matchesType = w.workerType.name == _filterType;
      final matchesSearch = _searchQuery.isEmpty ||
          w.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesType && matchesSearch;
    }).toList();

    if (filtered.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: EmptyState(
            icon: Icons.people_outline_rounded,
            title: 'factory.no_workers_found'.tr(),
            description: _searchQuery.isNotEmpty
                ? 'factory.no_worker_matches'.tr()
                : 'factory.no_workers_category'.tr(),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final worker = filtered[index];
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
                getPageRoute(
                  WorkerDetailScreen(
                    factoryId: widget.factoryId,
                    workerId: worker.id,
                  ),
                ),
              );
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
                      Icons.person_outline_rounded,
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
                          worker.name,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : AppTheme.gray900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          worker.workerType.displayName,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.formatCurrency(worker.balanceDue),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: worker.balanceDue > 0
                              ? AppTheme.success
                              : (worker.balanceDue < 0
                                  ? AppTheme.error
                                  : (isDark ? Colors.white : AppTheme.gray900)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${worker.totalBricks} ${'factory.bricks'.tr()}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppTheme.gray500,
                        ),
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
}
