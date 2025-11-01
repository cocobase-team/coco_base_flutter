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
  Future<Document<T>> getDocument<T>(
    String collection,
    String docId, {
    List<String>? populate,
  }) async {
    String path = '/collections/$collection/documents/$docId';

    if (populate != null && populate.isNotEmpty) {
      final populateParams = populate.map((p) => 'populate=$p').join('&');
      path = '$path?$populateParams';
    }

    final response = await _request<Map<String, dynamic>>('GET', path);
    return Document<T>.fromJson(response);
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

  /// List documents with QueryBuilder
  Future<List<Document<T>>> listDocuments<T>(
    String collection, {
    QueryBuilder? queryBuilder,
  }) async {
    final queryStr = queryBuilder?.build() ?? '';

    final path =
        '/collections/$collection/documents'
        '${queryStr.isNotEmpty ? '?$queryStr' : ''}';

    final response = await _request<List<dynamic>>('GET', path);
    return response.map((json) => Document<T>.fromJson(json)).toList();
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
  Future<CountResponse> countDocuments(
    String collection, {
    QueryBuilder? queryBuilder,
  }) async {
    final queryStr = queryBuilder?.build() ?? '';

    final path =
        '/collections/$collection/query/documents/count'
        '${queryStr.isNotEmpty ? '?$queryStr' : ''}';

    final response = await _request<Map<String, dynamic>>('GET', path);
    return CountResponse.fromJson(response);
  }

  /// Aggregate documents (sum, avg, min, max)
  Future<AggregateResponse> aggregateDocuments(
    String collection, {
    required String field,
    required String operation,
    QueryBuilder? queryBuilder,
  }) async {
    String queryStr = 'field=$field&operation=$operation';

    if (queryBuilder != null) {
      final builderQuery = queryBuilder.build();
      if (builderQuery.isNotEmpty) {
        queryStr = '$queryStr&$builderQuery';
      }
    }

    final path = '/collections/$collection/query/documents/aggregate?$queryStr';
    final response = await _request<Map<String, dynamic>>('GET', path);
    return AggregateResponse.fromJson(response);
  }

  /// Group documents by field value
  Future<GroupByResponse> groupByField(
    String collection, {
    required String field,
    QueryBuilder? queryBuilder,
  }) async {
    String queryStr = 'field=$field';

    if (queryBuilder != null) {
      final builderQuery = queryBuilder.build();
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
    final response = await _request<Map<String, dynamic>>(
      'POST',
      '/auth-collections/login',
      body: {'email': email, 'password': password},
      useDataKey: false,
    );

    final tokenResponse = TokenResponse.fromJson(response);
    _token = tokenResponse.accessToken;
    await setToken(_token!);
    user = await getCurrentUser();
  }

  /// Register a new user
  Future<void> register(
    String email,
    String password, {
    Map<String, dynamic>? data,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      'POST',
      '/auth-collections/signup',
      body: {'email': email, 'password': password, 'data': data},
      useDataKey: false,
    );

    final tokenResponse = TokenResponse.fromJson(response);
    _token = tokenResponse.accessToken;
    await setToken(_token!);
    await getCurrentUser();
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

  /// Watch a collection for real-time updates
  Connection watchCollection(
    String collection,
    Function(Map<String, dynamic>) callback, {
    String? connectionName,
    Function()? onOpen,
    Function()? onError,
  }) {
    final wsUrl =
        '${baseURL.replaceAll('http', 'ws')}/realtime/collections/$collection';
    final channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    bool isClosed = false;

    channel.stream.listen(
      (message) {
        final data = jsonDecode(message);
        callback({'event': data['event'], 'data': data['data']});
      },
      onError: (error) {
        if (onError != null) onError();
      },
      onDone: () {
        isClosed = true;
      },
    );

    // Send API key after connection
    channel.sink.add(jsonEncode({'api_key': apiKey}));

    if (onOpen != null) onOpen();

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
  void closeConnection(Connection connection) {
    connection.close();
  }
}
