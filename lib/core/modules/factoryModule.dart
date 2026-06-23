import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/types/factorySetup/factory.dart';
import 'package:vyaparsetu/types/factorySetup/worker.dart';
import 'package:vyaparsetu/types/factorySetup/transactionLog.dart';
import 'package:vyaparsetu/types/factorySetup/workerSummary.dart';
import 'package:vyaparsetu/types/factorySetup/factorySummary.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/storage/hive/cache.dart';
import 'package:vyaparsetu/helpers/errorHandler.dart';

class FactoryModule {
  final Core core;

  FactoryModule(this.core) {
    try {
      final cachedFacs = CacheBox.getCachedFactories();
      if (cachedFacs.isNotEmpty) {
        _factories = cachedFacs.map((e) => Factory.fromJson(e)).toList();
      }

      final cachedSums = CacheBox.getCachedSummaries();
      if (cachedSums.isNotEmpty) {
        final summariesMap = <String, FactorySummary>{};
        cachedSums.forEach((key, val) {
          summariesMap[key] = FactorySummary.fromJson(
            Map<String, dynamic>.from(val as Map),
          );
        });
        _summaries = summariesMap;
      }

      restoreSelectedFactory();
    } catch (e, stack) {
      print("FactoryModule init error: $e");
      print(stack);
    }
  }

  // Factories
  List<Factory> _factories = [];
  bool _isLoadingFactories = false;
  String? _factoriesError;

  Factory? _selectedFactory;
  bool _isLoadingFactory = false;

  // Workers
  List<Worker> _workers = [];
  bool _isLoadingWorkers = false;
  String? _workersError;

  Worker? _selectedWorker;
  bool _isLoadingWorker = false;

  // Transactions
  List<TransactionLog> _transactions = [];
  bool _isLoadingTransactions = false;
  String? _transactionsError;

  // Worker Summary
  WorkerSummary? _workerSummary;
  bool _isLoadingWorkerSummary = false;
  String? _workerSummaryError;

  // Factory Summary
  FactorySummary? _factorySummary;
  bool _isLoadingFactorySummary = false;
  String? _factorySummaryError;

  // Dashboard summaries map for all factories
  Map<String, FactorySummary> _summaries = {};

  // Getters
  List<Factory> get factories => _factories;
  bool get isLoadingFactories => _isLoadingFactories;
  String? get factoriesError => _factoriesError;

  Factory? get selectedFactory => _selectedFactory;
  bool get isLoadingFactory => _isLoadingFactory;

  List<Worker> get workers => _workers;
  bool get isLoadingWorkers => _isLoadingWorkers;
  String? get workersError => _workersError;

  Worker? get selectedWorker => _selectedWorker;
  bool get isLoadingWorker => _isLoadingWorker;

  List<TransactionLog> get transactions => _transactions;
  bool get isLoadingTransactions => _isLoadingTransactions;
  String? get transactionsError => _transactionsError;

  WorkerSummary? get workerSummary => _workerSummary;
  bool get isLoadingWorkerSummary => _isLoadingWorkerSummary;
  String? get workerSummaryError => _workerSummaryError;

  FactorySummary? get factorySummary => _factorySummary;
  bool get isLoadingFactorySummary => _isLoadingFactorySummary;
  String? get factorySummaryError => _factorySummaryError;

  Map<String, FactorySummary> get summaries => _summaries;

  // --- Factories ---
  Future<void> fetchFactories({String? status, String? search}) async {
    _isLoadingFactories = true;
    _factoriesError = null;
    core.notify();

    try {
      final list = await Api.instance.factory.listFactories(
        status: status,
        search: search,
      );
      _factories = list.map((e) => Factory.fromJson(e)).toList();

      if (_selectedFactory == null) {
        restoreSelectedFactory();
      } else {
        final index = _factories.indexWhere(
          (f) => f.id == _selectedFactory!.id,
        );
        if (index != -1) {
          _selectedFactory = _factories[index];
        } else {
          _selectedFactory = null;
        }
      }

      if (_selectedFactory != null) {
        await fetchWorkers(_selectedFactory!.id);
      }
    } catch (e) {
      _factoriesError = extractErrorMessage(e);
    }

    _isLoadingFactories = false;
    core.notify();
  }

