# Common Issues & Troubleshooting

Solutions to common problems and how to debug them.

## Table of Contents

1. [Authentication Issues](#authentication-issues)
2. [Query Problems](#query-problems)
3. [Type Conversion Errors](#type-conversion-errors)
4. [Performance Issues](#performance-issues)
5. [Network Problems](#network-problems)
6. [Real-Time Issues](#real-time-issues)
7. [Getting Help](#getting-help)

---

## Authentication Issues

### Issue: "API key is invalid"

**Symptoms:**

```
DioException: 401 Unauthorized - Invalid API key
```

**Solutions:**

1. **Verify API Key**

   ```dart
   // Check your API key is correct
   final config = CocobaseConfig(
     apiKey: "YOUR_API_KEY_HERE",  // Copy from dashboard
   );
   ```

2. **Check API Key Format**

   - API keys are typically 32-64 characters
   - Should be alphanumeric
   - Don't add quotes or extra spaces

3. **Verify API Key is Active**

   - Go to CocoBase Dashboard
   - Check if the API key is enabled
   - Check expiration date

4. **Use Environment Variables**
   ```dart
   // ✅ Better approach
   const apiKey = String.fromEnvironment('COCOBASE_API_KEY');
   final config = CocobaseConfig(apiKey: apiKey);
   ```

---

### Issue: "User session expired"

**Symptoms:**

```
DioException: 401 Unauthorized during request
```

**Solutions:**

1. **Implement Token Refresh**

   ```dart
   Future<T> withAutomaticRefresh<T>(
     Future<T> Function() request,
   ) async {
     try {
       return await request();
     } on DioException catch (e) {
       if (e.response?.statusCode == 401) {
         // Token expired - ask user to login again
         await db.logout();
         // Navigate to login screen
         throw Exception('Please login again');
       }
       rethrow;
     }
   }
   ```

2. **Check Token Storage**

   ```dart
   // Verify token is saved correctly
   final isAuth = await db.isAuthenticated();
   print('Authenticated: $isAuth');
   ```

3. **Clear Cache and Retry**
   ```dart
   // Force fresh login
   await db.logout();
   final result = await db.login(
     email: 'user@example.com',
     password: 'password',
   );
   ```

---

### Issue: "Email already registered"

**Symptoms:**

```
DioException: 409 Conflict - Email already in use
```

**Solutions:**

1. **Use Different Email**

   ```dart
   try {
     await db.register(
       email: 'newemail@example.com',
       password: 'SecurePassword123!',
     );
   } on DioException catch (e) {
     if (e.response?.statusCode == 409) {
       print('Email already registered - try another');
     }
   }
   ```

2. **Implement Email Check Before Registration**
   ```dart
   Future<bool> isEmailRegistered(String email) async {
     try {
       await db.login(email: email, password: 'dummy');
       return true;  // If login succeeds, email exists
     } catch (e) {
       return false;  // Email not registered
     }
   }
   ```

---

## Query Problems

### Issue: "No results when expecting data"

**Causes & Solutions:**

1. **Field Name Typo**

   ```dart
   // ❌ Wrong - typo in field name
   final docs = await db.listDocuments("books", filters: {
     'titulo': 'Flutter',  // Typo!
   });

   // ✅ Correct
   final docs = await db.listDocuments("books", filters: {
     'title': 'Flutter',
   });
   ```

2. **Case Sensitivity**

   ```dart
   // Field names are case-sensitive!
   // Make sure you match the exact case from your database schema
   ```

3. **Operator Missing**

   ```dart
   // ❌ Wrong - looking for exact price
   final docs = await db.listDocuments("books", filters: {
     'price': 29.99,  // Exact match only
   });

   // ✅ Correct - use operators
   final docs = await db.listDocuments("books", filters: {
     'price__gte': 20,
     'price__lte': 50,
   });
   ```

4. **Wrong Data Type**

   ```dart
   // ❌ Wrong - comparing string to number
   final docs = await db.listDocuments("books", filters: {
     'price': '29.99',  // String!
   });

   // ✅ Correct - use correct type
   final docs = await db.listDocuments("books", filters: {
     'price': 29.99,  // Number
   });
   ```

---

### Issue: "QueryBuilder not building correct query"

**Debug with `.build()`:**

```dart
final query = QueryBuilder()
  .where('status', 'published')
  .whereGreaterThan('price', 20)
  .limit(10);

// Check what query is generated
print('Query: ${query.build()}');
// Output: status=published&price__gt=20&limit=10
```

---

### Issue: "Pagination not working"

**Common Mistakes:**

```dart
// ❌ Wrong - not using offset
final docs = await db.listDocuments("books", filters: {
  'limit': 20,
  'limit': 40,  // Second limit overwrites first!
});

// ✅ Correct - use offset for pages
final page1 = await db.listDocuments("books", filters: {
  'limit': 20,
  'offset': 0,
});

final page2 = await db.listDocuments("books", filters: {
  'limit': 20,
  'offset': 20,
});
```

---

## Type Conversion Errors

### Issue: "type '\_InternalLinkedHashMap<String, dynamic>' is not a subtype"

**Cause:** Type mismatch in `fromJson()` method

```dart
// ❌ Wrong - assuming wrong type
factory Book.fromJson(Map<String, dynamic> json) {
  return Book(
    price: json['price'] as String,  // API returns number!
  );
}

// ✅ Correct - match actual type
factory Book.fromJson(Map<String, dynamic> json) {
  return Book(
    price: (json['price'] as num).toDouble(),  // Convert properly
  );
}
```

**Fix Strategy:**

```dart
// 1. Check what type the API actually returns
final doc = await db.getDocument("books", "doc-id");
print(doc.data.runtimeType);  // Check actual type
print(doc.data);              // Print the data

// 2. Update your fromJson to match
factory Book.fromJson(Map<String, dynamic> json) {
  return Book(
    price: _parsePrice(json['price']),  // Use helper
  );
}

static double _parsePrice(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  return 0.0;
}
```

---

### Issue: "NoSuchMethodError: The method 'fromJson' was called on null"

**Cause:** Converter not registered

```dart
// ❌ Wrong - forgot to register
final books = await db.listDocuments<Book>("books");

// ✅ Correct - register first
CocobaseConverters.register<Book>(Book.fromJson);
final books = await db.listDocuments<Book>("books");

// Or pass explicit converter
final books = await db.listDocuments<Book>(
  "books",
  converter: Book.fromJson,
);
```

---

### Issue: "null value error when accessing optional field"

**Cause:** Not handling null values

```dart
// ❌ Wrong - force unwrap optional
final subtitle = json['subtitle'] as String;  // Crashes if null!

// ✅ Correct - handle null
final subtitle = json['subtitle'] as String?;  // Nullable

// Or with default
final subtitle = (json['subtitle'] as String?) ?? 'No subtitle';
```

---

## Performance Issues

### Issue: "App is slow when loading many documents"

**Solutions:**

1. **Use Pagination**

   ```dart
   // ❌ Wrong - load everything at once
   final docs = await db.listDocuments("books");

   // ✅ Correct - paginate
   final docs = await db.listDocuments("books", filters: {
     'limit': 50,
     'offset': 0,
   });
   ```

2. **Select Only Needed Fields**

   ```dart
   // ❌ Wrong - fetch all fields
   final docs = await db.listDocuments("books");

   // ✅ Correct - select specific fields
   final docs = await db.listDocuments("books",
     queryBuilder: QueryBuilder()
       .select('id')
       .select('title')
       .select('price'),
   );
   ```

3. **Use Indexes**

   ```dart
   // ❌ Wrong - querying non-indexed field
   final docs = await db.listDocuments("books", filters: {
     'description__contains': 'flutter',  // Slow!
   });

   // ✅ Correct - query indexed field
   final docs = await db.listDocuments("books", filters: {
     'status': 'published',  // Fast if indexed
   });
   ```

---

### Issue: "Memory usage increases over time"

**Solutions:**

1. **Clear Collections**

   ```dart
   class SafeCollectionWatch {
     Future<void> watch(String collection) async {
       final eventBuffer = <WatchEvent>[];

       await db.watchCollection(collection, (event) {
         eventBuffer.add(event);

         // Process and clear buffer periodically
         if (eventBuffer.length >= 100) {
           _processBatch(eventBuffer);
           eventBuffer.clear();
         }
       });
     }
   }
   ```

2. **Dispose Resources**
   ```dart
   @override
   void dispose() {
     db.closeConnection();  // Important!
     super.dispose();
   }
   ```

---

## Network Problems

### Issue: "Network timeout"

**Symptoms:**

```
DioException: Connection timeout after 30000ms
```

**Solutions:**

1. **Check Internet Connection**

   ```dart
   import 'package:connectivity_plus/connectivity_plus.dart';

   Future<bool> hasInternet() async {
     final connectivity = await Connectivity().checkConnectivity();
     return connectivity != ConnectivityResult.none;
   }
   ```

2. **Increase Timeout (if needed)**

   ```dart
   final config = CocobaseConfig(
     apiKey: 'YOUR_KEY',
     baseUrl: 'https://api.cocobase.buzz',
     // Note: SDK doesn't expose timeout yet
     // You may need to configure Dio directly
   );
   ```

3. **Implement Retry Logic**

   ```dart
   Future<T> withRetry<T>(
     Future<T> Function() request, {
     int maxAttempts = 3,
   }) async {
     for (int i = 0; i < maxAttempts; i++) {
       try {
         return await request();
       } catch (e) {
         if (i == maxAttempts - 1) rethrow;
         await Future.delayed(Duration(seconds: 2 << i));  // Exponential backoff
       }
     }
     throw Exception('Max retries exceeded');
   }

   // Use it
   final books = await withRetry(() =>
     db.listDocuments<Book>("books")
   );
   ```

---

### Issue: "Certificate verification failed"

**Cause:** SSL/TLS certificate issue

**Solutions:**

1. **Check HTTPS Configuration**

   ```dart
   // Ensure using HTTPS
   final config = CocobaseConfig(
     apiKey: 'YOUR_KEY',
     baseUrl: 'https://api.cocobase.buzz',  // Must be HTTPS
   );
   ```

2. **Check Date/Time**
   - SSL certificates are time-sensitive
   - Ensure device date/time is correct

---

## Real-Time Issues

### Issue: "WebSocket connection fails"

**Solutions:**

1. **Verify Collection Exists**

   ```dart
   // ✅ Check collection exists before watching
   try {
     final collection = await db.getCollection('books');
     await db.watchCollection('books', (event) {
       print('Event: ${event.type}');
     });
   } catch (e) {
     print('Collection error: $e');
   }
   ```

2. **Check WebSocket is Enabled**

   ```dart
   // Real-time requires WebSocket support
   // Most BaaS platforms enable this by default
   ```

3. **Use QueryBuilder with watchCollection**

   ```dart
   // ❌ Wrong - passing QueryBuilder directly
   await db.watchCollection('books', callback,
     queryBuilder: QueryBuilder().limit(100),
   );

   // ✅ Correct - use filters parameter
   await db.watchCollection('books', callback,
     filters: {'status': 'published'},
   );
   ```

---

### Issue: "Real-time updates stopped"

**Solutions:**

1. **Reconnect on Disconnect**

   ```dart
   class RobustWatcher {
     Future<void> watch(String collection) async {
       try {
         await db.watchCollection(collection, (event) {
           // Handle event
         });
       } catch (e) {
         print('Watch failed: $e');
         // Reconnect after delay
         await Future.delayed(Duration(seconds: 5));
         await watch(collection);  // Retry
       }
     }
   }
   ```

2. **Check Network State**
   ```dart
   Future<void> watchWithNetworkCheck(String collection) async {
     if (await hasInternet()) {
       await db.watchCollection(collection, (event) {
         // Handle event
       });
     } else {
       print('No internet connection');
     }
   }
   ```

---

## Debugging Tips

### Enable Debug Logging

```dart
import 'package:dio/dio.dart';

final dio = Dio();
dio.interceptors.add(
  LogInterceptor(
    requestBody: true,
    responseBody: true,
    requestHeader: true,
    responseHeader: true,
  ),
);
```

### Print Document Details

```dart
final doc = await db.getDocument("books", "doc-id");
print('ID: ${doc.id}');
print('Collection: ${doc.collection}');
print('Data: ${doc.data}');
print('Data type: ${doc.data.runtimeType}');
print('Created: ${doc.createdAt}');
print('Updated: ${doc.updatedAt}');
```

### Check Query String

```dart
final query = QueryBuilder()
  .where('status', 'published')
  .whereGreaterThan('price', 20);

print('Query: ${query.build()}');
```

---

## Getting Help

### Resources

1. **Documentation**

   - Check [Getting Started](00-GETTING_STARTED.md)
   - Review [Querying Data](01-QUERYING_DATA.md)
   - See [Examples](07-EXAMPLES_AND_PATTERNS.md)

2. **Community**

   - GitHub Issues: [coco-base-flutter/issues](https://github.com)
   - Stack Overflow: Tag your question with `cocobase` and `flutter`

3. **Contact Support**
   - Email: support@cocobase.buzz
   - Dashboard: Help button in top-right

### Reporting Issues

When reporting a bug, include:

```dart
// 1. SDK version
print('CocoBase SDK version: 1.0.0');

// 2. Dart version
// dart --version

// 3. Minimal reproduction
final db = Cocobase(CocobaseConfig(apiKey: 'test-key'));
final books = await db.listDocuments("books");

// 4. Full error message and stack trace
// (Copy from console)

// 5. Expected vs actual behavior
```

---

**← [Examples & Patterns](07-EXAMPLES_AND_PATTERNS.md) | [API Reference →](09-API_REFERENCE.md)**
