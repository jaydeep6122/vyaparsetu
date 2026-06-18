# API

## Rule
All HTTP requests go through `Api.instance.<module>.<method>()`. Calls are made inside Core modules, never directly from screens.

## Api Singleton

```dart
class Api {
  static late final Api _instance;
  static Api get instance => _instance;

  late final AuthApi auth;
  late final BusinessApi business;
  late final DashboardApi dashboard;
  late final ExpenseApi expense;
  late final InvoiceApi invoice;
  late final ItemApi item;
  late final PartyApi party;
  late final PaymentApi payment;

  Api._internal(Dio dio) {
    auth = AuthApi(dio);
    business = BusinessApi(dio);
    // ... all modules with same dio
  }

  static void initialize(Dio dio) {
    _instance = Api._internal(dio);
  }
}
```

## Dio Configuration

- **Base URL:** `AppConstants.apiBaseUrl` (`https://vyaparsetubackend.onrender.com/v1/`)
- **Timeouts:** 30s connect, 30s receive
- **Auth header:** Automatically added via interceptor (`Authorization: Bearer <token>`)
- **Excluded paths:** `/auth/login`, `/auth/signup`, `/auth/refresh`
- **Session expiry:** Silent token refresh on 401. Calls `onSessionExpired` callback if refresh fails.

## Initialization Order (in `main.dart`)

```dart
DioInstance.init(baseURL: AppConstants.apiBaseUrl);
Api.initialize(dioInstance.dio);
```

## API Module Pattern

```dart
class InvoiceApi {
  final Dio _dio;
  InvoiceApi(this._dio);

  Future<List<Map<String, dynamic>>> getInvoices(String businessId) async {
    final response = await _dio.get('/businesses/$businessId/invoices');
    return (response.data['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createInvoice(
    String businessId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post('/businesses/$businessId/invoices', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }
}
```

## DO
- Create one API module file per entity in `api/modules/`
- Use `Api.instance` from within Core modules only
- Return raw JSON (`List<Map>`, `Map<String, dynamic>`) — parsing happens in Core modules
- Handle 401s via the Dio interceptor (automatic token refresh)

## DON'T
- Call `Api.instance` from screen files — always go through Core modules
- Create API module files outside `api/modules/`
- Add auth headers manually — the Dio interceptor handles it
- Use raw HTTP instead of Dio
