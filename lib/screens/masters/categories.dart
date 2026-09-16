import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/sectionHeader.dart';
import 'package:vyaparsetu/components/textInputDialog.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/types/item.dart';

/// Item or expense categories.
class CategoriesScreen extends StatefulWidget {
  final CategoryKind kind;

  const CategoriesScreen({super.key, required this.kind});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() =>
      context.read<Core>().master.fetchCategories(widget.kind, refresh: true);

  Future<void> _add() async {
    final name = await showTextInputDialog(
      context,
      title: 'new_category'.tr(),
      label: 'category_name'.tr(),
      textCapitalization: TextCapitalization.words,
    );
    if (name == null || !mounted) return;
    final master = context.read<Core>().master;
    if (await master.createCategory(widget.kind, name) == null) {
      showErrorToast(master.error ?? 'error_generic'.tr());
    }
  }

  Future<void> _rename(Category category) async {
    final name = await showTextInputDialog(
      context,
      title: 'rename_category'.tr(),
      label: 'category_name'.tr(),
      initialValue: category.name,
      textCapitalization: TextCapitalization.words,
    );
    if (name == null || name == category.name || !mounted) return;
    final master = context.read<Core>().master;
    if (!await master.renameCategory(widget.kind, category.id, name)) {
      showErrorToast(master.error ?? 'error_generic'.tr());
    }
  }

  Future<void> _setArchived(Category category, bool archived) async {
    final master = context.read<Core>().master;
    if (!await master.setCategoryArchived(widget.kind, category.id, archived: archived)) {
      showErrorToast(master.error ?? 'error_generic'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final canArchive = core.can(MemberRole.accountant);
    final title = widget.kind == CategoryKind.item
        ? 'item_categories'.tr()
        : 'expense_categories'.tr();

    Widget tile(Category category) => ListTile(
      title: Text(
        category.name,
        style: category.isArchived ? TextStyle(color: context.colors.muted) : null,
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (action) => switch (action) {
          'rename' => _rename(category),
          'archive' => _setArchived(category, true),
          _ => _setArchived(category, false),
        },
        itemBuilder: (_) => [
          if (!category.isArchived) PopupMenuItem(value: 'rename', child: Text('rename'.tr())),
          if (canArchive)
            category.isArchived
                ? PopupMenuItem(value: 'restore', child: Text('restore'.tr()))
                : PopupMenuItem(value: 'archive', child: Text('archive'.tr())),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-category',
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: Text('add_category'.tr()),
      ),
      body: LoadStateBody<List<Category>>(
        state: core.master.categories(widget.kind),
        onRetry: _refresh,
        builder: (context, categories) {
          final active = categories.where((c) => !c.isArchived).toList();
          final archived = categories.where((c) => c.isArchived).toList();
          if (categories.isEmpty) {
            return EmptyState(
              icon: Icons.category_outlined,
              title: 'no_categories_yet'.tr(),
              description: 'categories_hint'.tr(),
              buttonText: 'add_category'.tr(),
              onButtonPressed: _add,
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLg,
                AppTheme.spaceSm,
                AppTheme.spaceLg,
                AppTheme.fabClearance,
              ),
              children: [
                if (active.isNotEmpty)
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final (index, category) in active.indexed) ...[
                          if (index > 0) const Divider(indent: AppTheme.spaceLg),
                          tile(category),
                        ],
                      ],
                    ),
                  ),
                if (archived.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.space2xl),
                  SectionHeader(title: 'archived'.tr()),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final (index, category) in archived.indexed) ...[
                          if (index > 0) const Divider(indent: AppTheme.spaceLg),
                          tile(category),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