  void restoreSelectedFactory() {
    final selectedId = CacheBox.getSelectedFactoryId();
    if (selectedId != null && _factories.isNotEmpty) {
      final matched = _factories.where((f) => f.id == selectedId);
      if (matched.isNotEmpty) {
        selectFactory(matched.first);
      } else if (_factories.length == 1) {
        selectFactory(_factories.first);
      }
    } else if (_factories.length == 1) {
      selectFactory(_factories.first);
    }
  }

  Future<void> selectFactory(Factory factory) async {
    _selectedFactory = factory;
    await CacheBox.setSelectedFactoryId(factory.id);
    clearSubData();
    core.notify();
    await fetchWorkers(factory.id);
  }

  Future<void> clearSelectedFactory() async {
    _selectedFactory = null;
    await CacheBox.setSelectedFactoryId(null);
    core.notify();
  }

  void clearSubData() {
    _workers = [];
    _isLoadingWorkers = false;
    _workersError = null;
    _selectedWorker = null;
    _isLoadingWorker = false;
    _transactions = [];
    _isLoadingTransactions = false;
    _transactionsError = null;
    _workerSummary = null;
    _isLoadingWorkerSummary = false;
    _workerSummaryError = null;
    _factorySummary = null;
    _isLoadingFactorySummary = false;
    _factorySummaryError = null;
  }

  Future<void> fetchFactory(String factoryId) async {
    _isLoadingFactory = true;
    _selectedFactory = null;
    core.notify();

    try {
      final data = await Api.instance.factory.getFactory(factoryId);
      _selectedFactory = Factory.fromJson(data);
    } catch (e) {
      _factoriesError = extractErrorMessage(e);
    }

    _isLoadingFactory = false;
    core.notify();
  }

  Future<bool> createFactory(Map<String, dynamic> data) async {
    _isLoadingFactories = true;
    _factoriesError = null;
    core.notify();

    try {
      await Api.instance.factory.createFactory(data);
      await fetchFactories();
      _isLoadingFactories = false;
      core.notify();
      return true;
    } catch (e) {
      _factoriesError = extractErrorMessage(e);
    }

    _isLoadingFactories = false;
    core.notify();
    return false;
  }

  Future<bool> updateFactory(
    String factoryId,
    Map<String, dynamic> data,
  ) async {
    _isLoadingFactories = true;
    _factoriesError = null;
    core.notify();

    try {
      await Api.instance.factory.updateFactory(factoryId, data);
      await fetchFactories();
      _isLoadingFactories = false;
      core.notify();
      return true;
    } catch (e) {
      _factoriesError = extractErrorMessage(e);
    }

    _isLoadingFactories = false;
    core.notify();
    return false;
  }

  // --- Workers ---
  Future<void> fetchWorkers(
    String factoryId, {
    String? workerType,
    String? search,
  }) async {
    _isLoadingWorkers = true;
    _workersError = null;
    core.notify();

    try {
      final list = await Api.instance.factory.listWorkers(
        factoryId,
        type: workerType,
        search: search,
      );
      _workers = list.map((e) => Worker.fromJson(e)).toList();
    } catch (e) {
      _workersError = extractErrorMessage(e);
    }

    _isLoadingWorkers = false;
    core.notify();
  }

  Future<void> fetchWorker(String factoryId, String workerId) async {
    final cached = _workers.where((w) => w.id == workerId).firstOrNull;
    if (cached != null) {
      _selectedWorker = cached;
      _isLoadingWorker = false;
      core.notify();

      try {
        final data = await Api.instance.factory.getWorker(factoryId, workerId);
        _selectedWorker = Worker.fromJson(data);
        final idx = _workers.indexWhere((w) => w.id == workerId);
        if (idx != -1) {
          _workers[idx] = _selectedWorker!;
        }
        core.notify();
      } catch (_) {}
      return;
    }

    _isLoadingWorker = true;
    _selectedWorker = null;
    core.notify();

    try {
      final data = await Api.instance.factory.getWorker(factoryId, workerId);
      _selectedWorker = Worker.fromJson(data);
    } catch (e) {
      _workersError = extractErrorMessage(e);
    }

    _isLoadingWorker = false;
    core.notify();
  }

