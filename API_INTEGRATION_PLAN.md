# API Integration Plan - WowCare Mobility 2.0

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [File Structure](#file-structure)
3. [API Configuration](#api-configuration)
4. [API Client & Logging](#api-client--logging)
5. [Data Flow](#data-flow)
6. [Remote DataSource](#remote-datasource)
7. [Models](#models)
8. [Repository Pattern](#repository-pattern)
9. [Use Cases](#use-cases)
10. [State Management (Cubit)](#state-management-cubit)
11. [Caching Strategy](#caching-strategy)
12. [Pagination](#pagination)
13. [Error Handling](#error-handling)
14. [Dependency Injection](#dependency-injection)
15. [Best Practices](#best-practices)

---

## Architecture Overview

This project follows **Clean Architecture** principles with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  (Cubits, Screens, Widgets) - UI & State Management   │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│                     Domain Layer                         │
│  (Entities, Use Cases, Repository Interfaces)           │
│  - Business Logic & Rules                               │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│                      Data Layer                          │
│  (Models, DataSources, Repository Implementations)      │
│  - API Calls, Caching, Data Transformation              │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│                      Core Layer                          │
│  (Network, Storage, Utils) - Shared Infrastructure      │
└─────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

- **Presentation**: UI components, state management (Cubit/Bloc), user interactions
- **Domain**: Business entities, use cases, repository contracts (interfaces)
- **Data**: API calls, data models, repository implementations, caching
- **Core**: Network client, storage service, utilities, constants

---

## File Structure

```
lib/
├── core/                          # Shared infrastructure
│   ├── network/
│   │   ├── api_client.dart        # Dio client with interceptors
│   │   ├── api_logger.dart        # Centralized API logging
│   │   └── network_info.dart      # Connectivity checking
│   ├── storage/
│   │   └── storage_service.dart   # Local storage abstraction
│   └── util/
│       ├── api_constants.dart     # Base URLs for different services
│       ├── api_paths.dart         # API endpoint paths (constants only)
│       ├── api_error_handler.dart # Error message extraction
│       └── cache_manager.dart     # Global cache management
│
├── data/                          # Data layer
│   └── features/
│       └── {feature}/
│           ├── datasources/
│           │   └── {feature}_remote_datasource.dart
│           ├── models/
│           │   └── {feature}_models.dart
│           └── repositories/
│               └── {feature}_repository_impl.dart
│
├── domain/                        # Domain layer
│   └── features/
│       └── {feature}/
│           ├── entities/
│           │   └── {feature}_entity.dart
│           ├── repositories/
│           │   └── {feature}_repository.dart (interface)
│           └── usecases/
│               └── {action}_{feature}_usecase.dart
│
├── presentation/                  # Presentation layer
│   └── features/
│       └── {feature}/
│           ├── cubit/
│           │   ├── {feature}_cubit.dart
│           │   └── {feature}_state.dart
│           ├── view/
│           │   └── {feature}_screen.dart
│           └── widgets/
│               └── {feature}_widget.dart
│
└── app/
    └── di/
        └── di.dart                # Dependency injection setup
```

---

## API Configuration

### 1. Base URLs (`lib/core/util/api_constants.dart`)

All base URLs are centralized in `ApiConstants`:

```dart
class ApiConstants {
  ApiConstants._();
  
  // Base URLs for different services
  static const String baseUrl = 'https://...';
  static const String staffBaseUrl = 'https://qs176zl8-8083.inc1.devtunnels.ms';
  // ... other base URLs
}
```

**Rules:**
- Each service/feature can have its own base URL
- Use named constants (e.g., `staffBaseUrl`) for service-specific URLs
- Change `baseUrl` to switch environments (dev/qa/prod)

### 2. API Paths (`lib/core/util/api_paths.dart`)

All API endpoint paths are defined as **constants only**:

```dart
class ApiPaths {
  ApiPaths._();
  
  // Auth
  static const String authLogin = '/api/v1/auth/login';
  static const String authLogout = '/api/v1/auth/logout';
  
  // Staff
  static const String staffList = '/api/v1/staff';
  static const String staffDocuments = '/api/v1/staff-documents';
  
  // Helper methods
  static String url(String path) => '${ApiConstants.baseUrl}$path';
  static String urlWithBase(String path, String baseUrl) => '$baseUrl$path';
}
```

**Rules:**
- **ONLY** path constants (no variables/parameters)
- Variables/parameters go in the code file (datasource/repository)
- Use `url()` for default base URL
- Use `urlWithBase()` for custom base URLs (e.g., `staffBaseUrl`)

**Example:**
```dart
// ✅ CORRECT
final endpoint = ApiPaths.urlWithBase(
  ApiPaths.staffList,
  ApiConstants.staffBaseUrl,
);

// ❌ WRONG - Don't put variables in api_paths.dart
static String staffList(String schoolCode) => '/api/v1/staff/$schoolCode';
```

---

## API Client & Logging

### API Client (`lib/core/network/api_client.dart`)

The `ApiClient` wraps Dio and automatically logs all requests/responses:

```dart
class ApiClient {
  ApiClient({
    required String baseUrl,
    List<Interceptor>? interceptors,
    Duration connectTimeout = const Duration(seconds: 20),
    Duration receiveTimeout = const Duration(seconds: 20),
  });
  
  Dio get client => _dio;
}
```

**Features:**
- Automatic request/response/error logging via `ApiLogger`
- Configurable timeouts
- Supports custom interceptors
- JSON response type by default

### API Logger (`lib/core/network/api_logger.dart`)

Centralized logging for all API calls:

```dart
class ApiLogger {
  // Logs request details
  static void logRequest({
    required String url,
    required String method,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
  });
  
  // Logs response details
  static void logResponse({
    required String url,
    required String method,
    int? statusCode,
    dynamic data,
  });
  
  // Logs error details
  static void logError({
    required String url,
    required String method,
    String? type,
    String? message,
    int? statusCode,
    dynamic errorData,
  });
}
```

**Usage:**
- Automatically called by `ApiClient` interceptors
- No manual logging needed in datasources
- Logs appear in console with clear formatting

---

## Data Flow

Complete flow from UI to API:

```
1. User Action (Screen/Widget)
   ↓
2. Cubit Method (e.g., loadInitial, refresh, addItem)
   ↓
3. Use Case (Business Logic)
   ↓
4. Repository Interface (Domain Contract)
   ↓
5. Repository Implementation (Data Layer)
   ↓
6. Remote DataSource (API Call)
   ↓
7. API Client (Dio with Logging)
   ↓
8. API Server
```

**Response Flow (Reverse):**
```
API Response → Model (fromJson) → Entity (mapping) → Use Case → Cubit State → UI Update
```

---

## Remote DataSource

### Structure

Each feature has a remote datasource in `lib/data/features/{feature}/datasources/`:

```dart
// Abstract interface
abstract class StaffRemoteDataSource {
  Future<StaffPageModel> getStaffPage({
    required String schoolCode,
    int page = 0,
    int size = 10,
    String? status,
    String? designation,
    String? search,
  });
}

// Implementation
class StaffRemoteDataSourceImpl implements StaffRemoteDataSource {
  StaffRemoteDataSourceImpl(this._client);
  final Dio _client;
  
  @override
  Future<StaffPageModel> getStaffPage({...}) async {
    // 1. Build query parameters
    final queryParameters = <String, dynamic>{
      'schoolCode': schoolCode,
      'page': page,
      'size': size,
      // ... other params
    };
    
    // 2. Build endpoint URL
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffList,
      ApiConstants.staffBaseUrl,
    );
    
    // 3. Make API call
    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );
    
    // 4. Validate response
    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected API response format');
    }
    
    // 5. Parse and return model
    return StaffPageModel.fromJson(response.data! as Map<String, dynamic>);
  }
}
```

### Rules

1. **Use `ApiPaths` constants** - Never hardcode paths
2. **Use `ApiConstants` for base URLs** - Support multiple services
3. **Handle variables in code** - Query params, path params go here
4. **Return Models** - Not entities (entities are domain layer)
5. **Validate responses** - Check response format before parsing
6. **Throw exceptions** - Let repository handle errors

### Example: POST Request

```dart
@override
Future<StaffDocumentResponseModel> addStaffDocument({
  required String staffCode,
  required StaffDocumentRequestModel request,
}) async {
  // Build endpoint with path parameter
  final endpoint = '${ApiPaths.urlWithBase(
    ApiPaths.staffDocumentAdd,
    ApiConstants.staffBaseUrl,
  )}/$staffCode/documents';
  
  // Make POST request
  final response = await _client.post<Map<String, dynamic>>(
    endpoint,
    data: request.toJson(),
  );
  
  if (response.data == null) {
    throw Exception('Empty response from API');
  }
  
  return StaffDocumentResponseModel.fromJson(response.data!);
}
```

---

## Models

### Location
`lib/data/features/{feature}/models/{feature}_models.dart`

### Structure

Models handle JSON serialization/deserialization:

```dart
class StaffPageModel {
  final List<StaffItemModel> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;
  
  StaffPageModel({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });
  
  // Parse from API response
  factory StaffPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return StaffPageModel(
      items: (data['content'] as List)
          .map((e) => StaffItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: data['number'] as int,
      size: data['size'] as int,
      totalPages: data['totalPages'] as int,
      totalElements: data['totalElements'] as int,
      hasMore: !(data['last'] as bool),
    );
  }
  
  // Parse from cache (may have different structure)
  factory StaffPageModel.fromCacheJson(Map<String, dynamic> json) {
    // Cache structure might be different
    return StaffPageModel.fromJson(json);
  }
  
  // Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'content': items.map((e) => e.toJson()).toList(),
      'number': page,
      'size': size,
      'totalPages': totalPages,
      'totalElements': totalElements,
      'last': !hasMore,
    };
  }
}
```

### Rules

1. **Separate `fromJson` and `fromCacheJson`** - Cache structure may differ
2. **Implement `toJson`** - For caching
3. **Handle nested structures** - Extract `data` wrapper if needed
4. **Type safety** - Use type assertions carefully
5. **Null safety** - Handle nullable fields appropriately

---

## Repository Pattern

### Domain Interface (`lib/domain/features/{feature}/repositories/`)

Defines the contract:

```dart
abstract class StaffRepository {
  Future<StaffPage> getStaffPage({
    required String schoolCode,
    int page,
    int size,
    String? status,
    String? designation,
    String? search,
  });
  
  Future<String> addStaffDocument({
    required String staffCode,
    required StaffDocument document,
  });
}

// Optional: Cache interface
abstract class StaffRepositoryWithCache {
  Future<StaffPage?> loadCachedStaffPage(String schoolCode);
  Future<StaffDocumentsPage?> loadCachedStaffDocuments(String staffCode);
}
```

### Implementation (`lib/data/features/{feature}/repositories/`)

Implements the contract with caching:

```dart
class StaffRepositoryImpl implements StaffRepository, StaffRepositoryWithCache {
  StaffRepositoryImpl(this._remoteDataSource, StorageService storageService)
      : _cacheManager = CacheManager(storageService);
  
  final StaffRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;
  
  // Cache key helpers
  static String _staffListCacheKey(String schoolCode) =>
      CacheManager.buildCacheKey(
        feature: 'staff',
        resource: 'list',
        identifier: schoolCode,
      );
  
  @override
  Future<StaffPage> getStaffPage({...}) async {
    // 1. Call remote datasource
    final staffPageModel = await _remoteDataSource.getStaffPage(...);
    
    // 2. Cache only first page
    if (page == 0) {
      await _cacheManager.saveCache(
        _staffListCacheKey(schoolCode),
        staffPageModel.toJson(),
      );
    }
    
    // 3. Map model to entity
    return _mapPageModelToEntity(staffPageModel);
  }
  
  @override
  Future<StaffPage?> loadCachedStaffPage(String schoolCode) async {
    final payload = await _cacheManager.loadCache(_staffListCacheKey(schoolCode));
    if (payload == null) return null;
    
    final model = StaffPageModel.fromCacheJson(payload);
    return _mapPageModelToEntity(model);
  }
  
  // Map model to entity
  StaffPage _mapPageModelToEntity(StaffPageModel model) {
    return StaffPage(
      items: model.items.map((m) => StaffMember(...)).toList(),
      page: model.page,
      size: model.size,
      totalPages: model.totalPages,
      totalElements: model.totalElements,
      hasMore: model.hasMore,
    );
  }
  
  // IMPORTANT: Invalidate cache after mutations
  @override
  Future<String> addStaffDocument({...}) async {
    final response = await _remoteDataSource.addStaffDocument(...);
    
    // Invalidate cache to ensure fresh data on next fetch
    await _cacheManager.invalidateCache(_staffDocumentsCacheKey(staffCode));
    
    return response.message;
  }
}
```

### Rules

1. **Implement domain interface** - Repository interface is in domain layer
2. **Map Models to Entities** - Data layer models → Domain layer entities
3. **Cache only page 0** - Don't cache paginated pages
4. **Invalidate cache on mutations** - Add/Edit/Delete operations
5. **Use `CacheManager.buildCacheKey()`** - Consistent key pattern
6. **Return Entities** - Not models (models are data layer)

---

## Use Cases

### Location
`lib/domain/features/{feature}/usecases/{action}_{feature}_usecase.dart`

### Structure

Use cases encapsulate business logic:

```dart
class GetStaffDocumentsUseCase {
  GetStaffDocumentsUseCase(this._repository);
  
  final StaffRepository _repository;
  
  Future<StaffDocumentsPage> call({
    required String staffCode,
    int page = 0,
    int size = 10,
    bool? expired,
  }) {
    return _repository.getStaffDocuments(
      staffCode: staffCode,
      page: page,
      size: size,
      expired: expired,
    );
  }
}
```

### Rules

1. **Simple pass-through** - Usually just call repository
2. **Business logic here** - If validation/transformation needed
3. **Use `call()` method** - Can be invoked directly
4. **One use case per action** - Single responsibility

---

## State Management (Cubit)

### Structure

Cubits manage UI state:

```dart
class StaffDocumentsListCubit extends Cubit<StaffDocumentsListState> {
  StaffDocumentsListCubit({
    required GetStaffDocumentsUseCase getStaffDocumentsUseCase,
    required StaffRepository repository,
  })  : _getStaffDocumentsUseCase = getStaffDocumentsUseCase,
        _repository = repository,
        super(const StaffDocumentsListState.initial());
  
  final GetStaffDocumentsUseCase _getStaffDocumentsUseCase;
  final StaffRepository _repository;
  
  static const int _pageSize = 10;
  
  // Initial load: Try cache first, then API
  Future<void> loadInitial(String staffCode, {bool? expired}) async {
    // Try cache first
    final cached = await (_repository is StaffRepositoryWithCache
        ? (_repository as StaffRepositoryWithCache)
            .loadCachedStaffDocuments(staffCode)
        : Future.value(null));
    
    if (cached != null && !isClosed) {
      emit(StaffDocumentsListState.loaded(
        documents: cached.items,
        currentPage: 0, // Always start from page 0
        hasMore: cached.hasMore,
        isFromCache: true,
      ));
      return; // Don't hit API if cache is valid
    }
    
    // No cache - load from API
    await refresh(staffCode, expired: expired);
  }
  
  // Refresh: Always load page 0 from API
  Future<void> refresh(String staffCode, {bool? expired}) async {
    if (state.isRefreshing) return;
    
    emit(state.copyWith(
      isLoading: state.documents.isEmpty,
      isRefreshing: true,
      errorMessage: null,
    ));
    
    try {
      final firstPage = await _getStaffDocumentsUseCase(
        staffCode: staffCode,
        page: 0, // Always page 0 on refresh
        size: _pageSize,
        expired: expired,
      );
      
      if (isClosed) return;
      
      emit(StaffDocumentsListState.loaded(
        documents: firstPage.items,
        currentPage: firstPage.page,
        hasMore: firstPage.hasMore,
        isFromCache: false,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: e.toString(),
      ));
    }
  }
  
  // Load next page: Only if not loading and has more
  Future<void> loadNextPage(String staffCode, {bool? expired}) async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (state.currentPage < 0) return; // Safety check
    
    emit(state.copyWith(isLoadingMore: true, errorMessage: null));
    
    try {
      final nextPageIndex = state.currentPage + 1;
      final page = await _getStaffDocumentsUseCase(
        staffCode: staffCode,
        page: nextPageIndex,
        size: _pageSize,
        expired: expired,
      );
      
      if (isClosed) return;
      
      emit(state.copyWith(
        documents: [...state.documents, ...page.items], // Append
        currentPage: page.page,
        hasMore: page.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      ));
    }
  }
}
```

### State Definition

```dart
class StaffDocumentsListState extends Equatable {
  const StaffDocumentsListState({
    required this.documents,
    required this.isLoading,
    required this.isRefreshing,
    required this.isFromCache,
    this.currentPage = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });
  
  const StaffDocumentsListState.initial()
      : documents = const [],
        isLoading = false,
        isRefreshing = false,
        isFromCache = false,
        currentPage = 0,
        hasMore = false,
        isLoadingMore = false,
        errorMessage = null;
  
  const StaffDocumentsListState.loaded({
    required List<StaffDocument> documents,
    required bool isFromCache,
    this.currentPage = 0,
    this.hasMore = false,
  })  : documents = documents,
        isLoading = false,
        isRefreshing = false,
        isFromCache = isFromCache,
        isLoadingMore = false,
        errorMessage = null;
  
  final List<StaffDocument> documents;
  final bool isLoading;
  final bool isRefreshing;
  final bool isFromCache;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;
  
  StaffDocumentsListState copyWith({...}) { ... }
  
  @override
  List<Object?> get props => [...];
}
```

### Rules

1. **Cache-first on initial load** - Try cache, then API
2. **Always page 0 on refresh** - Reset pagination
3. **Append on pagination** - Don't replace existing items
4. **Check `isClosed`** - Prevent state updates after disposal
5. **Guard pagination** - Check `isLoading`, `isLoadingMore`, `hasMore`
6. **Track `currentPage`** - For next page calculation

---

## Caching Strategy

### Cache Manager (`lib/core/util/cache_manager.dart`)

Global, generic cache manager:

```dart
class CacheManager {
  CacheManager(this._storageService);
  final StorageService _storageService;
  
  // Build cache key following pattern: {feature}_{resource}_cache_{identifier}
  static String buildCacheKey({
    required String feature,
    required String resource,
    required String identifier,
  }) {
    return '${feature}_${resource}_cache_$identifier';
  }
  
  // Save cache with timestamp
  Future<void> saveCache(String key, Map<String, dynamic> payload) async {
    final cache = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'payload': payload,
    };
    await _storageService.saveJson(key, cache);
  }
  
  // Load cache if valid (not expired)
  Future<Map<String, dynamic>?> loadCache(String key) async {
    final cache = await _storageService.getJson(key);
    if (cache == null) return null;
    
    final timestampMillis = cache['timestamp'] as int?;
    if (timestampMillis == null) return null;
    
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    final age = DateTime.now().difference(cachedAt);
    if (age > StorageKeys.cacheValidDuration) {
      return null; // Expired
    }
    
    return cache['payload'] as Map<String, dynamic>?;
  }
  
  // Invalidate cache
  Future<void> invalidateCache(String key) async {
    await _storageService.remove(key);
  }
}
```

### Cache Key Pattern

```
{feature}_{resource}_cache_{identifier}
```

**Examples:**
- `staff_list_cache_SCH_12345`
- `staff_documents_cache_STF_870376B8-0`
- `students_list_cache_SCH_12345`

### Caching Rules

1. **Cache only page 0** - Don't cache paginated pages
2. **Invalidate on mutations** - Add/Edit/Delete operations
3. **Use `buildCacheKey()`** - Consistent key generation
4. **Timestamp-based expiration** - Configurable in `StorageKeys.cacheValidDuration`
5. **Cache in repository** - Not in datasource or cubit

### Cache Flow

```
1. Initial Load:
   - Try cache first
   - If valid → Use cache, don't hit API
   - If invalid/missing → Load from API, then cache

2. Refresh:
   - Always load from API (page 0)
   - Update cache

3. Pagination:
   - Don't cache (only page 0 is cached)
   - Append to existing list

4. Mutations (Add/Edit/Delete):
   - Invalidate cache
   - Next load will fetch fresh data
```

---

## Pagination

### Implementation Pattern

1. **Initial Load**: Page 0 only
2. **Refresh**: Page 0 only (reset)
3. **Next Page**: Triggered on scroll

### Cubit Methods

```dart
// Initial: Cache-first, then page 0
loadInitial(String staffCode) async { ... }

// Refresh: Always page 0
refresh(String staffCode) async { ... }

// Next Page: Append to list
loadNextPage(String staffCode) async { ... }
```

### UI Implementation

```dart
// In widget
NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    // Only trigger on actual scroll updates
    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels >=
          notification.metrics.maxScrollExtent - 200) {
        final state = cubit.state;
        if (!state.isLoading && !state.isLoadingMore && state.hasMore) {
          cubit.loadNextPage(staffCode);
        }
      }
    }
    return false;
  },
  child: SingleChildScrollView(...),
)
```

### Rules

1. **Start from page 0** - Always on initial load/refresh
2. **Append items** - Don't replace on pagination
3. **Check `hasMore`** - Don't load if no more pages
4. **Guard against duplicate calls** - Check `isLoadingMore`
5. **200px threshold** - Load when 200px from bottom

---

## Error Handling

### API Error Handler (`lib/core/util/api_error_handler.dart`)

Centralized error message extraction:

```dart
class ApiErrorHandler {
  ApiErrorHandler._();
  
  /// Extracts error message from DioException or any exception.
  /// Priority:
  /// 1. API response body's 'message' field
  /// 2. DioException's error message
  /// 3. Exception's toString()
  static String extractErrorMessage(dynamic error) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('message')) {
          return responseData['message'].toString();
        }
      }
      return error.message ?? 'An error occurred';
    }
    return error.toString();
  }
  
  /// Extracts success message from API response.
  static String extractSuccessMessage(
    dynamic responseData, {
    String defaultMessage = 'Operation completed successfully',
  }) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('message')) {
        return responseData['message'].toString();
      }
    }
    return defaultMessage;
  }
}
```

### Usage in Use Cases

```dart
class AddStaffDocumentUseCase {
  Future<String> call({...}) async {
    try {
      final response = await _repository.addStaffDocument(...);
      return response; // Success message
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}
```

### Usage in UI

```dart
BlocListener<StaffDocumentCubit, StaffDocumentState>(
  listener: (context, state) {
    if (state is StaffDocumentState.success) {
      CoreUtils.showTopSnackBar(
        context,
        message: state.message,
        isError: false,
      );
    } else if (state is StaffDocumentState.error) {
      CoreUtils.showTopSnackBar(
        context,
        message: state.message,
        isError: true,
      );
    }
  },
  child: ...,
)
```

### Rules

1. **Always use `ApiErrorHandler`** - Consistent error messages
2. **Show API messages** - Use `message` field from response
3. **Handle in Cubit** - Catch errors, emit error state
4. **Display in UI** - Use `CoreUtils.showTopSnackBar()`

---

## Dependency Injection

### Setup (`lib/app/di/di.dart`)

Using GetIt for DI:

```dart
final GetIt serviceLocator = GetIt.instance;

Future<void> configureDependencies({String? baseUrl}) async {
  // Core
  serviceLocator.registerLazySingleton<StorageService>(...);
  serviceLocator.registerLazySingleton<ApiClient>(...);
  serviceLocator.registerLazySingleton<CacheManager>(...);
  
  // Data Sources
  serviceLocator.registerLazySingleton<StaffRemoteDataSource>(
    () => StaffRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );
  
  // Repositories
  serviceLocator.registerLazySingleton<StaffRepository>(
    () => StaffRepositoryImpl(
      serviceLocator(),
      serviceLocator(),
    ),
  );
  
  // Use Cases
  serviceLocator.registerFactory<GetStaffDocumentsUseCase>(
    () => GetStaffDocumentsUseCase(serviceLocator()),
  );
  
  // Cubits
  serviceLocator.registerFactory<StaffDocumentsListCubit>(
    () => StaffDocumentsListCubit(
      getStaffDocumentsUseCase: serviceLocator(),
      repository: serviceLocator(),
    ),
  );
}
```

### Registration Rules

1. **LazySingleton** - Core services, repositories, datasources
2. **Factory** - Use cases, cubits (new instance each time)
3. **Order matters** - Register dependencies before dependents

### Usage in Widgets

```dart
// Option 1: Get from service locator
final cubit = serviceLocator<StaffDocumentsListCubit>();

// Option 2: Provide via BlocProvider
BlocProvider(
  create: (_) => serviceLocator<StaffDocumentsListCubit>(),
  child: ...,
)

// Option 3: Use existing instance
BlocProvider.value(
  value: _cubit, // Created in initState
  child: ...,
)
```

---

## Best Practices

### 1. API Paths
- ✅ Use `ApiPaths` constants only
- ✅ Variables in code files (datasource/repository)
- ❌ Don't hardcode paths
- ❌ Don't put variables in `api_paths.dart`

### 2. Base URLs
- ✅ Use `ApiConstants` for all base URLs
- ✅ Support multiple services (e.g., `staffBaseUrl`)
- ✅ Use `urlWithBase()` for custom base URLs

### 3. Caching
- ✅ Cache only page 0
- ✅ Invalidate on mutations
- ✅ Use `CacheManager.buildCacheKey()`
- ✅ Cache in repository, not datasource

### 4. Error Handling
- ✅ Always use `ApiErrorHandler.extractErrorMessage()`
- ✅ Show API messages to users
- ✅ Handle errors in Cubit, display in UI

### 5. Pagination
- ✅ Start from page 0
- ✅ Append items on pagination
- ✅ Check `hasMore` before loading
- ✅ Guard against duplicate calls

### 6. State Management
- ✅ Cache-first on initial load
- ✅ Always page 0 on refresh
- ✅ Check `isClosed` before emitting
- ✅ Track `currentPage` for pagination

### 7. Code Organization
- ✅ Follow Clean Architecture layers
- ✅ Domain entities, Data models
- ✅ Repository interfaces in domain
- ✅ Repository implementations in data

### 8. Logging
- ✅ Automatic via `ApiClient` interceptors
- ✅ No manual logging needed
- ✅ All requests/responses logged

---

## Quick Reference

### Adding a New API Endpoint

1. **Add path to `api_paths.dart`**:
   ```dart
   static const String newEndpoint = '/api/v1/new-endpoint';
   ```

2. **Add method to remote datasource**:
   ```dart
   Future<NewModel> getNewData({required String id}) async {
     final endpoint = ApiPaths.url(ApiPaths.newEndpoint);
     final response = await _client.get<Map<String, dynamic>>(endpoint);
     return NewModel.fromJson(response.data!);
   }
   ```

3. **Add method to repository interface** (domain):
   ```dart
   Future<NewEntity> getNewData({required String id});
   ```

4. **Implement in repository** (data):
   ```dart
   @override
   Future<NewEntity> getNewData({required String id}) async {
     final model = await _remoteDataSource.getNewData(id: id);
     return _mapModelToEntity(model);
   }
   ```

5. **Create use case** (domain):
   ```dart
   class GetNewDataUseCase {
     Future<NewEntity> call({required String id}) {
       return _repository.getNewData(id: id);
     }
   }
   ```

6. **Create cubit** (presentation):
   ```dart
   class NewCubit extends Cubit<NewState> {
     Future<void> loadData(String id) async {
       final entity = await _useCase(id: id);
       emit(NewState.loaded(entity));
     }
   }
   ```

7. **Register in DI** (`di.dart`):
   ```dart
   serviceLocator.registerFactory<GetNewDataUseCase>(...);
   serviceLocator.registerFactory<NewCubit>(...);
   ```

---

## Summary

This codebase follows **Clean Architecture** with:
- **Centralized API configuration** (`ApiPaths`, `ApiConstants`)
- **Automatic API logging** (`ApiClient` interceptors)
- **Global caching** (`CacheManager` with timestamp expiration)
- **Consistent error handling** (`ApiErrorHandler`)
- **Pagination pattern** (cache-first, page 0 on refresh, append on scroll)
- **Dependency injection** (GetIt)

All APIs are integrated following this pattern, ensuring consistency and maintainability.

