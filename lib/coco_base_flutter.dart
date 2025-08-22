import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Types
class CocobaseConfig {
  final String apiKey;
  
  CocobaseConfig({required this.apiKey});
}

class Document<T> {
  final String id;
  final String collection;
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
  
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document<T>(
      id: json['id'],
      collection: json['collection'],
      data: json['data'] as T,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class TokenResponse {
  final String accessToken;
  final String tokenType;
  
  TokenResponse({required this.accessToken, required this.tokenType});
  
  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'] ?? 'Bearer',
    );
  }
}

class AppUser {
  final String id;
  final String email;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  AppUser({
    required this.id,
    required this.email,
    this.data,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      data: json['data'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Query {
  final Map<String, dynamic>? where;
  final String? orderBy;
  final int? limit;
  final int? offset;
  
  Query({this.where, this.orderBy, this.limit, this.offset});
}

class Connection {
  final WebSocketChannel socket;
  final String name;
  bool closed;
  final Function() close;
  
  Connection({
    required this.socket,
    required this.name,
    required this.closed,
    required this.close,
  });
}

// Utils
const String BASEURL = 'https://api.cocobase.com';

String buildFilterQuery(Query? query) {
  if (query == null) return '';
  
  List<String> params = [];
  
  if (query.where != null) {
    query.where!.forEach((key, value) {
      params.add('$key=${Uri.encodeComponent(value.toString())}');
    });
  }
  
  if (query.orderBy != null) {
    params.add('orderBy=${Uri.encodeComponent(query.orderBy!)}');
  }
  
  if (query.limit != null) {
    params.add('limit=${query.limit}');
  }
  
  if (query.offset != null) {
    params.add('offset=${query.offset}');
  }
  
  return params.join('&');
}

Future<String?> getFromLocalStorage(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}

Future<void> setToLocalStorage(String key, String value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

Map<String, dynamic> mergeUserData(Map<String, dynamic> existing, Map<String, dynamic> updates) {
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
  
  Cocobase(CocobaseConfig config) 
    : baseURL = BASEURL,
      apiKey = config.apiKey {
    _dio = Dio(BaseOptions(
      baseUrl: baseURL,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {'Content-Type': 'application/json'},
    ));
    
    // Add interceptors for auth and API key
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (apiKey != null) {
          options.headers['x-api-key'] = apiKey;
        }
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
    ));
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
      throw Exception('Unexpected error during $method request to $baseURL$path: $error');
    }
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
  
  // Fetch a single document
  Future<Document<T>> getDocument<T>(String collection, String docId) async {
    final response = await _request<Map<String, dynamic>>(
      'GET',
      '/collections/$collection/documents/$docId',
    );
    return Document<T>.fromJson(response);
  }
  
  // Create a new document
  Future<Document<T>> createDocument<T>(String collection, T data) async {
    final response = await _request<Map<String, dynamic>>(
      'POST',
      '/collections/documents?collection=$collection',
      body: data,
    );
    return Document<T>.fromJson(response);
  }
  
  // Update a document
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
  
  // Delete a document
  Future<Map<String, bool>> deleteDocument(String collection, String docId) async {
    return await _request<Map<String, bool>>(
      'DELETE',
      '/collections/$collection/documents/$docId',
    );
  }
  
  // List documents
  Future<List<Document<T>>> listDocuments<T>(String collection, {Query? query}) async {
    final queryStr = buildFilterQuery(query);
    final path = '/collections/$collection/documents${queryStr.isNotEmpty ? '?$queryStr' : ''}';
    
    final response = await _request<List<dynamic>>('GET', path);
    return response.map((json) => Document<T>.fromJson(json)).toList();
  }
  
  // Authentication features
  Future<void> initAuth() async {
    final token = await getFromLocalStorage('cocobase-token');
    final userStr = await getFromLocalStorage('cocobase-user');
    
    if (token != null) {
      _token = token;
      if (userStr != null) {
        user = AppUser.fromJson(jsonDecode(userStr));
      } else {
        user = null;
        await getCurrentUser();
      }
    } else {
      _token = null;
    }
  }
  
  Future<void> setToken(String token) async {
    _token = token;
    await setToLocalStorage('cocobase-token', token);
  }
  
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
  
  Future<void> register(String email, String password, {Map<String, dynamic>? data}) async {
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
  
  void logout() {
    _token = null;
  }
  
  bool isAuthenticated() {
    return _token != null;
  }
  
  Future<AppUser> getCurrentUser() async {
    if (_token == null) {
      throw Exception('User is not authenticated');
    }
    
    final response = await _request<Map<String, dynamic>>('GET', '/auth-collections/user');
    if (response.isEmpty) {
      throw Exception('Failed to fetch current user');
    }
    
    user = AppUser.fromJson(response);
    await setToLocalStorage('cocobase-user', jsonEncode(user!.toJson()));
    return user!;
  }
  
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
    await setToLocalStorage('cocobase-user', jsonEncode(user!.toJson()));
    return user!;
  }
  
  Connection watchCollection(
    String collection,
    Function(Map<String, dynamic>) callback, {
    String? connectionName,
    Function()? onOpen,
    Function()? onError,
  }) {
    final wsUrl = '${baseURL.replaceAll('http', 'ws')}/realtime/collections/$collection';
    final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    
    bool isClosed = false;
    
    channel.stream.listen(
      (message) {
        final data = jsonDecode(message);
        callback({
          'event': data['event'],
          'data': data['data'],
        });
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
  
  void closeConnection(Connection connection) {
    connection.close();
  }
}