  Future<bool> createWorker(String factoryId, Map<String, dynamic> data) async {
    _isLoadingWorkers = true;
    _workersError = null;
    core.notify();

    try {
      await Api.instance.factory.createWorker(factoryId, data);
      await fetchWorkers(factoryId);
      _isLoadingWorkers = false;
      core.notify();
      return true;
    } catch (e) {
      _workersError = extractErrorMessage(e);
    }

    _isLoadingWorkers = false;
    core.notify();
    return false;
  }

  Future<bool> updateWorker(
    String factoryId,
    String workerId,
    Map<String, dynamic> data,
  ) async {
    _isLoadingWorkers = true;
    _workersError = null;
    core.notify();

    try {
      await Api.instance.factory.updateWorker(factoryId, workerId, data);
      await fetchWorkers(factoryId);
      _isLoadingWorkers = false;
      core.notify();
      return true;
    } catch (e) {
      _workersError = extractErrorMessage(e);
    }

    _isLoadingWorkers = false;
    core.notify();
    return false;
  }

  Future<bool> deleteWorker(String factoryId, String workerId) async {
    _isLoadingWorkers = true;
    _workersError = null;
    core.notify();

    try {
      await Api.instance.factory.deleteWorker(factoryId, workerId);
      await fetchWorkers(factoryId);
      _isLoadingWorkers = false;
      core.notify();
      return true;
    } catch (e) {
      _workersError = extractErrorMessage(e);
    }

    _isLoadingWorkers = false;
    core.notify();
    return false;
  }

  // --- Transactions ---
  Future<void> fetchTransactions(
    String factoryId, {
    String? transactionType,
    String? workerId,
    String? fromDate,
    String? toDate,
  }) async {
    _isLoadingTransactions = true;
    _transactionsError = null;
    core.notify();

    try {
      final list = await Api.instance.factory.listTransactions(
        factoryId,
        type: transactionType,
        workerId: workerId,
        dateFrom: fromDate,
        dateTo: toDate,
      );
      _transactions = list.map((e) => TransactionLog.fromJson(e)).toList();
    } catch (e) {
      _transactionsError = extractErrorMessage(e);
    }

    _isLoadingTransactions = false;
    core.notify();
  }

  Future<bool> createHandoff(
    String factoryId,
    Map<String, dynamic> data,
  ) async {
    _isLoadingTransactions = true;
    _transactionsError = null;
    core.notify();

    try {
      final response = await Api.instance.factory.createHandoff(
        factoryId,
        data,
      );
      final transaction =
          response['transaction'] as Map<String, dynamic>? ?? response;
      _transactions.add(TransactionLog.fromJson(transaction));
      await fetchTransactions(factoryId);
      _isLoadingTransactions = false;
      core.notify();
      return true;
    } catch (e) {
      _transactionsError = extractErrorMessage(e);
    }

    _isLoadingTransactions = false;
    core.notify();
    return false;
  }

  Future<bool> createDirect(String factoryId, Map<String, dynamic> data) async {
    _isLoadingTransactions = true;
    _transactionsError = null;
    core.notify();

    try {
      final response = await Api.instance.factory.createDirect(factoryId, data);
      final transaction =
          response['transaction'] as Map<String, dynamic>? ?? response;
      _transactions.add(TransactionLog.fromJson(transaction));
      await fetchTransactions(factoryId);
      _isLoadingTransactions = false;
      core.notify();
      return true;
    } catch (e) {
      _transactionsError = extractErrorMessage(e);
    }

    _isLoadingTransactions = false;
    core.notify();
    return false;
  }

  Future<bool> createTruckDistribution(
    String factoryId,
    Map<String, dynamic> data,
  ) async {
    _isLoadingTransactions = true;
    _transactionsError = null;
    core.notify();

    try {
      final response = await Api.instance.factory.createTruckDistribution(
        factoryId,
        data,
      );
      final transaction =
          response['transaction'] as Map<String, dynamic>? ?? response;
      _transactions.add(TransactionLog.fromJson(transaction));
      await fetchTransactions(factoryId);
      _isLoadingTransactions = false;
      core.notify();
      return true;
    } catch (e) {
      _transactionsError = extractErrorMessage(e);
    }

    _isLoadingTransactions = false;
    core.notify();
    return false;
  }

