# CocoBase Flutter SDK Documentation

Complete, comprehensive documentation for the CocoBase Flutter SDK.

## 📚 Documentation Index

### Getting Started

- **[00 - Getting Started](00-GETTING_STARTED.md)** - Installation, setup, and first request
  - Installation guide
  - Basic setup
  - First API request
  - Key concepts

### Core Features

- **[01 - Querying Data](01-QUERYING_DATA.md)** - Master filtering, sorting, and pagination

  - Simple filters (Map approach)
  - QueryBuilder API
  - All 12 operators
  - OR queries (3 types)
  - Sorting and pagination
  - Field selection
  - Relationship population

- **[02 - Type Conversion](02-TYPE_CONVERSION.md)** - Type-safe documents and models

  - Why type safety matters
  - Creating models with fromJson()
  - Registration methods
  - Using converted documents
  - Advanced patterns
  - Migration guide

- **[03 - Collections](03-COLLECTIONS.md)** - Create and manage collections

  - What is a collection?
  - Creating collections with schema
  - Reading collection metadata
  - Updating and deleting collections
  - Collection patterns
  - Best practices

- **[04 - Authentication](04-AUTHENTICATION.md)** - User registration and login

  - User registration
  - User login
  - Authentication state
  - User profile management
  - Logout
  - Security best practices

- **[05 - Real-Time Data](05-REAL_TIME_DATA.md)** - Watch collections for live updates
  - Real-time overview
  - Watching collections
  - Event types
  - Building reactive UI
  - Real-time patterns
  - Error handling and reconnection

### Advanced Topics

- **[06 - Advanced Features](06-ADVANCED_FEATURES.md)** - Batch operations and aggregations
  - Batch create/update/delete
  - Sum, avg, min, max aggregations
  - Group by field
  - Export and backup
  - Transactions
  - Performance optimization
  - Caching and lazy loading

### Practical Guides

- **[07 - Examples & Patterns](07-EXAMPLES_AND_PATTERNS.md)** - Real-world code examples
  - Complete Todo app
  - E-commerce app
  - Social media feed
  - Notes app
  - Messaging app

### Reference

- **[08 - Common Issues](08-COMMON_ISSUES.md)** - Troubleshooting and debugging

  - Authentication issues
  - Query problems
  - Type conversion errors
  - Performance issues
  - Network problems
  - Real-time issues
  - Debugging tips

- **[09 - API Reference](09-API_REFERENCE.md)** - Complete API documentation
  - Cocobase class
  - QueryBuilder class
  - Document class
  - Response models
  - Error handling
  - Type reference

---

## 🚀 Quick Start

### 1. Install

```yaml
dependencies:
  coco_base_flutter: ^1.0.0
  dio: ^5.2.1
  web_socket_channel: ^2.4.0
  shared_preferences: ^2.0.18
```

### 2. Initialize

```dart
final config = CocobaseConfig(apiKey: 'YOUR_API_KEY');
final db = Cocobase(config);
```

### 3. Use

```dart
// Define your model
class Book {
  final String title;
  final String author;

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'] as String,
      author: json['author'] as String,
    );
  }
}

// Register converter (once)
CocobaseConverters.register<Book>(Book.fromJson);

// Use everywhere - no converter needed!
final books = await db.listDocuments<Book>("books");
print(books[0].data.title);  // Fully typed!
```

---

## 📖 Learning Paths

### Path 1: Beginner → Intermediate

1. [Getting Started](00-GETTING_STARTED.md) - Learn basics
2. [Querying Data](01-QUERYING_DATA.md) - Master queries
3. [Type Conversion](02-TYPE_CONVERSION.md) - Type safety
4. [Examples & Patterns](07-EXAMPLES_AND_PATTERNS.md) - Real code

### Path 2: Building Production Apps

1. [Collections](03-COLLECTIONS.md) - Schema design
2. [Authentication](04-AUTHENTICATION.md) - User management
3. [Advanced Features](06-ADVANCED_FEATURES.md) - Optimization
4. [Common Issues](08-COMMON_ISSUES.md) - Troubleshooting

### Path 3: Real-Time Features

1. [Real-Time Data](05-REAL_TIME_DATA.md) - Live updates
2. [Examples & Patterns](07-EXAMPLES_AND_PATTERNS.md) - Social/Chat apps
3. [Advanced Features](06-ADVANCED_FEATURES.md) - Performance

---

## 🎯 Common Tasks

### List Documents

```dart
// All documents
final docs = await db.listDocuments("books");

// With filters
final docs = await db.listDocuments<Book>(
  "books",
  filters: {'status': 'published', 'price__lt': 50},
  converter: Book.fromJson,
);

// Complex query
final docs = await db.listDocuments<Book>(
  "books",
  queryBuilder: QueryBuilder()
    .where('status', 'published')
    .whereGreaterThan('rating', 4)
    .orderByDesc('createdAt')
    .limit(20),
  converter: Book.fromJson,
);
```

→ See [Querying Data](01-QUERYING_DATA.md)

### Create Document

```dart
final book = Book(title: 'Flutter Guide', author: 'John');
final created = await db.createDocument<Book>("books", book);
```

→ See [Getting Started](00-GETTING_STARTED.md)

### Update Document

```dart
await db.updateDocument("books", "doc-id", {
  'status': 'archived',
  'price': 29.99,
});
```

→ See [API Reference](09-API_REFERENCE.md)

### Type-Safe Documents

```dart
CocobaseConverters.register<Book>(Book.fromJson);
final books = await db.listDocuments<Book>("books");
print(books[0].data.title);  // Full IDE support!
```

