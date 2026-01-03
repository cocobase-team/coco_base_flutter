library;

import 'dart:convert';
import 'package:coco_base_flutter/query.dart';
import 'package:coco_base_flutter/models.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

export 'package:coco_base_flutter/query.dart';
export 'package:coco_base_flutter/models.dart';

// Authstore
/// ALLOWS USER TO IMPLEMENT CUSTOM AUTH STORAGE MECHANISMS
class AuthStore {
  Function(void) setToken;
  Future<String?> Function() getToken;

  AuthStore({required this.setToken, required this.getToken});
}

// Config
class CocobaseConfig {
  final String apiKey;
  final String? baseUrl;
  final AuthStore? authStore;
  CocobaseConfig({required this.apiKey, this.baseUrl, this.authStore});
}

// Utils
const String DEFAULT_BASEURL = 'https://api.cocobase.buzz';

Map<String, dynamic> mergeUserData(
  Map<String, dynamic> existing,
  Map<String, dynamic> updates,
) {
  final merged = Map<String, dynamic>.from(existing);
  updates.forEach((key, value) {
    merged[key] = value;
  });
  return merged;
}

// Main Cocobase class
class Cocobase {
  final String baseURL;
  String? apiKey;
  String? _token;
  AppUser? user;
  late final Dio _dio;
  final CocobaseConfig config;
  Cocobase(CocobaseConfig config)
    : baseURL = config.baseUrl ?? DEFAULT_BASEURL,
      apiKey = config.apiKey,
      config = config {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseURL,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add interceptors for auth and API key
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (apiKey != null) {
            options.headers['x-api-key'] = apiKey;
          }
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<T> _request<T>(
    String method,
    String path, {
    dynamic body,
    bool useDataKey = true,
  }) async {
    final data = useDataKey ? {'data': body} : body;

    try {
      Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _dio.get(path);
          break;
        case 'POST':
          response = await _dio.post(path, data: body != null ? data : null);
          break;
        case 'PATCH':
          response = await _dio.patch(path, data: body != null ? data : null);
          break;
        case 'DELETE':
          response = await _dio.delete(path);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      return response.data as T;
    } on DioException catch (e) {
      final errorMessage = {
        'statusCode': e.response?.statusCode ?? 0,
        'url': '$baseURL$path',
        'method': method,
        'error': e.response?.data ?? e.message,
        'suggestions': _getErrorSuggestion(e.response?.statusCode ?? 0, method),
      };

      throw Exception('Request failed:\n${jsonEncode(errorMessage)}');
    } catch (error) {
      throw Exception(
        'Unexpected error during $method request to $baseURL$path: $error',
      );
    }
  }

  Future<String> uploadFileFromPath({
    required String filepath,
    String? fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filepath, filename: fileName),
    });
    final response = await _request(
      'POST',
      "/collections/file",
      body: formData,
    );