  Future<bool> createMoneyGiven(
    String factoryId,
    Map<String, dynamic> data,
  ) async {
    _isLoadingTransactions = true;
    _transactionsError = null;
    core.notify();

    try {
      final response = await Api.instance.factory.createMoneyGiven(
        factoryId,
        data,
      );
      final transaction =
          response['transaction'] as Map<String, dynamic>? ?? response;
      _transactions.add(TransactionLog.fromJson(transaction));
      await fetchTransactions(factoryId);
      _isLoadingTransactions = false;
      core.notify();
      return true;
    } catch (e) {
      _transactionsError = extractErrorMessage(e);
    }

    _isLoadingTransactions = false;
    core.notify();
    return false;
  }

  // --- Worker Summary ---
  Future<void> fetchWorkerSummary(String factoryId, String workerId) async {
    _isLoadingWorkerSummary = true;
    _workerSummaryError = null;
    core.notify();

    try {
      final data = await Api.instance.factory.getWorkerSummary(
        factoryId,
        workerId,
      );
      _workerSummary = WorkerSummary.fromJson(data);
    } catch (e) {
      _workerSummaryError = extractErrorMessage(e);
    }

    _isLoadingWorkerSummary = false;
    core.notify();
  }

  // --- Factory Summary ---
  Future<void> fetchFactorySummary(String factoryId) async {
    _isLoadingFactorySummary = true;
    _factorySummaryError = null;
    core.notify();

    try {
      final data = await Api.instance.factory.getFactorySummary(factoryId);
      _factorySummary = FactorySummary.fromJson(data);
    } catch (e) {
      _factorySummaryError = extractErrorMessage(e);
    }

    _isLoadingFactorySummary = false;
    core.notify();
  }

  void clearAll() {
    _factories = [];
    _summaries = {};
    _isLoadingFactories = false;
    _factoriesError = null;
    _selectedFactory = null;
    _isLoadingFactory = false;
    clearSubData();
    core.notify();
  }

  // --- Consolidated Dashboard Loader & State Manager ---
  Future<void> fetchDashboardData() async {
    _isLoadingFactories = true;
    _factoriesError = null;
    core.notify();

    try {
      final cachedFactoryIds = _factories.map((f) => f.id).toList();
      final selectedId =
          _selectedFactory?.id ?? CacheBox.getSelectedFactoryId();

      // Run API calls concurrently in a clean direct list
      final results = await Future.wait([
        Api.instance.factory.listFactories(),
        if (selectedId != null) Api.instance.factory.listWorkers(selectedId),
        for (final id in cachedFactoryIds)
          Api.instance.factory.getFactorySummary(id),
      ]);

      int index = 0;

      // 1. Parse factories
      final list = results[index++] as List<dynamic>;
      _factories = list.map((e) => Factory.fromJson(e)).toList();

      // 2. Parse workers
      if (selectedId != null) {
        final workersList = results[index++] as List<dynamic>;
        _workers = workersList.map((e) => Worker.fromJson(e)).toList();
      }

      // 3. Parse summaries
      final summariesMap = <String, FactorySummary>{};
      for (int i = 0; i < cachedFactoryIds.length; i++) {
        final data = results[index++] as Map<String, dynamic>;
        final summary = FactorySummary.fromJson(data);
        summariesMap[summary.factoryId] = summary;
      }
      _summaries = summariesMap;

      // Restore/validate selection
      if (_selectedFactory == null) {
        restoreSelectedFactory();
      } else {
        final index = _factories.indexWhere(
          (f) => f.id == _selectedFactory!.id,
        );
        if (index != -1) {
          _selectedFactory = _factories[index];
        } else {
          _selectedFactory = null;
        }
      }

      // If the selected factory changed or we didn't fetch workers for the newly restored factory, fetch them now
      if (_selectedFactory != null && _selectedFactory!.id != selectedId) {
        await fetchWorkers(_selectedFactory!.id);
      }

      // 4. Check if there are any new factories that were not in our cache, and fetch their summaries
      final newFactoryIds = _factories
          .map((f) => f.id)
          .where((id) => !cachedFactoryIds.contains(id))
          .toList();
      if (newFactoryIds.isNotEmpty) {
        final newSummaries = await Future.wait(
          newFactoryIds.map((id) => Api.instance.factory.getFactorySummary(id)),
          eagerError: false,
        );
        for (final data in newSummaries) {
          final summary = FactorySummary.fromJson(data);
          _summaries[summary.factoryId] = summary;
        }
      }

      // Save updated data to Hive cache Box
      try {
        final facsJson = _factories.map((f) => f.toJson()).toList();
        await CacheBox.setCachedFactories(facsJson);

        final sumsJson = <String, dynamic>{};
        _summaries.forEach((key, value) {
          sumsJson[key] = value.toJson();
        });
        await CacheBox.setCachedSummaries(sumsJson);
      } catch (_) {}
    } catch (e) {
      _factoriesError = extractErrorMessage(e);
    }

    _isLoadingFactories = false;
    core.notify();
  }

