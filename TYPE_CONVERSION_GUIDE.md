# Type Conversion Guide for CocoBase Flutter SDK

## Understanding Type Conversion

When you fetch documents from CocoBase, you can convert the data to strongly-typed Dart classes for better type safety and IDE support.

## Response Structure

The API returns documents with this structure:

```json
{
  "id": "32bce252-9e30-4ec1-9d6b-3dc21ee77454",
  "collection": {
    "name": "books",
    "id": "5d24d64d-dc66-4238-97f7-1398cb19378b",
    "webhook_url": null,
    "permissions": {
      "read": [],
      "create": [],
      "delete": [],
      "update": ["admin"]
    },
    "created_at": "2025-11-15T15:56:58.218531"
  },
  "data": {
    "title": "No longer at ease",
    "content": "content of no longer at ease"
  },
  "created_at": "2025-12-08T20:59:50.861894",
  "updated_at": "2025-12-08T20:59:50.861894"
}
```

## Method 1: Using Map<String, dynamic> (Most Flexible)

```dart
final books = await db.listDocuments<Map<String, dynamic>>("books");

for (var doc in books) {
  print('Title: ${doc.data['title']}');
  print('Content: ${doc.data['content']}');
}
```

**Pros:**

- No extra setup needed
- Flexible - works with any data structure
- Good for dynamic data

**Cons:**

- No type safety
- IDE won't auto-complete field names
- Easy to make typos

## Method 2: Custom Classes (Type-Safe)

### Step 1: Create Your Data Class

```dart
class Book {
  final String title;
  final String content;
  final List<dynamic>? favUsers;

  Book({
    required this.title,
    required this.content,
    this.favUsers,
  });

  /// Factory constructor to create from JSON
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'] as String,
      content: json['content'] as String,
      favUsers: json['fav_users'] as List<dynamic>?,
    );
  }

  /// Convert back to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'fav_users': favUsers,
    };
  }

  @override
  String toString() {
    return 'Book(title: $title, content: $content, favUsers: $favUsers)';
  }
}
```

### Step 2: Convert Documents

**Option A: Manual Conversion**

```dart
final booksRaw = await db.listDocuments<Map<String, dynamic>>("books");

final bookDocs = booksRaw.map((doc) {
  return Document<Book>(
    id: doc.id,
    collection: doc.collection,
    data: Book.fromJson(doc.data),
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt,
  );
}).toList();

// Now use with type safety
for (var doc in bookDocs) {
  print('Title: ${doc.data.title}');  // Type-safe!
  print('Content: ${doc.data.content}');
}
```

**Option B: Using Helper Function (Cleaner)**

```dart
// Define once, use everywhere
List<Document<T>> convertDocuments<T>(
  List<Document<Map<String, dynamic>>> documents,
  T Function(Map<String, dynamic>) converter,
) {
  return documents.map((doc) {
    return Document<T>(
      id: doc.id,
      collection: doc.collection,
      data: converter(doc.data),
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    );
  }).toList();
}

// Use it
final bookDocs = convertDocuments(
  await db.listDocuments<Map<String, dynamic>>("books"),
  Book.fromJson,
);
```

## Comparison

| Feature           | Map<String, dynamic> | Custom Class    |
| ----------------- | -------------------- | --------------- |
| Type Safety       | ❌ No                | ✅ Yes          |
| IDE Auto-complete | ❌ No                | ✅ Yes          |
| Null Safety       | ❌ No                | ✅ Yes          |
| Flexibility       | ✅ High              | ❌ Fixed        |
| Setup Required    | ❌ None              | ✅ More         |
| Performance       | ✅ Faster            | ❌ Slower       |
| Error Detection   | ❌ Runtime           | ✅ Compile-time |

## Best Practices

### 1. **Always Create fromJson for API Responses**

```dart
class User {
  final String name;
  final String email;

  User({required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}
```

### 2. **Handle Nullable Fields**

```dart
factory User.fromJson(Map<String, dynamic> json) {
  return User(
    name: json['name'] as String,
    email: json['email'] as String?,  // Nullable
    avatar: json['avatar'],  // Can be null
  );
}
```

### 3. **Use Consistent Naming**

- JSON keys: snake_case (`fav_users`, `created_at`)
- Dart properties: camelCase (`favUsers`, `createdAt`)

```dart
factory Book.fromJson(Map<String, dynamic> json) {
  return Book(
    favUsers: json['fav_users'],  // Convert naming style
  );
}
```

### 4. **Create a Generic Converter Extension (Advanced)**

```dart
extension DocumentListConverter<T> on Future<List<Document<Map<String, dynamic>>>> {
  Future<List<Document<T>>> convert(T Function(Map<String, dynamic>) converter) async {
    final docs = await this;
    return docs.map((doc) {
      return Document<T>(
        id: doc.id,
        collection: doc.collection,
        data: converter(doc.data),
        createdAt: doc.createdAt,
        updatedAt: doc.updatedAt,
      );
    }).toList();
  }
}

// Use it like:
final bookDocs = await db
    .listDocuments<Map<String, dynamic>>("books")
    .convert(Book.fromJson);
```

## Common Patterns

### Pattern 1: Simple CRUD with Type Safety

```dart
class BookRepository {
  final Cocobase db;

  BookRepository(this.db);

  Future<List<Document<Book>>> getBooks() async {
    final raw = await db.listDocuments<Map<String, dynamic>>("books");
    return convertDocuments(raw, Book.fromJson);
  }

  Future<Document<Book>> getBook(String id) async {
    final doc = await db.getDocument<Map<String, dynamic>>("books", id);
    return Document<Book>(
      id: doc.id,
      collection: doc.collection,
      data: Book.fromJson(doc.data),
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    );
  }

  Future<Document<Book>> createBook(Book book) async {
    return await db.createDocument("books", book.toJson());
  }
}
```

### Pattern 2: Complex Nested Data

```dart
class Post {
  final String title;
  final String content;
  final Author author;
  final List<Comment> comments;

  Post({
    required this.title,
    required this.content,
    required this.author,
    required this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      title: json['title'],
      content: json['content'],
      author: Author.fromJson(json['author']),
      comments: (json['comments'] as List)
          .map((c) => Comment.fromJson(c))
          .toList(),
    );
  }
}
```

### Pattern 3: Populate with Type Safety

```dart
final postsRaw = await db.listDocuments<Map<String, dynamic>>(
  "posts",
  queryBuilder: QueryBuilder()
      .populate('author')
      .populate('comments'),
);

final posts = convertDocuments(postsRaw, Post.fromJson);

for (var doc in posts) {
  print('Title: ${doc.data.title}');
  print('Author: ${doc.data.author.name}');
  print('Comments: ${doc.data.comments.length}');
}
```

## When to Use What

**Use `Map<String, dynamic>`:**

- Exploring API responses
- Dynamic/flexible schemas
- One-off queries
- Prototyping

**Use Custom Classes:**

- Production code
- Strongly-typed repositories
- Complex domain models
- When you need IDE support
- Team projects where consistency matters

## Summary

Type conversion in CocoBase SDK:

1. ✅ Always fetch as `List<Document<Map<String, dynamic>>>`
2. ✅ Create `fromJson()` factory constructors
3. ✅ Use helper function to convert documents
4. ✅ Access data with dot notation: `doc.data.fieldName`
5. ✅ Get full type safety and IDE auto-complete

See `/test/coco_base_flutter_test.dart` for working examples!
