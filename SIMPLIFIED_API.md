# CocoBase Flutter SDK - Simplified Implementation

## ✅ Simplified API - One Way to Query

### What Changed?

**Before (Confusing):**

```dart
// Two different ways to query - confusing!
listDocuments('users', query: Query(...))          // Old way
listDocuments('users', queryBuilder: QueryBuilder()...)  // New way
```

**After (Clear):**

```dart
// One simple, powerful way to query
listDocuments('users', queryBuilder: QueryBuilder()...)
```

## Why This Change?

1. **Less Confusion**: Only one way to build queries
2. **More Powerful**: QueryBuilder supports all features (OR queries, populate, operators)
3. **Cleaner API**: No need to choose between `query` and `queryBuilder`
4. **Better DX**: Chainable, intuitive API

## Simple Migration

If you were using the old `Query` class:

**Before:**

```dart
final users = await cocobase.listDocuments(
  'users',
  query: Query(
    where: {'status': 'active'},
    orderBy: 'createdAt',
    limit: 10,
  ),
);
```

**After:**

```dart
final users = await cocobase.listDocuments(
  'users',
  queryBuilder: QueryBuilder()
      .where('status', 'active')
      .sortBy('createdAt')
      .limit(10),
);
```

## All Methods Now Use QueryBuilder

### List Documents

```dart
await cocobase.listDocuments(
  'users',
  queryBuilder: QueryBuilder()
      .where('status', 'active')
      .populate('profile'),
);
```

### Count Documents

```dart
await cocobase.countDocuments(
  'users',
  queryBuilder: QueryBuilder().where('status', 'active'),
);
```

### Aggregate Documents

```dart
await cocobase.aggregateDocuments(
  'users',
  field: 'age',
  operation: 'avg',
  queryBuilder: QueryBuilder().where('status', 'active'),
);
```

### Group By Field

```dart
await cocobase.groupByField(
  'users',
  field: 'role',
  queryBuilder: QueryBuilder().where('status', 'active'),
);
```

## QueryBuilder Still Has All Features

✅ **All 12 Operators**: `eq`, `ne`, `gt`, `gte`, `lt`, `lte`, `contains`, `startswith`, `endswith`, `in`, `notin`, `isnull`

✅ **Three Types of OR Queries**:

- Multi-field OR: `.searchInFields(['name', 'email'], 'john')`
- Simple OR: `.or('age__gte', 18).or('role', 'admin')`
- Named OR groups: `.orGroup('age', 'age__gte', 18)`

✅ **Populate (Relationships)**:

- Single: `.populate('author')`
- Multiple: `.populateAll(['author', 'category'])`
- Nested: `.populate('post.author')`

✅ **Field Selection**: `.selectAll(['name', 'email'])`

✅ **Sorting**: `.orderByAsc('age')` or `.orderByDesc('createdAt')`

✅ **Pagination**: `.limit(50).offset(100)` or `.take(50).skip(100)`

## Complete Example

```dart
import 'package:coco_base_flutter/coco_base_flutter.dart';

void main() async {
  final cocobase = Cocobase(
    CocobaseConfig(
      apiKey: 'your-api-key',
      baseUrl: 'https://api.cocobase.buzz', // Optional
    ),
  );

  // Complex query - still simple and readable!
  final products = await cocobase.listDocuments<Map<String, dynamic>>(
    'products',
    queryBuilder: QueryBuilder()
        // (in stock OR pre-order)
        .orGroup('availability', 'inStock', true)
        .orGroup('availability', 'preOrder', true)
        // AND (on sale OR new)
        .orGroup('promo', 'onSale', true)
        .orGroup('promo', 'isNew', true)
        // AND price range
        .whereGreaterThanOrEqual('price', 50)
        .whereLessThanOrEqual('price', 200)
        // Populate category
        .populate('category')
        // Sort and paginate
        .orderByAsc('price')
        .limit(20),
  );

  print('Found ${products.length} products');
}
```

## Benefits

✅ **Cleaner API** - No confusion about which parameter to use

✅ **More Powerful** - QueryBuilder supports all advanced features

✅ **Better Type Safety** - Chainable methods with clear names

✅ **Easier to Read** - Query logic flows naturally

✅ **Less Code** - No need for redundant logic handling two query types

## Summary

The SDK now has a **single, powerful way to build queries**: `QueryBuilder`.

No more confusion between `query` and `queryBuilder` parameters. Just use `QueryBuilder` for everything! 🎉