→ See [Type Conversion](02-TYPE_CONVERSION.md)

### Watch for Changes

```dart
await db.watchCollection<Book>(
  "books",
  (event) {
    print('Event: ${event.type}');
    if (event.type == 'create') {
      // New book created!
    }
  },
  converter: Book.fromJson,
);
```

→ See [Real-Time Data](05-REAL_TIME_DATA.md)

### User Authentication

```dart
// Register
await db.register(email: 'user@example.com', password: 'secure');

// Login
await db.login(email: 'user@example.com', password: 'secure');

// Get current user
final user = await db.getCurrentUser();
```

→ See [Authentication](04-AUTHENTICATION.md)

### Batch Operations

```dart
final result = await db.batchCreateDocuments<Book>(
  "books",
  [
    {'title': 'Book 1', 'author': 'Author 1'},
    {'title': 'Book 2', 'author': 'Author 2'},
  ],
);
print('Created: ${result.created}');
```

→ See [Advanced Features](06-ADVANCED_FEATURES.md)

### Aggregations

```dart
final totalPrice = await db.aggregateDocuments(
  "orders",
  field: 'total',
  operation: 'sum',
  filters: {'status': 'completed'},
);
print('Total revenue: \$${totalPrice.value}');
```

→ See [Advanced Features](06-ADVANCED_FEATURES.md)

---

## 🔍 Feature Comparison

| Feature         | Basic               | Advanced                  |
| --------------- | ------------------- | ------------------------- |
| List documents  | ✅                  | ✅                        |
| Filters         | Map or QueryBuilder | QueryBuilder              |
| Type conversion | Explicit converter  | Registered converters     |
| Sorting         | Simple              | ✅                        |
| Pagination      | limit/offset        | ✅                        |
| Relationships   | populate()          | ✅                        |
| OR queries      | Simple [or]         | Named groups, multi-field |
| Real-time       | watchCollection     | ✅                        |
| Batch ops       | -                   | ✅                        |
| Aggregations    | -                   | ✅                        |
| Group by        | -                   | ✅                        |

---

## 📊 Operators

### Comparison

- `==` (equality) - `where(field, value)`
- `>` (greater than) - `field__gt`
- `>=` (greater or equal) - `field__gte`
- `<` (less than) - `field__lt`
- `<=` (less or equal) - `field__lte`
- `!=` (not equal) - `field__ne`

### String

- Contains - `field__contains`
- Starts with - `field__startswith`
- Ends with - `field__endswith`

### Array

- In list - `field__in`
- Not in list - `field__notin`

### Special

- Is null - `field__isnull`

→ See [Querying Data](01-QUERYING_DATA.md) for details

---

## 🛠️ Tips & Best Practices

### Query Tips

1. **Always filter** - Don't fetch all documents
2. **Paginate large results** - Use limit/offset
3. **Use indexes** - Define in collection schema
4. **Select specific fields** - Reduce bandwidth

### Type Safety Tips

1. **Register converters once** - In app initialization
2. **Use factories** - Define `fromJson()` method
3. **Handle null values** - Use nullable types
4. **Type cast carefully** - Use `as Type?` for safety

### Performance Tips

1. **Cache data** - Avoid repeated requests
2. **Lazy load** - Load on demand
3. **Batch operations** - For multiple creates
4. **Close connections** - Dispose WebSockets

### Authentication Tips

1. **Store tokens securely** - SDK does this
2. **Check session on startup** - Restore login
3. **Handle 401 errors** - Re-login when needed
4. **Use strong passwords** - Enforce requirements

---

## 🚨 Common Mistakes

1. **Not registering converters** - Register in main()
2. **Forgetting to filter** - Always use limit/offset
3. **Type mismatches** - Check fromJson() types
4. **Not closing connections** - Call dispose()
5. **Hardcoding API keys** - Use environment variables

→ See [Common Issues](08-COMMON_ISSUES.md) for solutions

---

## 📞 Support

### Need Help?

- 📖 Check the relevant documentation page
- 🔍 Search [Common Issues](08-COMMON_ISSUES.md)
- 💬 Check [API Reference](09-API_REFERENCE.md)
- 📝 Review [Examples](07-EXAMPLES_AND_PATTERNS.md)

### Found a Bug?

- Check [Common Issues](08-COMMON_ISSUES.md)
- Check GitHub Issues
- Contact support@cocobase.buzz

---

## 📋 Documentation Stats

- **Total Pages:** 10
- **Code Examples:** 200+
- **Topics Covered:** 30+
- **Real-world Examples:** 5 complete apps

---

## 🔗 Quick Navigation

**First Time?** → Start with [Getting Started](00-GETTING_STARTED.md)

**Want to Query?** → See [Querying Data](01-QUERYING_DATA.md)

**Need Types?** → Go to [Type Conversion](02-TYPE_CONVERSION.md)

**Building Production?** → Try [Advanced Features](06-ADVANCED_FEATURES.md)

**Stuck?** → Check [Common Issues](08-COMMON_ISSUES.md)

**Need Details?** → See [API Reference](09-API_REFERENCE.md)

---

## 📝 Version History

### v1.0.0 (Current)

- ✅ Complete Collections API
- ✅ QueryBuilder with 12 operators
- ✅ Three types of OR queries
- ✅ Type-safe documents
- ✅ Converter registration system
- ✅ Simple filter map support
- ✅ Batch operations
- ✅ Aggregations and grouping
- ✅ Real-time WebSocket support
- ✅ Authentication system

---

**Last Updated:** January 2026
**Language:** Dart 3.8.1+
**Framework:** Flutter

Happy Coding! 🎉
