---
name: flutter_coding
description: Selcom project coding standards, network structure rules, and architecture patterns.
---

# 📐 Flutter Coding Standards

## 1. Project Structure

```
lib/
├── core/
│   ├── config/          # AppConfig, environment settings
│   ├── data/            # Data layer: models, datasources, repository implementations
│   │   ├── datasources/
│   │   ├── models/
│   │   └── repositories/
│   ├── di/              # Dependency injection (GetIt)
│   ├── domain/          # Domain layer: entities, repositories (abstract), usecases
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   ├── errors/          # Failure classes, error mappers
│   ├── network/         # ⭐ API layer (see Network Rules below)
│   ├── routes/          # App routing
│   ├── services/        # Platform services (analytics, socket, etc.)
│   └── theme/           # App theme, colors, text styles
├── features/            # Feature modules (auth, home, ride, booking...)
│   └── <feature>/
│       ├── controllers/
│       ├── presentation/
│       │   ├── screens/
│       │   └── widgets/
│       └── data/        # Feature-specific data if needed
├── shared/              # Shared widgets, utils
│   ├── widgets/
│   └── utils/
└── main.dart
```

## 2. Network Layer Rules (CRITICAL)

### ⭐ MANDATORY Structure
Every Selcom project MUST have this network folder:

```
lib/core/network/
├── api_service.dart              # Singleton ApiService + AuthInterceptor
├── api_constants.dart            # Params, ResultCode
├── headers.dart                  # commonHeaders() builder
├── urls.dart                     # URLS endpoint registry
├── failed_request_queue.dart     # Deduplicating request queue
├── retry_manager.dart            # Auto-retry manager
└── network_connectivity_service.dart  # Connectivity monitor
```

### Rules
1. **NEVER** use raw `Dio()` in repositories/controllers.
2. **ALWAYS** use `ApiService().call(request: ApiRequest(...))`.
3. **ALWAYS** define endpoints in `urls.dart` using the `URLS` registry pattern.
4. **ALWAYS** use `Params` constants from `api_constants.dart` for body/header keys.
5. **ALWAYS** use `commonHeaders()` from `headers.dart` for header construction.
6. **NEVER** hardcode API endpoint strings outside `urls.dart`.
7. **NEVER** store tokens in SharedPreferences — use `FlutterSecureStorage`.

### Adding a New API Endpoint
```dart
// 1. Add to urls.dart
class _RideEndpoints {
  const _RideEndpoints();
  final newEndpoint = "ride/new_endpoint";
}

// 2. Use in repository
final response = await ApiService().call(
  request: ApiRequest(
    endpoint: URLS.ride.newEndpoint,
    method: ApiMethod.post,
    body: {Params.rideId: rideId},
  ),
);
```

### Adding a New Feature API Group
```dart
// 1. Create endpoint class in urls.dart
class _NewFeatureEndpoints {
  const _NewFeatureEndpoints();
  final someAction = "new_feature/some_action";
}

// 2. Register in URLS abstract class
abstract class URLS {
  static const newFeature = _NewFeatureEndpoints();
  // ... existing groups
}
```

## 3. Repository Pattern

Repositories MUST:
- Implement abstract interfaces from `core/domain/repositories/`.
- Use `Either<Failure, T>` return types (from `dartz`).
- Call `ApiService().call()` — never raw Dio.
- Map responses to domain entities/models.
- Handle `DioException` → `Failure` mapping.

```dart
class ExampleRepositoryImpl implements ExampleRepository {
  @override
  Future<Either<Failure, Entity>> getData() async {
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.example.getData,
          method: ApiMethod.get,
        ),
      );
      if (response.statusCode == 200) {
        return Right(Entity.fromJson(response.data));
      }
      return Left(ServerFailure(response.data?['message'] ?? 'Error'));
    } on DioException catch (e) {
      return Left(ErrorMapper.mapDioExceptionToFailure(e));
    }
  }
}
```

## 4. State Management
- Use **GetX** for state management and navigation.
- Controllers go in `features/<feature>/controllers/`.
- Use `.obs` for reactive state, `Rx<T>` for complex types.

## 5. Dependency Injection
- Use **GetIt** (`get_it`) as service locator.
- All registrations in `core/di/injection_container.dart`.
- ApiService is initialized via `ApiService().init(...)` (singleton, not registered in GetIt).
- Repositories registered as lazy singletons.

## 6. Error Handling
- `Failure` abstract class with subtypes: `ServerFailure`, `CacheFailure`, `NetworkFailure`, `AuthFailure`.
- `ErrorMapper.mapDioExceptionToFailure()` for Dio errors.
- API layer handles retry/queue for network errors automatically.

## 7. Naming Conventions
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/methods: `camelCase`
- Constants: `UPPER_SNAKE_CASE` for result codes, `camelCase` for params
- Private classes: `_PascalCase`
