# API

## Rule
Every request goes through `Api.instance.<module>.<method>()`, called from a
Core module — never from a screen.

## Response envelope

The backend always answers with the same shape:

```json
{ "success": true, "data": { ... }, "pagination": { "limit": 50, "offset": 0, "total": 120 } }
{ "success": false, "statusCode": 409, "message": "…", "constraint": "parties_name_unique" }
```

`api/response.dart` unwraps it:

| Helper | Purpose |
|---|---|
| `dataOf(response)` | `data` as `Map<String, dynamic>` |
| `listOf(response)` | `data` as `List<Map<String, dynamic>>` |
| `PageJson.of(response)` | items + limit/offset/total for paged endpoints |
| `queryOf({...})` | Drops null and empty query values |
| `businessPath(id)` | `/businesses/<id>` |

Errors are turned into text by `helpers/errorHandler.dart` →
`userFriendlyError`, which maps unique constraints to `error_*` keys and
rewrites validation paths ("lines.0.quantity") into "Line 1 · Quantity: …".

## Dio

- Base URL `AppConstants.apiBaseUrl` (`…/v1/`), 30s timeouts.
- Interceptor adds `Authorization: Bearer <access token>`, except on
  `/auth/login`, `/auth/signup`, `/auth/refresh`, `/auth/logout`,
  `/auth/password/forgot`, `/auth/password/reset`.
- On 401 it refreshes once with the stored refresh token
  (`data.access_token` / `data.refresh_token`) and replays the request;
  if that fails it calls `onSessionExpired`, which signs the user out.

## Module pattern

```dart
class PartyApi {
  final Dio _dio;
  PartyApi(this._dio);

  String _base(String businessId) => '${businessPath(businessId)}/parties';

  Future<PageJson> list(String businessId, {String? search, int? limit, int offset = 0}) async {
    final response = await _dio.get(
      _base(businessId),
      queryParameters: queryOf({'search': search, 'limit': limit, 'offset': offset}),
    );
    return PageJson.of(response);
  }

  Future<Map<String, dynamic>> create(String businessId, Map<String, dynamic> data) async =>
      dataOf(await _dio.post(_base(businessId), data: data));
}
```

Request bodies are plain maps with snake_case keys, built by the screen and
passed straight through. Amounts are sent as strings ("1250.00") so they never
pass through float maths; dates as `YYYY-MM-DD` via `apiDate()`.

## Writes and role

`PATCH` updates only the fields sent (null clears one). `PUT` replaces the whole
document (invoices, payments, expenses). Editing, cancelling, transfers, stock
adjustments and reports need `accountant`; accounts, tax rates, team, business
settings and numbering need `admin`; archiving a business needs `owner`.

## DO
- One API module file per entity in `api/modules/`
- Return raw JSON; parse in Core modules
- Use `queryOf` so empty filters are dropped

## DON'T
- Add auth headers by hand
- Parse models or show toasts inside `api/`
- Call the API from screens or widgets