    return response['url'];
  }

  String _getErrorSuggestion(int status, String method) {
    switch (status) {
      case 401:
        return 'Check if your API key is valid and properly set';
      case 403:
        return 'You don\'t have permission to perform this action. Verify your access rights';
      case 404:
        return 'The requested resource was not found. Verify the path and ID are correct';
      case 405:
        return 'The $method method is not allowed for this endpoint. Check the API documentation for supported methods';
      case 429:
        return 'You\'ve exceeded the rate limit. Please wait before making more requests';
      default:
        return 'Check the API documentation and verify your request format';
    }
  }

  // ============================================================================
  // COLLECTIONS MANAGEMENT
  // ============================================================================

  /// Create a new collection
  Future<Collection> createCollection(String name) async {
    final response = await _request<Map<String, dynamic>>(
      'POST',
      '/collections/',
      body: {'name': name},
      useDataKey: false,
    );
    return Collection.fromJson(response);
  }

  /// List all collections
  Future<List<Collection>> listCollections() async {
    final response = await _request<List<dynamic>>('GET', '/collections/');
    return response.map((json) => Collection.fromJson(json)).toList();
  }

  /// Get a specific collection by name or ID
  Future<Collection> getCollection(String nameOrId) async {
    final response = await _request<Map<String, dynamic>>(
      'GET',
      '/collections/$nameOrId',
    );
    return Collection.fromJson(response);
  }

  /// Update a collection's name
  Future<Collection> updateCollection(String nameOrId, String newName) async {
    final response = await _request<Map<String, dynamic>>(
      'PATCH',
      '/collections/$nameOrId',
      body: {'name': newName},
      useDataKey: false,
    );
    return Collection.fromJson(response);
  }

  /// Delete a collection (WARNING: This deletes all documents!)
  Future<Map<String, bool>> deleteCollection(String nameOrId) async {
    return await _request<Map<String, bool>>(
      'DELETE',
      '/collections/$nameOrId',
    );
  }

  // ============================================================================
  // DOCUMENTS MANAGEMENT
  // ============================================================================

  /// Fetch a single document with optional relationship population
  ///
  /// [T] is the type of data in the document
  /// [converter] is optional - use it to convert Map data to your custom type.
  /// If not provided, tries to use a registered converter from [CocobaseConverters].
  ///
  /// Example 1 - With explicit converter:
  /// ```dart
  /// final book = await db.getDocument<Book>("books", "doc-id",
  ///   converter: Book.fromJson);
  /// print(book.data.title);  // Type-safe!
  /// ```
  ///
  /// Example 2 - With auto-registered converter (recommended):
  /// ```dart
  /// // Register once (in main or app initialization)
  /// CocobaseConverters.register<Book>(Book.fromJson);
  ///
  /// // Use without passing converter everywhere
  /// final book = await db.getDocument<Book>("books", "doc-id");
  /// print(book.data.title);  // Type-safe!
  /// ```
  Future<Document<T>> getDocument<T>(
    String collection,
    String docId, {
    List<String>? populate,
    T Function(Map<String, dynamic>)? converter,
  }) async {
    String path = '/collections/$collection/documents/$docId';

    if (populate != null && populate.isNotEmpty) {
      final populateParams = populate.map((p) => 'populate=$p').join('&');
      path = '$path?$populateParams';
    }

    final response = await _request<Map<String, dynamic>>('GET', path);
    final doc = Document<Map<String, dynamic>>.fromJson(response);

    // Try to get converter: explicit parameter, then registry, then return as-is
    final finalConverter = converter ?? CocobaseConverters.get<T>();

    if (finalConverter == null) {
      return Document<T>(
        id: doc.id,
        collection: doc.collection,
        data: doc.data as T,
        createdAt: doc.createdAt,
        updatedAt: doc.updatedAt,
      );
    }

    // If converter found (explicit or from registry), convert the data
    return Document<T>(
      id: doc.id,
      collection: doc.collection,
      data: finalConverter(doc.data),
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    );
  }

  /// Create a new document
  Future<Document<T>> createDocument<T>(String collection, T data) async {
    final response = await _request<Map<String, dynamic>>(
      'POST',
      '/collections/$collection/documents',
      body: data,
    );
    return Document<T>.fromJson(response);
  }

  /// Update a document
  Future<Document<T>> updateDocument<T>(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final response = await _request<Map<String, dynamic>>(
      'PATCH',
      '/collections/$collection/documents/$docId',
      body: data,
    );
    return Document<T>.fromJson(response);
  }

  /// Delete a document
  Future<Map<String, bool>> deleteDocument(
    String collection,
    String docId,
  ) async {
    return await _request<Map<String, bool>>(
      'DELETE',
      '/collections/$collection/documents/$docId',
    );
  }

  /// List documents with optional QueryBuilder or simple filter map
  ///
  /// [T] is the type of data in each document
  /// [queryBuilder] - Use for complex queries with multiple operators
  /// [filters] - Simple alternative: pass filters as a Map (uses __gt, __lt, __contains, etc.)
  /// [converter] is optional - use it to convert Map data to your custom type
  ///
  /// Example 1: No filters (returns all documents)
  /// ```dart
  /// final docs = await db.listDocuments("books");
  /// print(docs[0].data['title']);
  /// ```
  ///
  /// Example 2: Simple filters as Map (easiest for beginners)
  /// ```dart
  /// final books = await db.listDocuments<Book>("books",
  ///   filters: {'status': 'published', 'rating__gt': 4});
  /// print(books[0].data.title);
  /// ```
  ///
  /// Example 3: QueryBuilder for complex queries
  /// ```dart
  /// final books = await db.listDocuments<Book>("books",
  ///   queryBuilder: QueryBuilder()
  ///     .where('status', 'published')
  ///     .whereGreaterThan('rating', 4)
  ///     .limit(10));
  /// ```
  ///
  /// Example 4: With auto-registered converter (recommended)
  /// ```dart
  /// CocobaseConverters.register<Book>(Book.fromJson);
  /// final books = await db.listDocuments<Book>("books",
  ///   filters: {'status': 'published'});
  /// print(books[0].data.title);  // Type-safe!
  /// ```
  Future<List<Document<T>>> listDocuments<T>(
    String collection, {
    QueryBuilder? queryBuilder,
    Map<String, dynamic>? filters,
    T Function(Map<String, dynamic>)? converter,
  }) async {
    // If filters map is provided, convert to QueryBuilder
    final finalBuilder = filters != null
        ? QueryBuilder().whereAll(filters)
        : queryBuilder;

    final queryStr = finalBuilder?.build() ?? '';

    final path =
        '/collections/$collection/documents'
        '${queryStr.isNotEmpty ? '?$queryStr' : ''}';

    final response = await _request<List<dynamic>>('GET', path);

    return response.map((json) {
      final doc = Document<Map<String, dynamic>>.fromJson(json);

      // Try to get converter from parameter, then from registry
      final finalConverter = converter ?? CocobaseConverters.get<T>();

      // If no converter provided or found, return as-is with dynamic data
      if (finalConverter == null) {
        return Document<T>(
          id: doc.id,
          collection: doc.collection,
          data: doc.data as T,
          createdAt: doc.createdAt,
          updatedAt: doc.updatedAt,
        );
      }

      // Convert the data using the converter
      return Document<T>(
        id: doc.id,
        collection: doc.collection,
        data: finalConverter(doc.data),
        createdAt: doc.createdAt,
        updatedAt: doc.updatedAt,
      );
    }).toList();
  }

  // ============================================================================
  // BATCH OPERATIONS
  // ============================================================================

  /// Batch create multiple documents
  Future<BatchCreateResponse<T>> batchCreateDocuments<T>(
    String collection,
    List<Map<String, dynamic>> documents,
  ) async {
    final response = await _request<Map<String, dynamic>>(
      'POST',
      '/collections/$collection/batch/documents/create',
      body: {'documents': documents},
      useDataKey: false,
    );
    return BatchCreateResponse<T>.fromJson(response);
  }

  /// Batch update multiple documents by ID
  Future<BatchUpdateResponse> batchUpdateDocuments(
    String collection,
    List<Map<String, dynamic>> updates,
  ) async {
    final response = await _request<Map<String, dynamic>>(
      'PATCH',
      '/collections/$collection/batch/documents/update',
      body: {'updates': updates},
      useDataKey: false,
    );
    return BatchUpdateResponse.fromJson(response);
  }

  /// Batch delete multiple documents by ID
  Future<BatchDeleteResponse> batchDeleteDocuments(
    String collection,
    List<String> ids,
  ) async {
    final response = await _request<Map<String, dynamic>>(
      'DELETE',
      '/collections/$collection/batch/documents/delete',
      body: {'ids': ids},
      useDataKey: false,
    );
    return BatchDeleteResponse.fromJson(response);
  }

  // ============================================================================
  // ADVANCED QUERY FEATURES
  // ============================================================================

  /// Count documents matching the query
  ///
  /// [queryBuilder] - For complex queries with multiple operators
  /// [filters] - Simple alternative: pass filters as a Map
  ///
  /// Example 1: Count all documents
  /// ```dart
  /// final count = await db.countDocuments("books");
  /// ```
  ///
  /// Example 2: Count with filters map
  /// ```dart
  /// final count = await db.countDocuments("books",
  ///   filters: {'status': 'published', 'rating__gt': 4});
  /// ```
  ///
  /// Example 3: Count with QueryBuilder
  /// ```dart
  /// final count = await db.countDocuments("books",
  ///   queryBuilder: QueryBuilder().where('status', 'published'));
  /// ```
  Future<CountResponse> countDocuments(
    String collection, {
    QueryBuilder? queryBuilder,
    Map<String, dynamic>? filters,
  }) async {
    // If filters map is provided, convert to QueryBuilder
    final finalBuilder = filters != null
        ? QueryBuilder().whereAll(filters)
        : queryBuilder;

    final queryStr = finalBuilder?.build() ?? '';

    final path =
        '/collections/$collection/query/documents/count'
        '${queryStr.isNotEmpty ? '?$queryStr' : ''}';

    final response = await _request<Map<String, dynamic>>('GET', path);
    return CountResponse.fromJson(response);
  }

  /// Aggregate documents (sum, avg, min, max)
  ///
  /// [field] - The field to aggregate on
  /// [operation] - One of: 'sum', 'avg', 'min', 'max'
  /// [queryBuilder] - For complex filtering
  /// [filters] - Simple alternative: pass filters as a Map
  ///
  /// Example 1: Sum with filters map
  /// ```dart
  /// final result = await db.aggregateDocuments("books",
  ///   field: 'price',
  ///   operation: 'sum',
  ///   filters: {'status': 'published'});
  /// print(result.value);  // Total price
  /// ```
  ///
  /// Example 2: Average with QueryBuilder
  /// ```dart
  /// final result = await db.aggregateDocuments("books",
  ///   field: 'rating',
  ///   operation: 'avg',
  ///   queryBuilder: QueryBuilder().whereGreaterThan('votes', 10));
  /// ```
  Future<AggregateResponse> aggregateDocuments(
    String collection, {
    required String field,
    required String operation,
    QueryBuilder? queryBuilder,
    Map<String, dynamic>? filters,
  }) async {
    // If filters map is provided, convert to QueryBuilder
    final finalBuilder = filters != null
        ? QueryBuilder().whereAll(filters)
        : queryBuilder;

    String queryStr = 'field=$field&operation=$operation';

    if (finalBuilder != null) {
      final builderQuery = finalBuilder.build();
      if (builderQuery.isNotEmpty) {
        queryStr = '$queryStr&$builderQuery';
      }
    }

    final path = '/collections/$collection/query/documents/aggregate?$queryStr';
    final response = await _request<Map<String, dynamic>>('GET', path);
    return AggregateResponse.fromJson(response);
  }

  /// Group documents by field value
  ///
  /// [field] - The field to group by
  /// [queryBuilder] - For complex filtering
  /// [filters] - Simple alternative: pass filters as a Map
  ///
  /// Example 1: Group with filters map
  /// ```dart
  /// final result = await db.groupByField("orders",
  ///   field: 'status',
  ///   filters: {'year': 2024});
  /// ```
  ///
  /// Example 2: Group with QueryBuilder
  /// ```dart
  /// final result = await db.groupByField("orders",
  ///   field: 'status',
  ///   queryBuilder: QueryBuilder().whereGreaterThan('total', 100));
  /// ```
  Future<GroupByResponse> groupByField(
    String collection, {
    required String field,
    QueryBuilder? queryBuilder,
    Map<String, dynamic>? filters,
  }) async {
    // If filters map is provided, convert to QueryBuilder
    final finalBuilder = filters != null
        ? QueryBuilder().whereAll(filters)
        : queryBuilder;

    String queryStr = 'field=$field';

    if (finalBuilder != null) {
      final builderQuery = finalBuilder.build();
      if (builderQuery.isNotEmpty) {
        queryStr = '$queryStr&$builderQuery';
      }
    }

    final path = '/collections/$collection/query/documents/group-by?$queryStr';
    final response = await _request<List<dynamic>>('GET', path);
    return GroupByResponse.fromJson(response);
  }

  /// Get collection schema
  Future<SchemaResponse> getCollectionSchema(String collection) async {
    final response = await _request<Map<String, dynamic>>(
      'GET',
      '/collections/$collection/query/schema',
    );
    return SchemaResponse.fromJson(response);
  }

  /// Export collection data
  Future<dynamic> exportCollection(
    String collection, {
    String format = 'json',
    List<String>? populate,
  }) async {
    String queryStr = 'format=$format';

    if (populate != null && populate.isNotEmpty) {
      final populateParams = populate.map((p) => 'populate=$p').join('&');
      queryStr = '$queryStr&$populateParams';
    }

    final path = '/collections/$collection/export?$queryStr';
    final response = await _request('GET', path);
    return response;
  }

  // ============================================================================
  // LEGACY DOCUMENT METHODS (Kept for backward compatibility)
  // ============================================================================

  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  /// Initialize authentication from local storage
  Future<void> initAuth() async {
    final token = await config.authStore?.getToken();

    if (token != null) {
      _token = token;
      await getCurrentUser();
    } else {
      _token = null;
    }
  }

  /// Set authentication token
  Future<void> setToken(String token) async {
    _token = token;
    config.authStore?.setToken(token);
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    try {
      final response = await _request<Map<String, dynamic>>(
        'POST',
        '/auth-collections/login',
        body: {'email': email, 'password': password},
        useDataKey: false,
      );

      final tokenResponse = TokenResponse.fromJson(response);
      if (tokenResponse.accessToken.isNotEmpty) {
        _token = tokenResponse.accessToken;
        await setToken(_token!);
        
        // Fetch user info after successful login
        try {
          user = await getCurrentUser();
        } catch (e) {
          // If getCurrentUser fails, continue anyway - user is logged in
        }
      } else {
        throw Exception('No access token received from server');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Register a new user
  Future<void> register(
    String email,
    String password, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _request<Map<String, dynamic>>(
        'POST',
        '/auth-collections/signup',
        body: {'email': email, 'password': password, 'data': data},
        useDataKey: false,
      );

      final tokenResponse = TokenResponse.fromJson(response);
      _token = tokenResponse.accessToken;
      await setToken(_token!);
      
      // Fetch user info after successful registration
      try {
        await getCurrentUser();
      } catch (e) {
        // If getCurrentUser fails, continue anyway - user is registered
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Logout the current user
  void logout() {
    _token = null;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _token != null;
  }

  /// Get the current authenticated user
  Future<AppUser> getCurrentUser() async {
    if (_token == null) {
      throw Exception('User is not authenticated');
    }

    final response = await _request<Map<String, dynamic>>(
      'GET',
      '/auth-collections/user',
    );
    if (response.isEmpty) {
      throw Exception('Failed to fetch current user');
    }

    user = AppUser.fromJson(response);
    return user!;
  }

  /// Update the current user's information
  Future<AppUser> updateUser({
    Map<String, dynamic>? data,
    String? email,
    String? password,
  }) async {
    if (_token == null) {
      throw Exception('User is not authenticated');
    }

    final Map<String, dynamic> body = {};
    if (data != null) {
      body['data'] = mergeUserData(user?.data ?? {}, data);
    }
    if (email != null) body['email'] = email;
    if (password != null) body['password'] = password;

    final response = await _request<Map<String, dynamic>>(
      'PATCH',
      '/auth-collections/user',
      body: body,
      useDataKey: false,
    );

    user = AppUser.fromJson(response);
    return user!;
  }

  // ============================================================================
  // REALTIME FEATURES
  // ============================================================================

  /// Watch a collection for real-time updates via WebSocket
  ///
  /// Establishes a persistent WebSocket connection to receive live events
  /// when documents in the collection are created, updated, or deleted.
  ///
  /// **Parameters:**
  /// - `collection` - Name of the collection to watch (required)
  /// - `onEvent` - Callback function called when events occur (required)
  ///   - Receives `{'event': 'string', 'data': Map<String, dynamic>}`
  /// - `connectionName` - Optional name for this connection (for debugging)
  /// - `onConnected` - Optional callback when connection established
  /// - `onConnectionError` - Optional callback when connection fails
  ///
  /// **Returns:** `Connection` object - save this to close the connection later
  ///
  /// **Example:**
  /// ```dart
  /// // Simple usage
  /// final conn = db.watchCollection("books", (event) {
  ///   print('Event: ${event['event']}');
  ///   print('Data: ${event['data']}');
  /// });
  ///
  /// // With all options
  /// final conn = db.watchCollection(
  ///   "books",
  ///   (event) {
  ///     if (event['event'] == 'create') {
  ///       print('New book: ${event['data']}');
  ///     }
  ///   },
  ///   connectionName: 'books-watcher',
  ///   onConnected: () => print('✅ Connected'),
  ///   onConnectionError: () => print('❌ Error'),
  /// );
  ///
  /// // Close when done
  /// db.closeConnection(conn);
  /// ```
  Connection watchCollection(
    String collection,
    Function(Map<String, dynamic>) onEvent, {
    String? connectionName,
    Function()? onConnected,
    Function()? onConnectionError,
  }) {
    final wsUrl =
        '${baseURL.replaceAll('http', 'ws')}/realtime/collections/$collection';
    final channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    bool isClosed = false;

    channel.stream.listen(
      (message) {
        final data = jsonDecode(message);
        onEvent({'event': data['event'], 'data': data['data']});
      },
      onError: (error) {
        if (onConnectionError != null) onConnectionError();
      },
      onDone: () {
        isClosed = true;
      },
    );

    // Send API key after connection
    channel.sink.add(jsonEncode({'api_key': apiKey}));

    if (onConnected != null) onConnected();

    return Connection(
      socket: channel,
      name: connectionName ?? 'watch-$collection',
      closed: isClosed,
      close: () {
        if (!isClosed) {
          channel.sink.close();
          isClosed = true;
        }
      },
    );
  }

  /// Close a real-time connection
  ///
  /// Call this when you're done watching a collection to clean up
  /// the WebSocket connection and free resources.
  ///
  /// **Example:**
  /// ```dart
  /// final conn = await db.watchCollection("books", (event) { ... });
  ///
  /// // Later, when done:
  /// db.closeConnection(conn);
  /// ```
  void closeConnection(Connection connection) {
    connection.close();
  }
}
