import "package:coco_base_flutter/coco_base_flutter.dart";

/// Book class for type-safe data conversion
class Book {
  final String title;
  final String content;
  final List<dynamic>? favUsers;

  Book({required this.title, required this.content, this.favUsers});

  /// Factory constructor to create a Book from JSON
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'] as String,
      content: json['content'] as String,
      favUsers: json['fav_users'] as List<dynamic>?,
    );
  }

  /// Convert Book to JSON
  Map<String, dynamic> toJson() {
    return {'title': title, 'content': content, 'fav_users': favUsers};
  }

  @override
  String toString() {
    return 'Book(title: $title, content: $content, favUsers: $favUsers)';
  }
}

void main() async {
  final config = CocobaseConfig(
    apiKey: "VTXjd5f7SRhfyqpKKenvSNCYzOSOaVBj75pYBQ8Z",
  );
  final db = Cocobase(config);

  // print('=== Test 1: Easiest Way (Recommended) ===');
  // // Just pass the converter function - that's it!
  // final books = await db.listDocuments<Book>("books", converter: Book.fromJson);

  // print('Count: ${books.length}');
  // for (var doc in books) {
  //   print('ID: ${doc.id}');
  //   print('Data: ${doc.data}');
  //   print('Title: ${doc.data.title}');
  //   print('Content: ${doc.data.content}');
  //   print('---');
  // }

  // print('\n=== Test 2: Get Single Document with Type ===');
  // if (books.isNotEmpty) {
  //   final firstBook = await db.getDocument<Book>(
  //     "books",
  //     books[0].id,
  //     converter: Book.fromJson,
  //   );
  //   print('Retrieved: ${firstBook.data.title}');
  // }

  print('\n=== Test 3: With QueryBuilder (Complex Query) ===');
  final filteredBooks = await db.listDocuments<Book>(
    "books",
    filters: {
      'limit':1
    },
    converter: Book.fromJson,
  );

  print('Filtered count: ${filteredBooks.length}');
  for (var doc in filteredBooks) {
    print('- ${doc.data.title}');
  }

  // print('\n=== Test 4: Without Converter (If You Want Dynamic) ===');
  // final dynamicBooks = await db.listDocuments("books");
  // print('First book (dynamic): ${dynamicBooks[0].data}');
}
