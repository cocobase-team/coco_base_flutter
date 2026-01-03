# API Reference

Complete API documentation for all classes and methods.

## Table of Contents

1. [Cocobase Class](#cocobase-class)
2. [CocobaseConfig](#cocobaseconfig)
3. [QueryBuilder Class](#querybuilder-class)
4. [Document Class](#document-class)
5. [Response Models](#response-models)
6. [Error Handling](#error-handling)

---

## Cocobase Class

The main class for all database operations.

### Constructor

```dart
Cocobase(CocobaseConfig config)
```

**Parameters:**

- `config` - Configuration object with API key and optional base URL

**Example:**

```dart
final db = Cocobase(
  CocobaseConfig(
    apiKey: 'YOUR_API_KEY',
    baseUrl: 'https://api.cocobase.buzz',  // Optional
  )
);
```

---

### Document Operations

#### listDocuments<T>

```dart
Future<List<Document<T>>> listDocuments<T>(
  String collection, {
  QueryBuilder? queryBuilder,
  Map<String, dynamic>? filters,
  T Function(Map<String, dynamic>)? converter,
})
```

**Parameters:**

- `collection` - Collection name (required)
- `queryBuilder` - Complex query builder (optional)
- `filters` - Simple filter map (optional)
- `converter` - Type converter function (optional)

**Returns:** List of type-safe documents

**Examples:**

```dart
// Simple
final docs = await db.listDocuments("books");

// With filters
final docs = await db.listDocuments<Book>(
  "books",
  filters: {'status': 'published'},
  converter: Book.fromJson,
);

// With QueryBuilder
final docs = await db.listDocuments<Book>(
  "books",
  queryBuilder: QueryBuilder()
    .where('status', 'published')
    .orderByDesc('createdAt')
    .limit(20),
  converter: Book.fromJson,
);
```

---

#### getDocument<T>

```dart
Future<Document<T>> getDocument<T>(
  String collection,
  String docId, {
  List<String>? populate,
  T Function(Map<String, dynamic>)? converter,
})
```

**Parameters:**

- `collection` - Collection name (required)
- `docId` - Document ID (required)
- `populate` - Fields to populate relationships (optional)
- `converter` - Type converter function (optional)

**Returns:** Single typed document

**Examples:**

```dart
// Simple
final doc = await db.getDocument("books", "doc-123");

// With type conversion
final book = await db.getDocument<Book>(
  "books",
  "doc-123",
  converter: Book.fromJson,
);

// With population
final book = await db.getDocument<Book>(
  "books",
  "doc-123",
  populate: ['author', 'publisher'],
  converter: Book.fromJson,
);
```

---

#### createDocument<T>

```dart
Future<Document<T>> createDocument<T>(
  String collection,
  T data,
)
```

**Parameters:**

- `collection` - Collection name (required)
- `data` - Document data to create (required)

**Returns:** Created document with ID

**Examples:**

```dart
final book = Book(
  title: 'Flutter Guide',
  author: 'John Doe',
  price: 29.99,
);

final created = await db.createDocument<Book>("books", book);
print('Created: ${created.id}');
```

---

#### updateDocument<T>

```dart
Future<Document<T>> updateDocument<T>(
  String collection,
  String docId,
  Map<String, dynamic> data,
)
```

**Parameters:**

- `collection` - Collection name (required)
- `docId` - Document ID (required)
- `data` - Fields to update (required)

**Returns:** Updated document

**Examples:**

```dart
await db.updateDocument(
  "books",
  "doc-123",
  {'price': 24.99, 'status': 'archived'},
);
```

---

#### deleteDocument

```dart
Future<Map<String, bool>> deleteDocument(
  String collection,
  String docId,
)
```

**Parameters:**

- `collection` - Collection name (required)
- `docId` - Document ID (required)

**Returns:** Success status

---

### Query Operations

#### countDocuments

```dart
Future<CountResponse> countDocuments(
  String collection, {
  QueryBuilder? queryBuilder,
  Map<String, dynamic>? filters,
})
```

**Returns:** Count of matching documents

---

#### aggregateDocuments

```dart
Future<AggregateResponse> aggregateDocuments(
  String collection, {
  required String field,
  required String operation,
  QueryBuilder? queryBuilder,
  Map<String, dynamic>? filters,
})
```

**Parameters:**

- `field` - Field to aggregate (required)
- `operation` - 'sum', 'avg', 'min', 'max' (required)

---

#### groupByField

```dart
Future<GroupByResponse> groupByField(
  String collection, {
  required String field,
  QueryBuilder? queryBuilder,
  Map<String, dynamic>? filters,
})
```

**Parameters:**

- `field` - Field to group by (required)

---

### Batch Operations

#### batchCreateDocuments<T>

```dart
Future<BatchCreateResponse<T>> batchCreateDocuments<T>(
  String collection,
  List<Map<String, dynamic>> documents,
)
```

**Returns:** Response with created documents and count

---

#### batchUpdateDocuments

```dart
Future<BatchUpdateResponse> batchUpdateDocuments(
  String collection,
  List<Map<String, dynamic>> updates,
)
```

**Example:**

```dart
final updates = [
  {'id': 'doc-1', 'price': 19.99},
  {'id': 'doc-2', 'price': 24.99},
];

final result = await db.batchUpdateDocuments("books", updates);
print('Updated: ${result.updated}');
```

---

#### batchDeleteDocuments

```dart
Future<BatchDeleteResponse> batchDeleteDocuments(
  String collection,
  List<String> ids,
)
```

---

### Collection Management

#### createCollection

```dart
Future<Collection> createCollection(Collection collection)
```

**Example:**

```dart
final collection = Collection(
  name: 'books',
  description: 'Book catalog',
  fields: {
    'title': {'type': 'string', 'required': true},
    'price': {'type': 'number'},
  },
);

final created = await db.createCollection(collection);
```

---

#### listCollections

```dart
Future<List<Collection>> listCollections()
```

---

#### getCollection

```dart
Future<Collection> getCollection(String name)
```

---

#### updateCollection

```dart
Future<Collection> updateCollection(Collection collection)
```

---

#### deleteCollection

```dart
Future<Map<String, bool>> deleteCollection(String name)
```

---

#### getCollectionSchema

```dart
Future<SchemaResponse> getCollectionSchema(String collection)
```

---

### Authentication

#### register

```dart
Future<TokenResponse> register({
  required String email,
  required String password,
})
```

**Returns:** Token and user ID

---

#### login

```dart
Future<TokenResponse> login({
  required String email,
  required String password,
})
```

---

#### getCurrentUser

```dart
Future<AppUser> getCurrentUser()
```

**Returns:** Current authenticated user

---

#### updateUser

```dart
Future<void> updateUser({
  String? name,
  String? avatar,
  Map<String, dynamic>? metadata,
})
```

---

#### isAuthenticated

```dart
Future<bool> isAuthenticated()
```

---

#### logout

```dart
Future<void> logout()
```

---

### Real-Time Operations

#### watchCollection

```dart
Connection watchCollection(
  String collection,
  Function(Map<String, dynamic>) onEvent, {
  String? connectionName,
  Function()? onConnected,
  Function()? onConnectionError,
})
```

**Parameters:**

- `collection` - Collection name to watch (required)
- `onEvent` - Callback function for events (required)
- `connectionName` - Optional name for this connection
- `onConnected` - Optional callback when connected
- `onConnectionError` - Optional callback on error

**Example:**

```dart
Connection conn = db.watchCollection(
  "books",
  (event) {
    print('Event: ${event['event']}');
  },
);
db.closeConnection(conn);
```

#### closeConnection

```dart
void closeConnection(Connection connection)
```

**Parameters:**

- `connection` - The Connection object from watchCollection

**Example:**

```dart
final conn = db.watchCollection("books", (event) { ... });
db.closeConnection(conn);
```

## CocobaseConfig

Configuration for the SDK.

```dart
class CocobaseConfig {
  final String apiKey;
  final String? baseUrl;

  CocobaseConfig({
    required this.apiKey,
    this.baseUrl = 'https://api.cocobase.buzz',
  });
}
```

---

## QueryBuilder Class

Fluent API for building complex queries.

### Comparison Methods

```dart
// Equality
QueryBuilder where(String field, dynamic value)

// Comparison
QueryBuilder whereGreaterThan(String field, dynamic value)
QueryBuilder whereGreaterThanOrEqual(String field, dynamic value)
QueryBuilder whereLessThan(String field, dynamic value)
QueryBuilder whereLessThanOrEqual(String field, dynamic value)
QueryBuilder whereNotEqual(String field, dynamic value)

// String operations
QueryBuilder whereContains(String field, String value)
QueryBuilder whereStartsWith(String field, String value)
QueryBuilder whereEndsWith(String field, String value)

// List operations
QueryBuilder whereIn(String field, List<dynamic> values)
QueryBuilder whereNotIn(String field, List<dynamic> values)

// Null check
QueryBuilder whereIsNull(String field, bool isNull)

// Bulk add
QueryBuilder whereAll(Map<String, dynamic> filters)
```

---

### OR Methods

```dart
// Simple OR
QueryBuilder or(String field, dynamic value)
QueryBuilder orGreaterThan(String field, dynamic value)
QueryBuilder orContains(String field, String value)
// ... all comparison methods with 'or' prefix

// Search across fields
QueryBuilder searchInFields(
  List<String> fields,
  String value,
)

// Named OR groups
QueryBuilder orGroup(
  String groupName,
  String field,
  dynamic value,
)
```

---

### Relationship Methods

```dart
// Single field population
QueryBuilder populate(String field)

// Multiple fields
QueryBuilder populateAll(List<String> fields)
```

---

### Selection Methods

```dart
// Single field
QueryBuilder select(String field)

// Multiple fields
QueryBuilder selectAll(List<String> fields)
```

---

### Sorting Methods

```dart
QueryBuilder orderByAsc(String field)
QueryBuilder orderByDesc(String field)
QueryBuilder sortBy(String field, String order)
```

---

### Pagination Methods

```dart
QueryBuilder limit(int value)
QueryBuilder offset(int value)
QueryBuilder take(int value)      // Alias for limit
QueryBuilder skip(int value)      // Alias for offset
```

---

### Utility Methods

```dart
String build()           // Get query string
QueryBuilder clone()     // Deep copy
void clear()            // Reset all filters
```

---

## Document Class

Generic document wrapper with metadata.

```dart
class Document<T> {
  final String id;
  final dynamic collection;
  final T data;
  final DateTime createdAt;
  final DateTime updatedAt;

  Document({
    required this.id,
    required this.collection,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json)

  Map<String, dynamic> toJson()

  @override
  String toString()
}
```

---

## Response Models

### Collection

```dart
class Collection {
  final String name;
  final String? description;
  final Map<String, dynamic> fields;
  final int documentCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String>? indexes;
  final String? primaryKey;
}
```

### CountResponse

```dart
class CountResponse {
  final int count;
  final int totalDocuments;
}
```

### AggregateResponse

```dart
class AggregateResponse {
  final dynamic value;
  final String operation;
  final int? count;
}
```

### GroupByResponse

```dart
class GroupByResponse {
  final List<GroupByItem> groups;
  final int totalGroups;
  final int totalDocuments;
}

class GroupByItem {
  final dynamic key;
  final int count;
}
```

### Batch Responses

```dart
class BatchCreateResponse<T> {
  final int created;
  final int failed;
  final List<Document<T>> documents;
}

class BatchUpdateResponse {
  final int updated;
  final int failed;
  final List<String> errorIds;
}

class BatchDeleteResponse {
  final int deleted;
  final int failed;
  final List<String> errorIds;
}
```

### Authentication Responses

```dart
class TokenResponse {
  final String userId;
  final String token;
  final String? refreshToken;
  final int? expiresIn;
}

class AppUser {
  final String id;
  final String email;
  final String? name;
  final String? avatar;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

### Real-Time Responses

```dart
class WatchEvent {
  final String type;  // 'create', 'update', 'delete', 'connected'
  final Document<dynamic> data;
  final DateTime timestamp;
}

class Connection {
  final String id;
  final bool isConnected;
  final DateTime connectedAt;
}
```

---

## Converter Registry

### CocobaseConverters

```dart
class CocobaseConverters {
  // Register a converter
  static void register<T>(
    T Function(Map<String, dynamic>) converter,
  )

  // Get a registered converter
  static T? Function(Map<String, dynamic>)? get<T>()

  // Check if registered
  static bool hasConverter<T>()

  // Clear all converters
  static void clear()
}
```

**Example:**

```dart
CocobaseConverters.register<Book>(Book.fromJson);
CocobaseConverters.register<Author>(Author.fromJson);

final hasBook = CocobaseConverters.hasConverter<Book>();
```

---

## Error Handling

### Exception Types

Most errors throw `DioException` from the Dio package:

```dart
import 'package:dio/dio.dart';

try {
  final docs = await db.listDocuments("books");
} on DioException catch (e) {
  print('Status: ${e.response?.statusCode}');
  print('Message: ${e.message}');
  print('Data: ${e.response?.data}');
}
```

### Common Status Codes

| Code | Meaning             | Solution                                      |
| ---- | ------------------- | --------------------------------------------- |
| 400  | Bad Request         | Check query parameters                        |
| 401  | Unauthorized        | Check API key or login                        |
| 403  | Forbidden           | Check permissions                             |
| 404  | Not Found           | Check collection/document name                |
| 409  | Conflict            | Email already registered or unique constraint |
| 500  | Server Error        | Contact support                               |
| 503  | Service Unavailable | Try again later                               |

---

## Type Aliases

```dart
// Converter function type
typedef T Converter<T>(Map<String, dynamic> json);

// Watch event callback
typedef void WatchCallback(WatchEvent event);
```

---

## Constants

```dart
const String DEFAULT_BASE_URL = 'https://api.cocobase.buzz';
const int DEFAULT_TIMEOUT_MS = 30000;
const int DEFAULT_RETRY_COUNT = 3;
```

---

**← [Common Issues](08-COMMON_ISSUES.md) | [Back to Docs](README.md)**
