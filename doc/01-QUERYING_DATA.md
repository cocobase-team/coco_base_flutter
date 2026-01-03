# Querying Data

Master the art of filtering, sorting, and searching your documents with powerful query APIs.

## Table of Contents

1. [Simple Filters](#simple-filters)
2. [QueryBuilder API](#querybuilder-api)
3. [Operators Reference](#operators-reference)
4. [OR Queries](#or-queries)
5. [Sorting](#sorting)
6. [Pagination](#pagination)
7. [Advanced Examples](#advanced-examples)

---

## Simple Filters

### Filter Map Approach (Easiest)

Pass filters as a simple `Map<String, dynamic>`:

```dart
// Find active users older than 18
final users = await db.listDocuments<User>("users", filters: {
  'status': 'active',
  'age__gt': 18,  // __gt = greater than
});
```

This is the **recommended approach for most use cases** because:

- ✅ Simple and readable
- ✅ No need to learn QueryBuilder syntax
- ✅ Works with all operators
- ✅ Perfect for beginners

---

## QueryBuilder API

For more complex queries, use the fluent QueryBuilder:

```dart
final users = await db.listDocuments<User>("users",
  queryBuilder: QueryBuilder()
    .where('status', 'active')
    .whereGreaterThan('age', 18)
    .whereContains('email', '@gmail.com')
    .orderByDesc('createdAt')
    .limit(10),
);
```

### Why QueryBuilder?

- 🔗 **Chainable methods** - Build queries step by step
- 📝 **Self-documenting** - Method names are clear (`whereGreaterThan`, not `__gt`)
- 🔍 **IDE support** - Get autocomplete and type hints
- 🎯 **Complex queries** - Combine multiple conditions easily

---

## Operators Reference

### Comparison Operators

| Operator         | Filter Map     | QueryBuilder Method                      | Example                   |
| ---------------- | -------------- | ---------------------------------------- | ------------------------- |
| Equal            | `field: value` | `.where(field, value)`                   | `'age': 25`               |
| Greater Than     | `field__gt`    | `.whereGreaterThan(field, value)`        | `'age__gt': 18`           |
| Greater or Equal | `field__gte`   | `.whereGreaterThanOrEqual(field, value)` | `'age__gte': 18`          |
| Less Than        | `field__lt`    | `.whereLessThan(field, value)`           | `'age__lt': 65`           |
| Less or Equal    | `field__lte`   | `.whereLessThanOrEqual(field, value)`    | `'age__lte': 65`          |
| Not Equal        | `field__ne`    | `.whereNotEqual(field, value)`           | `'status__ne': 'deleted'` |

### String Operators

| Operator    | Filter Map          | QueryBuilder Method              | Example                        |
| ----------- | ------------------- | -------------------------------- | ------------------------------ |
| Contains    | `field__contains`   | `.whereContains(field, value)`   | `'title__contains': 'flutter'` |
| Starts With | `field__startswith` | `.whereStartsWith(field, value)` | `'email__startswith': 'admin'` |
| Ends With   | `field__endswith`   | `.whereEndsWith(field, value)`   | `'domain__endswith': '.com'`   |

### Array/List Operators

| Operator     | Filter Map     | QueryBuilder Method          | Example                               |
| ------------ | -------------- | ---------------------------- | ------------------------------------- |
| In Array     | `field__in`    | `.whereIn(field, values)`    | `'status__in': 'active,pending'`      |
| Not In Array | `field__notin` | `.whereNotIn(field, values)` | `'status__notin': 'deleted,archived'` |

### Special Operators

| Operator | Filter Map      | QueryBuilder Method         | Example                     |
| -------- | --------------- | --------------------------- | --------------------------- |
| Is Null  | `field__isnull` | `.whereIsNull(field, bool)` | `'deletedAt__isnull': true` |

---

## OR Queries

CocoBase supports three types of OR queries for different needs.

### Type 1: Simple OR Conditions

Use when you want "field1 = value1 **OR** field2 = value2":

```dart
// Find users with admin role OR with email verified
final query = QueryBuilder()
  .or('role', 'admin')
  .or('emailVerified', true);

// Produces: [or]role=admin&[or]emailVerified=true
final users = await db.listDocuments<User>("users",
  queryBuilder: query
);
```

### Type 2: Multi-Field OR (Search)

Use when you want to search across multiple fields:

```dart
// Search for "john" in name, email, or phone
final query = QueryBuilder()
  .searchInFields(['name', 'email', 'phone'], 'john');

// Produces: name__or__email__or__phone__contains=john
final users = await db.listDocuments<User>("users",
  queryBuilder: query
);
```

### Type 3: Named OR Groups

Use when you want to group OR conditions:

```dart
// Users where:
// - (role=admin OR role=moderator) AND status=active
final query = QueryBuilder()
  .orGroup('roleGroup', 'role', 'admin')
  .orGroup('roleGroup', 'role', 'moderator')
  .where('status', 'active');

// Produces: [or:roleGroup]role=admin&[or:roleGroup]role=moderator&status=active
final users = await db.listDocuments<User>("users",
  queryBuilder: query
);
```

---

## Sorting

### Single Field Sorting

```dart
// Sort by creation date (newest first)
final query = QueryBuilder()
  .orderByDesc('createdAt');

// Sort by price (lowest first)
final query = QueryBuilder()
  .orderByAsc('price');

// Or use sortBy with explicit order
final query = QueryBuilder()
  .sortBy('name', 'asc');
```

### Using Filter Map

```dart
final books = await db.listDocuments<Book>("books", filters: {
  'orderBy': 'title',  // Sort field
  'order': 'asc',      // Sort direction
});
```

---

## Pagination

### Limit and Offset

```dart
// Get the first 10 documents
final query = QueryBuilder()
  .limit(10);

// Skip first 20, get next 10 (page 2)
final query = QueryBuilder()
  .limit(10)
  .offset(20);
```

### Using Filter Map

```dart
final books = await db.listDocuments<Book>("books", filters: {
  'limit': 10,
  'offset': 20,
});
```

### Handy Aliases

```dart
// These are equivalent
queryBuilder.limit(10);      // same as...
queryBuilder.take(10);       // limit alias

queryBuilder.offset(20);     // same as...
queryBuilder.skip(20);       // offset alias
```

---

## Field Selection

### Select Specific Fields

Include only certain fields in the response:

```dart
// Only get title and price, not full document
final query = QueryBuilder()
  .select('title')
  .select('price');

// Or select multiple at once
final query = QueryBuilder()
  .selectAll(['title', 'price', 'author']);

final books = await db.listDocuments<Book>("books",
  queryBuilder: query
);
```

---

## Population (Relationships)

Load related documents automatically:

```dart
// Single relationship
final query = QueryBuilder()
  .populate('author');  // Load author details

// Multiple relationships
final query = QueryBuilder()
  .populateAll(['author', 'publisher']);

final books = await db.listDocuments<Book>("books",
  queryBuilder: query
);
```

---

## Advanced Examples

### Example 1: Search with Filters

Find published books by specific authors:

```dart
final books = await db.listDocuments<Book>("books",
  queryBuilder: QueryBuilder()
    .where('status', 'published')
    .searchInFields(['title', 'description'], 'flutter')
    .whereIn('authorId', ['auth1', 'auth2', 'auth3'])
    .orderByDesc('publishedAt')
    .limit(20),
);
```

### Example 2: Range Query

Find products in a price range:

```dart
final products = await db.listDocuments<Product>("products",
  queryBuilder: QueryBuilder()
    .whereGreaterThanOrEqual('price', 10)
    .whereLessThanOrEqual('price', 100)
    .populate('category'),
);
```

### Example 3: Complex OR Logic

Find premium users (verified OR have payment method):

```dart
final query = QueryBuilder()
  .orGroup('premium', 'emailVerified', true)
  .orGroup('premium', 'paymentMethodId__isnull', false)
  .where('status', 'active');

final users = await db.listDocuments<User>("users",
  queryBuilder: query,
);
```

### Example 4: Search and Filter

Search for restaurants by cuisine with ratings:

```dart
final restaurants = await db.listDocuments<Restaurant>("restaurants",
  queryBuilder: QueryBuilder()
    .searchInFields(['name', 'description'], 'pizza')
    .whereIn('cuisineType', ['Italian', 'Mediterranean'])
    .whereGreaterThan('rating', 4.0)
    .orderByDesc('rating')
    .limit(50),
);
```

### Example 5: Using Filter Map for Complex Query

```dart
final orders = await db.listDocuments<Order>("orders", filters: {
  'status': 'completed',
  'totalAmount__gte': 100,
  'createdAt__gte': '2024-01-01',
  'limit': 20,
  'offset': 0,
});
```

---

## Building Reusable Queries

Create query builders as functions:

```dart
QueryBuilder publishedBooksQuery(String searchTerm) {
  return QueryBuilder()
    .where('status', 'published')
    .searchInFields(['title', 'description'], searchTerm)
    .orderByDesc('publishedAt')
    .limit(20);
}

// Use it anywhere
final results = await db.listDocuments<Book>("books",
  queryBuilder: publishedBooksQuery('flutter'),
);
```

---

## Debugging Queries

### Print the Query String

```dart
final query = QueryBuilder()
  .where('status', 'active')
  .whereGreaterThan('age', 18)
  .limit(10);

print(query.build());
// Output: status=active&age__gt=18&limit=10
```

---

## Query Limits

- **Maximum limit**: 1000 documents per request
- **Offset range**: 0 to 100,000
- **Field name length**: 255 characters
- **Filter value length**: 10,000 characters

---

## Tips & Best Practices

1. **Use Filter Map for Simple Queries** - It's cleaner and faster
2. **Use QueryBuilder for Complex Logic** - When you need multiple conditions
3. **Always Limit Results** - Don't fetch thousands of documents unnecessarily
4. **Use Pagination** - For better performance and user experience
5. **Select Only Needed Fields** - Reduce bandwidth when possible
6. **Test Your Queries** - Use `.build()` to see the actual query string

---

**← [Getting Started](00-GETTING_STARTED.md) | [Type Conversion →](02-TYPE_CONVERSION.md)**
