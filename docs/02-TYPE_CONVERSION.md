# Type Conversion & Type Safety

Learn how to work with strongly-typed documents and eliminate null safety issues.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Why Type Safety?](#why-type-safety)
3. [Creating Models](#creating-models)
4. [Registration Methods](#registration-methods)
5. [Using Converted Documents](#using-converted-documents)
6. [Advanced Patterns](#advanced-patterns)

---

## Quick Start

### Define Your Model

```dart
class Book {
  final String title;
  final String author;
  final double price;

  Book({
    required this.title,
    required this.author,
    required this.price,
  });

  // Create from JSON (required for type conversion)
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'] as String,
      author: json['author'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  // Convert back to JSON (optional but helpful)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'price': price,
    };
  }
}
```

### Register Once

```dart
void main() {
  final config = CocobaseConfig(apiKey: "YOUR_KEY");
  final db = Cocobase(config);

  // Register your converter one time
  CocobaseConverters.register<Book>(Book.fromJson);
}
```

### Use Everywhere

```dart
// No converter parameter needed!
final books = await db.listDocuments<Book>("books");
print(books[0].data.title);  // Fully typed!
```

---

## Why Type Safety?

### Without Type Safety (Dynamic)

```dart
final docs = await db.listDocuments("books");  // Returns dynamic data

// ❌ No autocomplete - what fields exist?
print(docs[0].data['title']);  // Might be null, no type checking

// ❌ Easy to make mistakes
print(docs[0].data['titulo']);  // Typo - no error at compile time

// ❌ Manual type casting required
final price = (docs[0].data['price'] as double) * 2;
```

### With Type Safety (Converted)

```dart
final books = await db.listDocuments<Book>("books");

// ✅ Full autocomplete - IDE knows all fields
print(books[0].data.title);  // Perfect!

// ✅ Compile-time type checking
// books[0].data.titulo;  // ❌ ERROR: no property 'titulo'

// ✅ No casting needed
final price = books[0].data.price * 2;  // Dart knows it's double
```

---

## Creating Models

### Basic Model

```dart
class User {
  final String id;
  final String name;
  final String email;
  final int age;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      age: json['age'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
    };
  }
}
```

### Model with Optional Fields

```dart
class Product {
  final String name;
  final double price;
  final String? description;  // Optional
  final List<String>? tags;   // Optional list

  Product({
    required this.name,
    required this.price,
    this.description,
    this.tags,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'tags': tags,
    };
  }
}
```

### Model with Complex Types

```dart
class Order {
  final String id;
  final List<Item> items;
  final Address shippingAddress;
  final double total;

  Order({
    required this.id,
    required this.items,
    required this.shippingAddress,
    required this.total,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => Item.fromJson(item as Map<String, dynamic>))
          .toList(),
      shippingAddress: Address.fromJson(
        json['shippingAddress'] as Map<String, dynamic>
      ),
      total: (json['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => item.toJson()).toList(),
      'shippingAddress': shippingAddress.toJson(),
      'total': total,
    };
  }
}

class Item {
  final String productId;
  final int quantity;
  final double price;

  Item({
    required this.productId,
    required this.quantity,
    required this.price,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      productId: json['productId'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'price': price,
    };
  }
}

class Address {
  final String street;
  final String city;
  final String zipCode;

  Address({
    required this.street,
    required this.city,
    required this.zipCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] as String,
      city: json['city'] as String,
      zipCode: json['zipCode'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'zipCode': zipCode,
    };
  }
}
```

---

## Registration Methods

### Method 1: Global Registration (Recommended)

Register converters once in your app initialization:

```dart
void main() async {
  final config = CocobaseConfig(apiKey: "YOUR_KEY");
  final db = Cocobase(config);

  // Register all your converters here
  CocobaseConverters.register<Book>(Book.fromJson);
  CocobaseConverters.register<User>(User.fromJson);
  CocobaseConverters.register<Product>(Product.fromJson);
  CocobaseConverters.register<Order>(Order.fromJson);

  runApp(const MyApp());
}
```

**Advantages:**

- ✅ Register once, use everywhere
- ✅ Cleaner API calls
- ✅ Best for production code

### Method 2: Explicit Converter (Alternative)

Pass converter directly to method:

```dart
// Use when you need one-off conversions
final books = await db.listDocuments<Book>(
  "books",
  converter: Book.fromJson,  // Explicit parameter
);
```

**Advantages:**

- ✅ No global state
- ✅ Good for testing
- ✅ Works without registration

### Method 3: Inline Lambda (Quick & Dirty)

```dart
final books = await db.listDocuments<Book>(
  "books",
  converter: (json) => Book.fromJson(json),
);
```

**Only for:** Experimentation, one-off queries

### Method 4: Check Before Registering

```dart
if (!CocobaseConverters.hasConverter<Book>()) {
  CocobaseConverters.register<Book>(Book.fromJson);
}

// Safe to use
final books = await db.listDocuments<Book>("books");
```

---

## Using Converted Documents

### List of Typed Documents

```dart
final books = await db.listDocuments<Book>("books");

// books is List<Document<Book>>
// Each doc.data is a Book instance

for (var doc in books) {
  print('ID: ${doc.id}');
  print('Title: ${doc.data.title}');  // Type-safe!
  print('Price: \$${doc.data.price}');
  print('Created: ${doc.createdAt}');
}
```

### Single Typed Document

```dart
final doc = await db.getDocument<Book>("books", "doc-id");

// doc is Document<Book>
// doc.data is a Book instance

print(doc.data.title);
print(doc.data.author);
```

### Accessing Document Metadata

```dart
final doc = await db.getDocument<Book>("books", "doc-id");

// You get both data AND metadata
print(doc.id);          // Document ID
print(doc.collection);  // Collection name
print(doc.data);        // Your typed data (Book)
print(doc.createdAt);   // Creation timestamp
print(doc.updatedAt);   // Last update timestamp
```

---

## Advanced Patterns

### Pattern 1: Type-Safe List Processing

```dart
final books = await db.listDocuments<Book>("books");

// Process with full type safety
final total = books
    .where((doc) => doc.data.price > 20)
    .map((doc) => doc.data.price)
    .fold(0.0, (sum, price) => sum + price);

print('Total price: \$$total');
```

### Pattern 2: Type Conversion in Batch Operations

```dart
// Create multiple typed documents
final newBooks = [
  Book(title: 'Book 1', author: 'Author 1', price: 19.99),
  Book(title: 'Book 2', author: 'Author 2', price: 24.99),
];

final results = await db.batchCreateDocuments<Book>(
  "books",
  newBooks,
);

for (var result in results.documents) {
  print('Created: ${result.data.title} (${result.id})');
}
```

### Pattern 3: Safe Type Conversion with Error Handling

```dart
extension TypeSafeConversion on Document {
  T? convertTo<T>(T Function(Map<String, dynamic>) converter) {
    try {
      return converter(data as Map<String, dynamic>);
    } catch (e) {
      print('Conversion error: $e');
      return null;
    }
  }
}

// Use it
final doc = await db.getDocument("books", "doc-id");
final book = doc.convertTo<Book>(Book.fromJson);
if (book != null) {
  print('Converted: ${book.title}');
} else {
  print('Conversion failed');
}
```

### Pattern 4: Polymorphic Types

```dart
abstract class Content {
  String get title;
  factory Content.fromJson(Map<String, dynamic> json) {
    final type = json['contentType'] as String;
    switch (type) {
      case 'article':
        return Article.fromJson(json);
      case 'video':
        return Video.fromJson(json);
      case 'podcast':
        return Podcast.fromJson(json);
      default:
        throw ArgumentError('Unknown content type: $type');
    }
  }
}

class Article implements Content {
  final String title;
  final String body;

  Article({required this.title, required this.body});

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }
}

// Similar for Video, Podcast...

// Use polymorphic conversion
CocobaseConverters.register<Content>(Content.fromJson);

final content = await db.listDocuments<Content>("content");
for (var doc in content) {
  if (doc.data is Article) {
    print('Article: ${(doc.data as Article).title}');
  } else if (doc.data is Video) {
    print('Video: ${(doc.data as Video).title}');
  }
}
```

### Pattern 5: Sealed Classes (Dart 3.0+)

```dart
sealed class ApiResponse {
  const ApiResponse();
}

class SuccessResponse<T> extends ApiResponse {
  final T data;
  const SuccessResponse(this.data);
}

class ErrorResponse extends ApiResponse {
  final String message;
  const ErrorResponse(this.message);
}

// Use with type safety
Future<ApiResponse> getBooks() async {
  try {
    final books = await db.listDocuments<Book>("books");
    return SuccessResponse(books);
  } catch (e) {
    return ErrorResponse(e.toString());
  }
}

// Pattern match (Dart 3.0+)
final response = await getBooks();
switch (response) {
  case SuccessResponse<List<Document<Book>>>(:final data):
    print('Got ${data.length} books');
  case ErrorResponse(:final message):
    print('Error: $message');
}
```

---

## Migration Guide

### From Untyped to Typed

```dart
// Before: Untyped, no autocomplete
final docs = await db.listDocuments("books");
final title = docs[0].data['title'];

// After: Fully typed, with autocomplete
CocobaseConverters.register<Book>(Book.fromJson);
final books = await db.listDocuments<Book>("books");
final title = books[0].data.title;
```

---

## Troubleshooting

### Issue: "type '\_InternalLinkedHashMap<String, dynamic>' is not a subtype"

**Cause:** Field type mismatch in `fromJson()`

```dart
// ❌ Wrong - expects String but API returns int
final age = json['age'] as String;

// ✅ Correct
final age = json['age'] as int;
```

### Issue: "NoSuchMethodError: The method 'fromJson' was called on null"

**Cause:** Converter not registered

```dart
// ✅ Register first
CocobaseConverters.register<Book>(Book.fromJson);

// Now it works
final books = await db.listDocuments<Book>("books");
```

### Issue: "The null object does not have the property"

**Cause:** Optional field treated as required

```dart
// ✅ Use nullable type
class Book {
  final String? subtitle;  // Optional field

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      subtitle: json['subtitle'] as String?,  // Can be null
    );
  }
}
```

---

## Best Practices

1. **Always define `fromJson()` factory** - Required for type conversion
2. **Type cast in `fromJson()`** - Use `as Type` for safety
3. **Handle optional fields** - Use nullable types `String?`
4. **Register in `main()`** - Register converters once at app start
5. **Use `toJson()` for updates** - Convert back when creating/updating
6. **Test your converters** - Verify JSON parsing works as expected

---

**← [Querying Data](01-QUERYING_DATA.md) | [Collections →](03-COLLECTIONS.md)**
