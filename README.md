# Cocobase Dart Client

A powerful and type-safe Dart client for Cocobase Backend-as-a-Service (BaaS). This package provides seamless integration with Cocobase's document database, authentication, and real-time features.

## Features

- 🚀 **Full CRUD Operations** - Create, read, update, and delete documents
- 🔐 **Authentication** - User registration, login, and profile management
- ⚡ **Real-time Updates** - WebSocket connections for live data synchronization
- 🎯 **Type Safe** - Full generic type support with Dart's type system
- 📱 **Cross Platform** - Works on Flutter mobile, web, and desktop
- 🛡️ **Error Handling** - Comprehensive error messages with helpful suggestions
- 💾 **Local Storage** - Automatic token and user data persistence

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  cocobase_dart: ^1.0.0
  dio: ^5.3.2
  web_socket_channel: ^2.4.0
  shared_preferences: ^2.0.18
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Initialize Cocobase

```dart
import 'package:cocobase_dart/cocobase.dart';

void main() async {
  // Initialize with your API key
  final cocobase = Cocobase(CocobaseConfig(
    apiKey: 'your-api-key-here',
  ));

  // Initialize authentication (loads saved tokens)
  await cocobase.initAuth();
}
```

### 2. Document Operations

```dart
// Define your data model
class User {
  final String name;
  final String email;
  final int age;

  User({required this.name, required this.email, required this.age});

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'age': age,
  };
}

// Create a document
final user = User(name: 'John Doe', email: 'john@example.com', age: 30);
final doc = await cocobase.createDocument('users', user.toJson());
print('Created user with ID: ${doc.id}');

// Get a document
final userDoc = await cocobase.getDocument<Map<String, dynamic>>('users', doc.id);
print('User name: ${userDoc.data['name']}');

// Update a document
await cocobase.updateDocument('users', doc.id, {'age': 31});

// List documents with query
final query = Query(
  where: {'age': 31},
  orderBy: 'created_at',
  limit: 10,
);
final users = await cocobase.listDocuments<Map<String, dynamic>>('users', query: query);

// Delete a document
await cocobase.deleteDocument('users', doc.id);
```

### 3. Authentication

```dart
// Register a new user
await cocobase.register(
  'user@example.com',
  'securePassword123',
  data: {'name': 'New User', 'role': 'member'},
);

// Login
await cocobase.login('user@example.com', 'securePassword123');

// Check authentication status
if (cocobase.isAuthenticated()) {
  print('User is logged in: ${cocobase.user?.email}');
}

// Update user profile
await cocobase.updateUser(
  data: {'name': 'Updated Name'},
  email: 'newemail@example.com',
);

// Logout
cocobase.logout();
```

### 4. Real-time Updates

```dart
// Watch for changes in a collection
final connection = cocobase.watchCollection(
  'messages',
  (event) {
    print('Event: ${event['event']}');
    print('Data: ${event['data']}');
  },
  connectionName: 'messages-watcher',
  onOpen: () => print('Connected to messages'),
  onError: () => print('Connection error'),
);

// Close the connection when done
connection.close();
```

## API Reference

### Cocobase Class

#### Constructor

```dart
Cocobase(CocobaseConfig config)
```

#### Document Methods

- `Future<Document<T>> getDocument<T>(String collection, String docId)`
- `Future<Document<T>> createDocument<T>(String collection, T data)`
- `Future<Document<T>> updateDocument<T>(String collection, String docId, Map<String, dynamic> data)`
- `Future<Map<String, bool>> deleteDocument(String collection, String docId)`
- `Future<List<Document<T>>> listDocuments<T>(String collection, {Query? query})`

#### Authentication Methods

- `Future<void> initAuth()`
- `Future<void> login(String email, String password)`
- `Future<void> register(String email, String password, {Map<String, dynamic>? data})`
- `void logout()`
- `bool isAuthenticated()`
- `Future<AppUser> getCurrentUser()`
- `Future<AppUser> updateUser({Map<String, dynamic>? data, String? email, String? password})`

#### Real-time Methods

- `Connection watchCollection(String collection, Function(Map<String, dynamic>) callback, {String? connectionName, Function()? onOpen, Function()? onError})`
- `void closeConnection(Connection connection)`

### Data Models

#### Document<T>

```dart
class Document<T> {
  final String id;
  final String collection;
  final T data;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### AppUser

```dart
class AppUser {
  final String id;
  final String email;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### Query

```dart
class Query {
  final Map<String, dynamic>? where;
  final String? orderBy;
  final int? limit;
  final int? offset;
}
```

## Error Handling

The client provides detailed error information with helpful suggestions:

```dart
try {
  await cocobase.getDocument('users', 'nonexistent-id');
} catch (e) {
  print(e.toString()); // Contains status code, URL, method, and suggestions
}
```

Common error scenarios and suggestions:

- **401**: Check if your API key is valid and properly set
- **403**: Verify your access rights for the requested resource
- **404**: Verify the path and ID are correct
- **429**: You've exceeded the rate limit, wait before making more requests

## Advanced Usage

### Custom Types

```dart
class Product {
  final String name;
  final double price;
  final List<String> tags;

  Product({required this.name, required this.price, required this.tags});

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    name: json['name'],
    price: json['price'].toDouble(),
    tags: List<String>.from(json['tags']),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
    'tags': tags,
  };
}

// Use with type safety
final productDoc = await cocobase.createDocument('products', product.toJson());
final products = await cocobase.listDocuments<Map<String, dynamic>>('products');
```

### Complex Queries

```dart
final query = Query(
  where: {
    'status': 'active',
    'category': 'electronics',
    'price_lt': 1000, // Less than $1000
  },
  orderBy: 'created_at',
  limit: 50,
  offset: 0,
);

final results = await cocobase.listDocuments('products', query: query);
```

### Multiple Real-time Connections

```dart
// Watch multiple collections
final userConnection = cocobase.watchCollection('users', handleUserEvents);
final messageConnection = cocobase.watchCollection('messages', handleMessageEvents);

// Close specific connections
userConnection.close();
messageConnection.close();
```

## Testing

The package includes comprehensive tests. Run them with:

```bash
flutter test
```

### Test Dependencies

Add these to your `dev_dependencies`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.6
```

### Running Specific Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/cocobase_test.dart

# Run tests with coverage
flutter test --coverage
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📧 Email: support@cocobase.com
- 📚 Documentation: [docs.cocobase.com](https://docs.cocobase.com)
- 🐛 Issues: [GitHub Issues](https://github.com/your-repo/cocobase-dart/issues)
- 💬 Discord: [Join our community](https://discord.gg/cocobase)

## Changelog

### 1.0.0

- Initial release
- Full CRUD operations
- Authentication support
- Real-time WebSocket connections
- Comprehensive error handling
- Type-safe operations
