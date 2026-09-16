import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/global/themes.dart';

/// Bottom sheet to choose one option, with search.
///
/// Pass [options] to filter locally, or [onSearch] to fetch results from the
/// server as the user types. [onCreate] adds an "add new" button whose result
/// is returned as the choice (e.g. create a party without leaving the bill).
Future<T?> showPickerSheet<T>({
  required BuildContext context,
  required String title,
  required String Function(T option) labelOf,
  List<T> options = const [],
  Future<List<T>> Function(String query)? onSearch,
  String? Function(T option)? subtitleOf,
  Widget? Function(T option)? trailingOf,
  bool Function(T option)? isSelected,
  bool searchable = true,
  String? searchHint,
  String? emptyText,
  String? createLabel,
  Future<T?> Function(BuildContext context)? onCreate,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PickerSheet<T>(
      title: title,
      labelOf: labelOf,
      options: options,
      onSearch: onSearch,
      subtitleOf: subtitleOf,
      trailingOf: trailingOf,
      isSelected: isSelected,
      searchable: searchable,
      searchHint: searchHint,
      emptyText: emptyText,
      createLabel: createLabel,
      onCreate: onCreate,
    ),
  );
}

class _PickerSheet<T> extends StatefulWidget {
  final String title;
  final String Function(T option) labelOf;
  final List<T> options;
  final Future<List<T>> Function(String query)? onSearch;
  final String? Function(T option)? subtitleOf;
  final Widget? Function(T option)? trailingOf;
  final bool Function(T option)? isSelected;
  final bool searchable;
  final String? searchHint;
  final String? emptyText;
  final String? createLabel;
  final Future<T?> Function(BuildContext context)? onCreate;

  const _PickerSheet({
    required this.title,
    required this.labelOf,
    required this.options,
    this.onSearch,
    this.subtitleOf,
    this.trailingOf,
    this.isSelected,
    required this.searchable,
    this.searchHint,
    this.emptyText,
    this.createLabel,
    this.onCreate,
  });

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  final _controller = TextEditingController();
  Timer? _debounce;
  late List<T> _results = widget.options;
  bool _loading = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    if (widget.onSearch != null) _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    if (widget.onSearch == null) {
      final needle = query.trim().toLowerCase();
      setState(() {
        _results = widget.options.where((option) {
          final label = widget.labelOf(option).toLowerCase();
          final subtitle = widget.subtitleOf?.call(option)?.toLowerCase() ?? '';
          return label.contains(needle) || subtitle.contains(needle);
        }).toList();
      });
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query));
  }

  Future<void> _search(String query) async {
    final generation = ++_generation;
    setState(() => _loading = true);
    final results = await widget.onSearch!(query.trim());
    if (!mounted || generation != _generation) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  Future<void> _create() async {
    final created = await widget.onCreate!(context);
    if (created != null && mounted) Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
            child: Text(widget.title, style: context.text.titleLarge),
          ),
          if (widget.searchable)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLg,
                AppTheme.spaceMd,
                AppTheme.spaceLg,
                AppTheme.spaceSm,
              ),
              child: TextField(
                controller: _controller,
                onChanged: _onQueryChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: widget.searchHint ?? 'search'.tr(),
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                ),
              ),
            ),
          SizedBox(
            height: 2,
            child: _loading ? const LinearProgressIndicator(minHeight: 2) : null,
          ),
          Expanded(
            child: _results.isEmpty && !_loading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.space2xl),
                      child: Text(
                        widget.emptyText ?? 'picker_no_results'.tr(),
                        style: context.text.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const Divider(indent: AppTheme.spaceLg),
                    itemBuilder: (context, index) {
                      final option = _results[index];
                      final subtitle = widget.subtitleOf?.call(option);
                      final selected = widget.isSelected?.call(option) ?? false;
                      return ListTile(
                        minVerticalPadding: AppTheme.spaceMd,
                        title: Text(widget.labelOf(option)),
                        subtitle: subtitle == null ? null : Text(subtitle),
                        trailing: selected
                            ? Icon(Icons.check_rounded, color: colors.primary)
                            : widget.trailingOf?.call(option),
                        onTap: () => Navigator.of(context).pop(option),
                      );
                    },
                  ),
          ),
          if (widget.onCreate != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                child: AppButton(
                  text: widget.createLabel ?? 'add_new'.tr(),
                  icon: Icons.add_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: _create,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
