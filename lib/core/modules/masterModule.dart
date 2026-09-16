import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/core/components/moduleBase.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/types/item.dart';

/// GST tax rates and item/expense categories of the selected business.
class MasterModule extends CoreModule {
  MasterModule(super.core);

  final LoadState<List<TaxRate>> taxRates = LoadState();
  final LoadState<List<Category>> itemCategories = LoadState();
  final LoadState<List<Category>> expenseCategories = LoadState();

  LoadState<List<Category>> categories(CategoryKind kind) =>
      kind == CategoryKind.item ? itemCategories : expenseCategories;

  List<TaxRate> get activeTaxRates =>
      (taxRates.value ?? []).where((rate) => rate.isActive).toList();

  List<Category> activeCategories(CategoryKind kind) =>
      (categories(kind).value ?? []).where((c) => !c.isArchived).toList();

  Future<List<TaxRate>?> fetchTaxRates({bool refresh = false}) {
    final businessId = core.businessId;
    return loadValue(
      taxRates,
      () async => (await Api.instance.master.taxRates(businessId))
          .map(TaxRate.fromJson)
          .toList(),
      refresh: refresh,
    );
  }

  /// Includes archived categories, so screens can offer to restore them.
  Future<List<Category>?> fetchCategories(
    CategoryKind kind, {
    bool refresh = false,
  }) {
    final businessId = core.businessId;
    return loadValue(
      categories(kind),
      () async => (await Api.instance.master.categories(
        businessId,
        kind,
        includeArchived: true,
      ))
          .map(Category.fromJson)
          .toList(),
      refresh: refresh,
    );
  }

  Future<TaxRate?> createTaxRate({
    required String rate,
    String? cessRate,
    String? name,
  }) async {
    final json = await runSave(
      () => Api.instance.master.createTaxRate(
        core.businessId,
        rate: rate,
        cessRate: cessRate,
        name: name,
      ),
    );
    if (json == null) return null;
    await fetchTaxRates(refresh: true);
    return TaxRate.fromJson(json);
  }

  Future<bool> setTaxRateActive(String taxRateId, {required bool isActive}) async {
    final json = await runSave(
      () => Api.instance.master.updateTaxRate(
        core.businessId,
        taxRateId,
        isActive: isActive,
      ),
    );
    if (json == null) return false;
    await fetchTaxRates(refresh: true);
    return true;
  }

  Future<Category?> createCategory(CategoryKind kind, String name) async {
    final json = await runSave(
      () => Api.instance.master.createCategory(core.businessId, kind, name),
    );
    if (json == null) return null;
    await fetchCategories(kind, refresh: true);
    return Category.fromJson(json);
  }

  Future<bool> renameCategory(
    CategoryKind kind,
    String categoryId,
    String name,
  ) async {
    final json = await runSave(
      () => Api.instance.master.renameCategory(
        core.businessId,
        kind,
        categoryId,
        name,
      ),
    );
    if (json == null) return false;
    await fetchCategories(kind, refresh: true);
    return true;
  }

  Future<bool> setCategoryArchived(
    CategoryKind kind,
    String categoryId, {
    required bool archived,
  }) async {
    final json = await runSave(
      () => Api.instance.master.setCategoryArchived(
        core.businessId,
        kind,
        categoryId,
        archived: archived,
      ),
    );
    if (json == null) return false;
    await fetchCategories(kind, refresh: true);
    return true;
  }

  void clear() {
    taxRates.reset();
    itemCategories.reset();
    expenseCategories.reset();
  }
}
