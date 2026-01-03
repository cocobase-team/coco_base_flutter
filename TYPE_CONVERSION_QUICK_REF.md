# Quick Reference: Type Conversion Examples

## The Three Ways to Handle Document Data

### 1. Raw Map (No Conversion Needed)

```dart
final books = await db.listDocuments<Map<String, dynamic>>("books");

for (var doc in books) {
  print(doc.data['title']);  // Dynamic access
}
```

### 2. Manual Conversion

```dart
final booksRaw = await db.listDocuments<Map<String, dynamic>>("books");

final books = booksRaw.map((doc) {
  return Document<Book>(
    id: doc.id,
    collection: doc.collection,
    data: Book.fromJson(doc.data),
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt,
  );
}).toList();

for (var doc in books) {
  print(doc.data.title);  // Type-safe access
}
```

### 3. Helper Function (Cleanest)

```dart
final books = convertDocuments(
  await db.listDocuments<Map<String, dynamic>>("books"),
  Book.fromJson,
);

for (var doc in books) {
  print(doc.data.title);  // Type-safe access
}
```

## Define Your Data Class Once

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

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'],
      content: json['content'],
      favUsers: json['fav_users'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'fav_users': favUsers,
    };
  }
}
```

## Use the Helper Function Everywhere

```dart
// Define once
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

// Use it for any type
final books = convertDocuments(
  await db.listDocuments<Map<String, dynamic>>("books"),
  Book.fromJson,
);

final users = convertDocuments(
  await db.listDocuments<Map<String, dynamic>>("users"),
  User.fromJson,
);

final posts = convertDocuments(
  await db.listDocuments<Map<String, dynamic>>("posts"),
  Post.fromJson,
);
```

## Real Test File Example

See `/test/coco_base_flutter_test.dart` for:

- ✅ Test 1: Raw Map<String, dynamic>
- ✅ Test 2: Manual conversion
- ✅ Test 3: Helper function (recommended)

Run it:

```bash
dart test/coco_base_flutter_test.dart
```
