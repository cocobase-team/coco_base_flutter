# Advanced Features

Master batch operations, aggregations, and complex data processing.

## Table of Contents

1. [Batch Operations](#batch-operations)
2. [Aggregations](#aggregations)
3. [Group By](#group-by)
4. [Export & Backup](#export--backup)
5. [Transactions](#transactions)
6. [Performance Optimization](#performance-optimization)

---

## Batch Operations

Handle multiple documents efficiently with batch operations.

### Batch Create

Create multiple documents in one request:

```dart
final newBooks = [
  {'title': 'Flutter Guide', 'author': 'John Doe', 'price': 29.99},
  {'title': 'Dart Essentials', 'author': 'Jane Smith', 'price': 39.99},
  {'title': 'Clean Code', 'author': 'Robert Martin', 'price': 49.99},
];

final result = await db.batchCreateDocuments<Book>(
  "books",
  newBooks,
);

print('Created ${result.created} books');
for (var book in result.documents) {
  print('- ${book.id}: ${book.data.title}');
}
```

### Batch Update

Update multiple documents at once:

```dart
final updates = [
  {'id': 'doc-1', 'price': 19.99},
  {'id': 'doc-2', 'price': 24.99},
  {'id': 'doc-3', 'price': 34.99},
];

final result = await db.batchUpdateDocuments(
  "books",
  updates,
);

print('Updated: ${result.updated}');
print('Failed: ${result.failed}');
```

### Batch Delete

Delete multiple documents:

```dart
final ids = ['doc-1', 'doc-2', 'doc-3'];

final result = await db.batchDeleteDocuments(
  "books",
  ids,
);

print('Deleted: ${result.deleted}');
print('Failed: ${result.failed}');
```

### Response Structure

```dart
class BatchCreateResponse<T> {
  final int created;
  final int failed;
  final List<Document<T>> documents;
}

class BatchUpdateResponse {
  final int updated;
  final int failed;
  final List<String> errorIds;
}

class BatchDeleteResponse {
  final int deleted;
  final int failed;
  final List<String> errorIds;
}
```

### Batch Operations Best Practices

```dart
// ✅ Good - Batch process large datasets
Future<void> importBooks(List<Map<String, dynamic>> bookData) async {
  const batchSize = 100;
  for (int i = 0; i < bookData.length; i += batchSize) {
    final batch = bookData.sublist(
      i,
      (i + batchSize).clamp(0, bookData.length),
    );

    try {
      final result = await db.batchCreateDocuments<Book>(
        "books",
        batch,
      );
      print('Created batch: ${result.created}');
    } catch (e) {
      print('Batch failed: $e');
    }
  }
}

// ✅ Good - Handle errors gracefully
Future<void> updateMultipleBooks(Map<String, dynamic> updates) async {
  final result = await db.batchUpdateDocuments(
    "books",
    updates.entries.map((e) => {'id': e.key, ...e.value}).toList(),
  );

  print('Success: ${result.updated}');
  if (result.failed > 0) {
    print('Failed to update: ${result.errorIds}');
  }
}
```

---

## Aggregations

Calculate statistics across your data.

### Sum

Calculate total of a field:

```dart
final result = await db.aggregateDocuments(
  "orders",
  field: 'total',
  operation: 'sum',
);

print('Total revenue: \$${result.value}');
```

### Average

Calculate average value:

```dart
final result = await db.aggregateDocuments(
  "products",
  field: 'price',
  operation: 'avg',
);

print('Average price: \$${result.value}');
```

### Minimum

Find minimum value:

```dart
final result = await db.aggregateDocuments(
  "books",
  field: 'price',
  operation: 'min',
);

print('Cheapest book: \$${result.value}');
```

### Maximum

Find maximum value:

```dart
final result = await db.aggregateDocuments(
  "books",
  field: 'price',
  operation: 'max',
);

print('Most expensive book: \$${result.value}');
```

### With Filters

Aggregate only matching documents:

```dart
// Total revenue from completed orders
final result = await db.aggregateDocuments(
  "orders",
  field: 'total',
  operation: 'sum',
  filters: {
    'status': 'completed',
    'createdAt__gte': '2024-01-01',
  },
);

print('2024 revenue: \$${result.value}');
```

### Response Structure

```dart
class AggregateResponse {
  final dynamic value;              // The calculated value
  final String operation;           // 'sum', 'avg', 'min', 'max'
  final int? count;                // Number of documents processed
}
```

### Aggregation Examples

```dart
// Example 1: Statistics Dashboard
Future<Map<String, dynamic>> getStorageStats() async {
  final totalSize = await db.aggregateDocuments(
    "files",
    field: 'size',
    operation: 'sum',
  );

  final avgSize = await db.aggregateDocuments(
    "files",
    field: 'size',
    operation: 'avg',
  );

  return {
    'totalSize': totalSize.value,
    'averageSize': avgSize.value,
    'totalDocuments': totalSize.count,
  };
}

// Example 2: Price Analysis
Future<Map<String, dynamic>> getPriceStats() async {
  final min = await db.aggregateDocuments(
    "products",
    field: 'price',
    operation: 'min',
    filters: {'active': true},
  );

  final max = await db.aggregateDocuments(
    "products",
    field: 'price',
    operation: 'max',
    filters: {'active': true},
  );

  final avg = await db.aggregateDocuments(
    "products",
    field: 'price',
    operation: 'avg',
    filters: {'active': true},
  );

  return {
    'minPrice': min.value,
    'maxPrice': max.value,
    'avgPrice': avg.value,
    'range': (max.value as num) - (min.value as num),
  };
}
```

---

## Group By

Group documents by field values and get counts.

### Basic Grouping

```dart
final result = await db.groupByField(
  "orders",
  field: 'status',
);

for (var group in result.groups) {
  print('${group.key}: ${group.count} orders');
}

// Output:
// pending: 15 orders
// processing: 8 orders
// completed: 102 orders
// cancelled: 3 orders
```

### Group With Filters

```dart
final result = await db.groupByField(
  "users",
  field: 'country',
  filters: {'active': true},
);

print('Active users by country:');
for (var group in result.groups) {
  print('${group.key}: ${group.count}');
}
```

### Response Structure

```dart
class GroupByResponse {
  final List<GroupByItem> groups;
  final int totalGroups;
  final int totalDocuments;
}

class GroupByItem {
  final dynamic key;              // Group key value
  final int count;                // Count in group
}
```

### Grouping Patterns

```dart
// Example 1: Dashboard Statistics
Future<Map<String, int>> getUserStatistics() async {
  final byRole = await db.groupByField(
    "users",
    field: 'role',
  );

  final stats = <String, int>{};
  for (var group in byRole.groups) {
    stats[group.key.toString()] = group.count;
  }

  return stats;
}

// Example 2: Category Analysis
Future<void> analyzeSales() async {
  final bySeason = await db.groupByField(
    "sales",
    field: 'season',
    filters: {'year': 2024},
  );

  print('Sales by season (2024):');
  for (var group in bySeason.groups) {
    print('${group.key}: ${group.count} transactions');
  }
}

// Example 3: Activity Report
Future<Map<String, dynamic>> getActivityReport() async {
  final byType = await db.groupByField(
    "activities",
    field: 'type',
  );

  final byStatus = await db.groupByField(
    "activities",
    field: 'status',
  );

  return {
    'byType': byType.groups.map((g) => {'type': g.key, 'count': g.count}).toList(),
    'byStatus': byStatus.groups.map((g) => {'status': g.key, 'count': g.count}).toList(),
  };
}
```

---

## Export & Backup

Export data for backup or analysis:

```dart
// Export entire collection
Future<void> exportCollection(String collectionName) async {
  final docs = await db.listDocuments(
    collectionName,
    filters: {'limit': 10000},
  );

  // Convert to CSV or JSON
  final jsonData = docs.map((doc) => doc.data).toList();

  // Save to file
  final json = jsonEncode(jsonData);
  // Write to file system or cloud storage
  print('Exported ${docs.length} documents');
}

// Export with filter
Future<void> exportFilteredData() async {
  final results = await db.listDocuments<Order>(
    "orders",
    filters: {
      'status': 'completed',
      'createdAt__gte': '2024-01-01',
    },
    converter: Order.fromJson,
  );

  // Process exports
  final csv = _convertToCSV(results);
  _saveToFile(csv, 'orders_2024.csv');
}
```

---

## Transactions

Handle multiple operations atomically:

```dart
// Note: Full transaction support depends on your BaaS backend
// This is a client-side simulation

class Transaction {
  final Cocobase db;
  final List<Function> operations = [];

  Transaction(this.db);

  void add(Function operation) {
    operations.add(operation);
  }

  Future<void> commit() async {
    for (var op in operations) {
      try {
        await op();
      } catch (e) {
        print('Transaction failed: $e');
        rethrow;
      }
    }
  }
}

// Use it
Future<void> transferFunds(
  String fromAccount,
  String toAccount,
  double amount,
) async {
  final tx = Transaction(db);

  tx.add(() => db.updateDocument(
    "accounts",
    fromAccount,
    {'balance': FieldValue.increment(-amount)},
  ));

  tx.add(() => db.updateDocument(
    "accounts",
    toAccount,
    {'balance': FieldValue.increment(amount)},
  ));

  tx.add(() => db.createDocument(
    "transactions",
    {
      'from': fromAccount,
      'to': toAccount,
      'amount': amount,
      'timestamp': DateTime.now(),
    },
  ));

  await tx.commit();
}
```

---

## Performance Optimization

### 1. Use Indexes

```dart
final collection = Collection(
  name: 'orders',
  fields: {
    'customerId': {'type': 'string', 'indexed': true},  // Index frequently queried
    'createdAt': {'type': 'datetime', 'indexed': true},
    'status': {'type': 'string', 'indexed': true},
    'notes': {'type': 'string'},  // Don't index large text
  },
);

await db.createCollection(collection);
```

### 2. Pagination

```dart
// ✅ Good - Paginate large datasets
const pageSize = 50;
int page = 0;

Future<List<Document<Book>>> getNextPage() async {
  final offset = page * pageSize;
  final docs = await db.listDocuments<Book>(
    "books",
    filters: {
      'limit': pageSize,
      'offset': offset,
    },
    converter: Book.fromJson,
  );
  page++;
  return docs;
}

// Load pages on demand
class PaginatedBookList extends StatefulWidget {
  @override
  State<PaginatedBookList> createState() => _PaginatedBookListState();
}

class _PaginatedBookListState extends State<PaginatedBookList> {
  final books = <Document<Book>>[];
  bool hasMore = true;
  bool isLoading = false;

  Future<void> loadNextPage() async {
    if (isLoading || !hasMore) return;

    setState(() => isLoading = true);

    try {
      final newBooks = await getNextPage();
      setState(() {
        books.addAll(newBooks);
        if (newBooks.length < 50) {
          hasMore = false;
        }
      });
    } catch (e) {
      print('Error loading page: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: books.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == books.length) {
          loadNextPage();
          return const Center(child: CircularProgressIndicator());
        }
        return ListTile(title: Text(books[index].data.title));
      },
    );
  }
}
```

### 3. Caching

```dart
class DocumentCache {
  final Map<String, Document> _cache = {};
  static const cacheDuration = Duration(minutes: 5);
  final Map<String, DateTime> _timestamps = {};

  Document? get(String key) {
    if (_isCacheValid(key)) {
      return _cache[key];
    }
    _cache.remove(key);
    _timestamps.remove(key);
    return null;
  }

  void set(String key, Document value) {
    _cache[key] = value;
    _timestamps[key] = DateTime.now();
  }

  bool _isCacheValid(String key) {
    final timestamp = _timestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < cacheDuration;
  }

  void clear() {
    _cache.clear();
    _timestamps.clear();
  }
}

// Use cache
final cache = DocumentCache();

Future<Document<Book>> getBook(String id) async {
  // Try cache first
  final cached = cache.get('book_$id');
  if (cached != null) {
    return cached;
  }

  // Fetch from server
  final doc = await db.getDocument<Book>("books", id);
  cache.set('book_$id', doc);
  return doc;
}
```

### 4. Lazy Loading

```dart
class LazyLoadingList extends StatefulWidget {
  @override
  State<LazyLoadingList> createState() => _LazyLoadingListState();
}

class _LazyLoadingListState extends State<LazyLoadingList> {
  final items = <Document<Item>>[];
  bool hasMore = true;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController!.addListener(_onScroll);
    _loadMore();
  }

  void _onScroll() {
    if (_scrollController!.position.pixels ==
        _scrollController!.position.maxScrollExtent) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (!hasMore) return;

    final newItems = await db.listDocuments<Item>(
      "items",
      filters: {
        'limit': 20,
        'offset': items.length,
      },
      converter: Item.fromJson,
    );

    setState(() {
      items.addAll(newItems);
      if (newItems.length < 20) {
        hasMore = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(items[index].data.name));
      },
    );
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }
}
```

### 5. Select Specific Fields

```dart
// Only fetch needed fields to reduce bandwidth
final results = await db.listDocuments(
  "books",
  queryBuilder: QueryBuilder()
    .select('id')
    .select('title')
    .select('price')
    .limit(100),
);

print('Fetched only needed fields');
```

---

## Monitoring & Debugging

### Query Performance

```dart
Future<T> measureQueryTime<T>(
  Future<T> Function() query,
) async {
  final sw = Stopwatch()..start();
  final result = await query();
  sw.stop();
  print('Query took ${sw.elapsedMilliseconds}ms');
  return result;
}

// Use it
final books = await measureQueryTime(() =>
  db.listDocuments<Book>("books")
);
```

### Request Logging

```dart
// Enable debug logging in Dio
final dio = Dio();
dio.interceptors.add(LogInterceptor(
  requestBody: true,
  responseBody: true,
));
```

---

**← [Real-Time Data](05-REAL_TIME_DATA.md) | [Examples & Patterns →](07-EXAMPLES_AND_PATTERNS.md)**