  void updateLocalStats(String factoryId, Map<String, dynamic> change) {
    final type = change['type'] as String;
    final summary = _summaries[factoryId];

    int newBricks = summary?.totalBricks ?? 0;
    double newAmount = summary?.totalAmount ?? 0.0;
    double newMoneyGiven = summary?.totalMoneyGiven ?? 0.0;

    if (type == 'handoff') {
      final qty = change['quantity'] as int? ?? 0;
      final kilnWorkerId = change['kilnWorkerId'] as String?;
      final producerMolderId = change['producerMolderId'] as String?;

      newBricks += qty;
      double addedAmount = 0.0;
      if (producerMolderId != null) {
        final w = _workers.where((x) => x.id == producerMolderId).firstOrNull;
        if (w != null && w.ratePer1000 != null) {
          addedAmount += (qty / 1000.0) * w.ratePer1000!;
        }
      }
      if (kilnWorkerId != null) {
        final w = _workers.where((x) => x.id == kilnWorkerId).firstOrNull;
        if (w != null && w.ratePer1000 != null) {
          addedAmount += (qty / 1000.0) * w.ratePer1000!;
        }
      }
      newAmount += addedAmount;
    } else if (type == 'direct') {
      final qty = change['quantity'] as int? ?? 0;
      final directAmt = change['amount'] as double?;
      final workerId = change['workerId'] as String?;

      newBricks += qty;
      if (directAmt != null) {
        newAmount += directAmt;
      } else if (workerId != null) {
        final w = _workers.where((x) => x.id == workerId).firstOrNull;
        if (w != null && w.ratePer1000 != null) {
          newAmount += (qty / 1000.0) * w.ratePer1000!;
        }
      }
    } else if (type == 'truck_dist') {
      final qty = change['quantity'] as int? ?? 0;
      final workerIds = change['workerIds'] as List<dynamic>? ?? [];

      if (workerIds.isNotEmpty) {
        final qtyPerWorker = qty / workerIds.length;
        double addedAmount = 0.0;
        for (final id in workerIds) {
          final w = _workers.where((x) => x.id == id).firstOrNull;
          if (w != null && w.ratePer1000 != null) {
            addedAmount += (qtyPerWorker / 1000.0) * w.ratePer1000!;
          }
        }
        newAmount += addedAmount;
      }
    } else if (type == 'money_given') {
      final amt = change['amount'] as double? ?? 0.0;
      newMoneyGiven += amt;
    } else if (type == 'add_worker') {
      final index = _factories.indexWhere((f) => f.id == factoryId);
      if (index != -1) {
        final f = _factories[index];
        _factories[index] = f.copyWith(workerCount: f.workerCount + 1);
      }
    }

    if (summary != null) {
      _summaries[factoryId] = summary.copyWith(
        totalBricks: newBricks,
        totalAmount: newAmount,
        totalMoneyGiven: newMoneyGiven,
      );
      core.notify();
    }
  }
}
