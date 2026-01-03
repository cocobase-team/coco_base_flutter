# CocoBase Flutter SDK - Query Guide

Complete guide to using the powerful QueryBuilder for complex queries with OR conditions, relationships, and more.

## Table of Contents

- [Installation](#installation)
- [Basic Setup](#basic-setup)
- [Query Types](#query-types)
  - [AND Queries (Default)](#and-queries-default)
  - [Multi-Field OR](#multi-field-or)
  - [Simple OR Conditions](#simple-or-conditions)
  - [Named OR Groups](#named-or-groups)
- [Operators](#operators)
- [Relationships (Populate)](#relationships-populate)
- [Field Selection](#field-selection)
- [Sorting & Pagination](#sorting--pagination)
- [Real-World Examples](#real-world-examples)

## Installation

```yaml
dependencies:
  coco_base_flutter: ^1.0.0
```

## Basic Setup

```dart
import 'package:coco_base_flutter/coco_base_flutter.dart';

// Initialize with optional custom base URL
final cocobase = Cocobase(
  CocobaseConfig(
    apiKey: 'your-api-key',
    baseUrl: 'https://api.cocobase.buzz', // Optional
  ),
);
```

## Query Types

### AND Queries (Default)

All conditions are ANDed together by default:

```dart
// Find active users aged 18-65
final query = QueryBuilder()
    .where('status', 'active')
    .whereGreaterThanOrEqual('age', 18)
    .whereLessThanOrEqual('age', 65);

// SQL equivalent: WHERE status = 'active' AND age >= 18 AND age <= 65
```

### Multi-Field OR

Search for the same value across multiple fields:

```dart
// Search "john" in name OR email OR username
final query = QueryBuilder()
    .searchInFields(['name', 'email', 'username'], 'john');

// Or use multiFieldOr with operator
final query2 = QueryBuilder()
    .multiFieldOr(['firstName', 'lastName'], 'Smith');

// Results in: name__or__email__or__username__contains=john
// SQL: WHERE (name ILIKE '%john%' OR email ILIKE '%john%' OR username ILIKE '%john%')
```

### Simple OR Conditions

Group conditions with OR logic using `[or]` prefix:

```dart
// Find users who are EITHER over 18 OR admins
final query = QueryBuilder()
    .orGreaterThanOrEqual('age', 18)
    .or('role', 'admin');

// Results in: [or]age__gte=18&[or]role=admin
// SQL: WHERE (age >= 18 OR role = 'admin')
```

**Mix AND + OR:**

```dart
// Active users who are EITHER premium OR verified
final query = QueryBuilder()
    .where('status', 'active')           // AND condition
    .or('isPremium', true)                // OR condition
    .or('isVerified', true);              // OR condition

// SQL: WHERE status = 'active' AND (isPremium = true OR isVerified = true)
```

### Named OR Groups

Create multiple OR groups that are ANDed together:

```dart
// (age >= 18 OR role = admin) AND (country = USA OR country = UK)
final query = QueryBuilder()
    .orGroup('age', 'age__gte', 18)
    .orGroup('age', 'role', 'admin')
    .orGroup('country', 'country', 'USA')
    .orGroup('country', 'country', 'UK');

// SQL: WHERE (age >= 18 OR role = 'admin') AND (country = 'USA' OR country = 'UK')
```

**Complex Example:**

```dart
// (in stock OR pre-order) AND (on sale OR discounted) AND price <= 100
final query = QueryBuilder()
    .orGroup('availability', 'inStock', true)
    .orGroup('availability', 'isPreOrder', true)
    .orGroup('deals', 'onSale', true)
    .orGroup('deals', 'hasDiscount', true)
    .whereLessThanOrEqual('price', 100);
```

## Operators

### Comparison Operators

| Method                      | Operator | Example                               | SQL Equivalent        |
| --------------------------- | -------- | ------------------------------------- | --------------------- |
| `where()`                   | `eq`     | `.where('status', 'active')`          | `status = 'active'`   |
| `whereNotEqual()`           | `ne`     | `.whereNotEqual('status', 'deleted')` | `status != 'deleted'` |
| `whereGreaterThan()`        | `gt`     | `.whereGreaterThan('age', 18)`        | `age > 18`            |
| `whereGreaterThanOrEqual()` | `gte`    | `.whereGreaterThanOrEqual('age', 18)` | `age >= 18`           |
| `whereLessThan()`           | `lt`     | `.whereLessThan('age', 65)`           | `age < 65`            |
| `whereLessThanOrEqual()`    | `lte`    | `.whereLessThanOrEqual('age', 65)`    | `age <= 65`           |

### String Operators

| Method              | Operator     | Example                                |
| ------------------- | ------------ | -------------------------------------- |
| `whereContains()`   | `contains`   | `.whereContains('name', 'john')`       |
| `whereStartsWith()` | `startswith` | `.whereStartsWith('email', 'admin')`   |
| `whereEndsWith()`   | `endswith`   | `.whereEndsWith('email', 'gmail.com')` |

### List Operators

| Method         | Operator | Example                                        |
| -------------- | -------- | ---------------------------------------------- |
| `whereIn()`    | `in`     | `.whereIn('role', ['admin', 'moderator'])`     |
| `whereNotIn()` | `notin`  | `.whereNotIn('status', ['deleted', 'banned'])` |

### Null Operators

| Method          | Operator | Example                           |
| --------------- | -------- | --------------------------------- |
| `whereIsNull()` | `isnull` | `.whereIsNull('deletedAt', true)` |

### OR Variants

All operators have OR equivalents:

```dart
.orGreaterThan('age', 18)
.orLessThan('price', 100)
.orContains('name', 'john')
.orIn('role', ['admin', 'moderator'])
// ... etc
```

## Relationships (Populate)

### Basic Population

```dart
// Populate single relationship
final query = QueryBuilder()
    .where('status', 'published')
    .populate('author');

final posts = await cocobase.listDocuments('posts', queryBuilder: query);
// Each post will have author data populated
```

### Multiple Relationships

```dart
// Populate multiple relationships
final query = QueryBuilder()
    .populate('author')
    .populate('category')
    .populate('tags');

// Or use populateAll
final query2 = QueryBuilder()
    .populateAll(['author', 'category', 'tags']);
```

### Nested Population

```dart
// Populate relationships within relationships
final query = QueryBuilder()
    .populate('post.author')        // Post -> Author
    .populate('comments.user');     // Comments -> User
```

### Filter by Relationship Fields

```dart
// Find posts by admin authors
final query = QueryBuilder()
    .where('author.role', 'admin')
    .populate('author');
```

## Field Selection

Return only specific fields:

```dart
// Select specific fields
final query = QueryBuilder()
    .selectAll(['name', 'email', 'age']);

// With relationships
final query2 = QueryBuilder()
    .selectAll(['title', 'author.name', 'author.email'])
    .populate('author');
```

## Sorting & Pagination

```dart
// Sort ascending
final query = QueryBuilder()
    .where('status', 'active')
    .orderByAsc('age');

// Sort descending
final query2 = QueryBuilder()
    .orderByDesc('createdAt');

// Pagination
final query3 = QueryBuilder()
    .limit(50)
    .offset(100);

// Or use aliases
final query4 = QueryBuilder()
    .take(50)
    .skip(100);
```

## Real-World Examples

### 1. E-commerce Product Search

```dart
// Find available products: (in stock OR pre-order) AND (on sale OR new) AND price $50-$200
final products = await cocobase.listDocuments<Map<String, dynamic>>(
  'products',
  queryBuilder: QueryBuilder()
      .orGroup('availability', 'inStock', true)
      .orGroup('availability', 'preOrder', true)
      .orGroup('promo', 'onSale', true)
      .orGroup('promo', 'isNew', true)
      .whereGreaterThanOrEqual('price', 50)
      .whereLessThanOrEqual('price', 200)
      .orderByAsc('price')
      .limit(20),
);
```

### 2. User Management - Find Risky Users

```dart
// (multiple failed logins OR suspicious activity) AND NOT banned
final riskyUsers = await cocobase.listDocuments<Map<String, dynamic>>(
  'users',
  queryBuilder: QueryBuilder()
      .orGreaterThanOrEqual('failedLogins', 5)
      .or('suspiciousActivity', true)
      .whereNotEqual('status', 'banned')
      .orderByDesc('lastLogin'),
);
```

### 3. Task Management - Urgent Tasks

```dart
// (high priority OR overdue) AND (assigned to me OR unassigned) AND NOT completed
final urgentTasks = await cocobase.listDocuments<Map<String, dynamic>>(
  'tasks',
  queryBuilder: QueryBuilder()
      .orGroup('urgency', 'priority', 'high')
      .orGroup('urgency', 'isOverdue', true)
      .orGroup('assignment', 'assignedTo', 'user123')
      .orGroup('assignment', 'assignedTo__isnull', true)
      .whereNotEqual('status', 'completed')
      .populate('assignedUser')
      .orderByDesc('priority'),
);
```

### 4. Social Media - Popular Posts

```dart
// (likes > 100 OR comments > 50) AND recent AND NOT reported
final popularPosts = await cocobase.listDocuments<Map<String, dynamic>>(
  'posts',
  queryBuilder: QueryBuilder()
      .orGreaterThan('likes', 100)
      .orGreaterThan('comments', 50)
      .whereGreaterThanOrEqual('createdAt', '2025-01-05')
      .where('isReported', false)
      .populate('author')
      .selectAll(['title', 'excerpt', 'author.name', 'likes', 'comments'])
      .orderByDesc('likes')
      .limit(50),
);
```

### 5. Blog with Search & Filters

```dart
// Search in title/content + filter by authors + populate relationships
final posts = await cocobase.listDocuments<Map<String, dynamic>>(
  'posts',
  queryBuilder: QueryBuilder()
      .where('status', 'published')
      .searchInFields(['title', 'content'], 'flutter')
      .orIn('author_id', ['user1', 'user2', 'user3'])
      .populateAll(['author', 'category', 'tags'])
      .orderByDesc('createdAt')
      .limit(10),
);
```

### 6. Advanced Queries with Aggregation

```dart
// Count active users
final count = await cocobase.countDocuments(
  'users',
  queryBuilder: QueryBuilder()
      .where('status', 'active')
      .orGreaterThanOrEqual('age', 18),
);
print('Total: ${count.count}');

// Average age of active users
final avgAge = await cocobase.aggregateDocuments(
  'users',
  field: 'age',
  operation: 'avg',
  queryBuilder: QueryBuilder().where('status', 'active'),
);
print('Average age: ${avgAge.result}');

// Group users by role
final grouped = await cocobase.groupByField(
  'users',
  field: 'role',
  queryBuilder: QueryBuilder().where('status', 'active'),
);
for (var group in grouped.items) {
  print('${group.value}: ${group.count} users');
}
```

## Query Utilities

```dart
// Clone a query
final baseQuery = QueryBuilder()
    .where('status', 'active')
    .orderByDesc('createdAt');

final page1 = baseQuery.clone().take(10).skip(0);
final page2 = baseQuery.clone().take(10).skip(10);

// Clear a query
final query = QueryBuilder()
    .where('status', 'active')
    .populate('author');
query.clear(); // Resets everything

// Get query string
final queryString = query.build();
print(queryString); // status=active&populate=author
```

## API Methods Summary

All these methods support QueryBuilder:

```dart
// List documents
await cocobase.listDocuments('collection', queryBuilder: query);

// Count documents
await cocobase.countDocuments('collection', queryBuilder: query);

// Aggregate documents
await cocobase.aggregateDocuments('collection',
  field: 'age',
  operation: 'avg',
  queryBuilder: query,
);

// Group by field
await cocobase.groupByField('collection',
  field: 'role',
  queryBuilder: query,
);

// Get single document with populate
await cocobase.getDocument('collection', 'doc-id',
  populate: ['author', 'category'],
);
```

## Best Practices

1. **Use meaningful OR group names**

   ```dart
   // Good
   .orGroup('availability', 'inStock', true)
   .orGroup('availability', 'preOrder', true)

   // Bad
   .orGroup('a', 'inStock', true)
   ```

2. **Prefer `whereIn` over multiple OR conditions**

   ```dart
   // Good
   .whereIn('status', ['active', 'pending', 'review'])

   // Less efficient
   .or('status', 'active').or('status', 'pending').or('status', 'review')
   ```

3. **Use field selection to reduce payload**

   ```dart
   .selectAll(['id', 'name', 'email'])  // Only get what you need
   ```

4. **Combine filters wisely**

   ```dart
   // Filter by indexed fields first, then more expensive operations
   .where('status', 'active')           // Fast (indexed)
   .whereContains('bio', 'developer')   // Slower (full-text)
   ```

5. **Limit nested populations**

   ```dart
   // Good (2 levels)
   .populate('post.author')

   // Avoid (3+ levels can be slow)
   .populate('comment.post.author.company')
   ```

## Support

For issues or questions:

- GitHub: [lordace-coder/coco_base_flutter](https://github.com/lordace-coder/coco_base_flutter)
- API Docs: [https://docs.cocobase.buzz](https://docs.cocobase.buzz)
