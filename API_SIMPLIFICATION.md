# API Simplification Summary

## What Was Removed

### 1. Legacy `Query` Class

**Removed from `lib/query.dart`:**

```dart
// REMOVED - No longer needed
class Query {
  final Map<String, dynamic>? where;
  final String? orderBy;
  final int? limit;
  final int? offset;
  Query({...});
}
```

### 2. Dual Parameter Support

**Before (Confusing):**

```dart
Future<List<Document<T>>> listDocuments<T>(
  String collection, {
  QueryBuilder? queryBuilder,  // Which one should I use?
  Query? query,                 // This is confusing!
}) async { ... }
```

**After (Clear):**

```dart
Future<List<Document<T>>> listDocuments<T>(
  String collection, {
  QueryBuilder? queryBuilder,  // Only one way - simple!
}) async { ... }
```

### 3. Utility Function

**Removed:**

- `buildFilterQuery(Query? query)` - No longer needed

### 4. Backward Compatibility Method

**Removed from QueryBuilder:**

- `toQuery()` - No longer needed

## Methods That Changed

All these methods now only accept `QueryBuilder` (no more `Query` parameter):

1. ✅ `listDocuments(collection, {queryBuilder})`
2. ✅ `countDocuments(collection, {queryBuilder})`
3. ✅ `aggregateDocuments(collection, {field, operation, queryBuilder})`
4. ✅ `groupByField(collection, {field, queryBuilder})`

## What Stayed the Same

✅ **All QueryBuilder features** - Nothing removed, only simplified!

- All 12 operators
- Three types of OR queries
- Populate (relationships)
- Field selection
- Sorting & pagination
- Chainable API

✅ **All other methods** - No changes to:

- Collection management
- Document CRUD operations
- Batch operations
- Authentication
- Real-time features

## Migration Example

**Old Code (Still Works with Old SDK):**

```dart
// Using the old Query class
await cocobase.listDocuments(
  'users',
  query: Query(
    where: {'status': 'active', 'age__gte': 18},
    orderBy: 'createdAt',
    limit: 50,
  ),
);
```

**New Code (Cleaner, More Powerful):**

```dart
// Using QueryBuilder - the only way now
await cocobase.listDocuments(
  'users',
  queryBuilder: QueryBuilder()
      .where('status', 'active')
      .whereGreaterThanOrEqual('age', 18)
      .sortBy('createdAt')
      .limit(50),
);
```

## Benefits of This Change

### 1. No More Confusion

Users won't wonder "Should I use `query` or `queryBuilder`?"

### 2. One Powerful API

`QueryBuilder` supports ALL features:

- Simple AND queries
- Complex OR queries (3 types!)
- Relationships/populate
- All operators
- Field selection

### 3. Better Developer Experience

```dart
// Reads like natural language
QueryBuilder()
    .where('status', 'active')
    .orGreaterThan('age', 18)
    .or('role', 'admin')
    .populate('profile')
    .orderByDesc('createdAt')
    .limit(10)
```

### 4. Less Code to Maintain

- Removed ~30 lines of redundant code
- No more dual-path logic in methods
- Simpler, cleaner implementation

### 5. Future-Proof

Easy to add new features to QueryBuilder without creating confusion

## Files Modified

1. ✅ `lib/query.dart` - Removed `Query` class and `toQuery()` method
2. ✅ `lib/coco_base_flutter.dart` - Removed dual parameter support and `buildFilterQuery()`
3. ✅ Created `SIMPLIFIED_API.md` - Migration guide

## Breaking Change?

**Yes, but minimal:**

- Only affects users who were using the old `Query` class
- Easy migration: just switch to `QueryBuilder`
- QueryBuilder is more powerful anyway

**Recommendation:**

- Bump version to `2.0.0` (breaking change)
- Add migration guide to CHANGELOG
- Most users will benefit from the simplification

## Summary

✅ **Removed** confusing dual API (Query + QueryBuilder)

✅ **Kept** powerful QueryBuilder with ALL features

✅ **Result** cleaner, simpler, more intuitive API

The SDK is now easier to use and maintain! 🎉
