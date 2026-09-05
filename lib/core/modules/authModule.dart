import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/types/user.dart';
import 'package:vyaparsetu/storage/secure_storage.dart';
import 'package:vyaparsetu/storage/hive/cache.dart';
import 'package:vyaparsetu/storage/hive/user.dart';
import 'package:vyaparsetu/storage/hive.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/helpers/errorHandler.dart';

class AuthModule {
  final Core core;
  AuthModule(this.core);

  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  void setError(String? error) {
    _error = error;
    core.notify();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      final response = await Api.instance.auth.login(
        email: email,
        password: password,
        deviceInfo: 'Mobile App',
      );

      final userJson = response['user'];
      final accessToken = response['accessToken'];
      final refreshToken = response['refreshToken'];

      if (userJson != null && accessToken != null && refreshToken != null) {
        _user = User.fromJson(Map<String, dynamic>.from(userJson));
        await SecureStorage.setAccessToken(accessToken);
        await SecureStorage.setRefreshToken(refreshToken);
        await CacheBox.setUser(_user!.toJson());
        await UserBox.setLastLoginEmail(email);

        _isLoading = false;
        core.notify();
        return true;
      } else {
        _error = 'Invalid response from server';
      }
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notify();
    return false;
  }

  Future<bool> signup(String name, String email, String password, String confirmPassword) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      final response = await Api.instance.auth.signup(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        deviceInfo: 'Mobile App',
      );

      final userJson = response['user'];
      final accessToken = response['accessToken'];
      final refreshToken = response['refreshToken'];

      if (userJson != null && accessToken != null && refreshToken != null) {
        _user = User.fromJson(Map<String, dynamic>.from(userJson));
        await SecureStorage.setAccessToken(accessToken);
        await SecureStorage.setRefreshToken(refreshToken);
        await CacheBox.setUser(_user!.toJson());
        await UserBox.setLastLoginEmail(email);

        _isLoading = false;
        core.notify();
        return true;
      } else {
        _error = 'Invalid response from server';
      }
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notify();
    return false;
  }

  Future<bool> tryAutoLogin() async {
    final cachedUser = CacheBox.getUser();
    final token = await SecureStorage.getAccessToken();

    if (cachedUser == null || token == null) {
      return false;
    }

    _user = User.fromJson(cachedUser);
    core.notify();

    try {
      final response = await Api.instance.auth.getMe();
      final userJson = response['user'];
      if (userJson != null) {
        _user = User.fromJson(Map<String, dynamic>.from(userJson));
        await CacheBox.setUser(_user!.toJson());
        core.notify();
        return true;
      }
    } catch (e) {
      final currentToken = await SecureStorage.getAccessToken();
      if (currentToken == null) {
        _user = null;
        core.notify();
        return false;
      }
    }

    return _user != null;
  }

  Future<void> logout({bool allDevices = false}) async {
    _isLoading = true;
    core.notify();

    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken != null) {
        await Api.instance.auth.logout(
          refreshToken: refreshToken,
          allDevices: allDevices,
        );
      }
    } catch (e) {
      // Ignore API errors during logout
    } finally {
      _user = null;

      // Clear all in-memory module state
      core.business.clearAll();
      core.party.clearAll();
      core.item.clearAll();
      core.invoice.clearAll();
      core.payment.clearAll();
      core.expense.clearAll();
      core.dashboard.clearAll();

      // Clear persisted storage
      await SecureStorage.deleteAll();
      await clearBoxes();

      _isLoading = false;
      core.notify();
    }
  }

  void handleSessionExpired() {
    _user = null;
    core.business.clearAll();
    core.party.clearAll();
    core.item.clearAll();
    core.invoice.clearAll();
    core.payment.clearAll();
    core.expense.clearAll();
    core.dashboard.clearAll();
    core.notify();
  }

}
