// ignore_for_file: unused_local_variable

import 'package:coco_base_flutter/coco_base_flutter.dart';
import 'package:flutter/material.dart';

/// Comprehensive examples of using QueryBuilder with all features
void main() async {
  // Initialize Cocobase with custom base URL
  final cocobase = Cocobase(CocobaseConfig(apiKey: 'your-api-key-here'));

  // ============================================================================
  // BASIC QUERIES (AND conditions)
  // ============================================================================

  // Simple equality filter
  final query1 = QueryBuilder()
      .where('status', 'active')
      .where('role', 'admin');
  // Results in: status=active&role=admin

  // Using operators
  final query2 = QueryBuilder()
      .whereGreaterThanOrEqual('age', 18)
      .whereLessThanOrEqual('age', 65)
      .where('country', 'USA');
  // Results in: age__gte=18&age__lte=65&country=USA

  // String operators
  final query3 = QueryBuilder()
      .whereContains('email', 'gmail')
      .whereStartsWith('username', 'admin')
      .whereEndsWith('domain', '.com');
  // Results in: email__contains=gmail&username__startswith=admin&domain__endswith=.com

  // In operator
  final query4 = QueryBuilder()
      .whereIn('role', ['admin', 'moderator', 'support'])
      .where('status', 'active');
  // Results in: role__in=admin,moderator,support&status=active

  // Not in operator
  final query5 = QueryBuilder()
      .whereNotIn('status', ['deleted', 'banned'])
      .whereGreaterThan('age', 18);
  // Results in: status__notin=deleted,banned&age__gt=18

  // Is null operator
  final query6 = QueryBuilder()
      .whereIsNull('deletedAt', true) // WHERE deletedAt IS NULL
      .where('status', 'active');
  // Results in: deletedAt__isnull=true&status=active

  final query7 = QueryBuilder().whereIsNull(
    'profilePicture',
    false,
  ); // WHERE profilePicture IS NOT NULL
  // Results in: profilePicture__isnull=false

  // ============================================================================
  // MULTI-FIELD OR QUERIES (Search same value in multiple fields)
  // ============================================================================

  // Search "john" in name OR email
  final query8 = QueryBuilder().multiFieldOr(
    ['name', 'email'],
    'john',
    operator: 'contains',
  );
  // Results in: name__or__email__contains=john

  // Convenience method for searching
  final query9 = QueryBuilder().searchInFields([
    'name',
    'username',
    'email',
  ], 'admin');
  // Results in: name__or__username__or__email__contains=admin

  // Search in multiple fields with equality
  final query10 = QueryBuilder().multiFieldOr([
    'firstName',
    'lastName',
  ], 'Smith');
  // Results in: firstName__or__lastName=Smith

  // ============================================================================
  // SIMPLE OR CONDITIONS (using [or] prefix)
  // ============================================================================

  // Find users who are EITHER over 18 OR admins
  final query11 = QueryBuilder().or('age__gte', 18).or('role', 'admin');
  // Results in: [or]age__gte=18&[or]role=admin

  // Using convenience methods
  final query12 = QueryBuilder()
      .orGreaterThanOrEqual('age', 18)
      .or('role', 'admin');
  // Results in: [or]age__gte=18&[or]role=admin

  // Complex OR with AND
  final query13 = QueryBuilder()
      .where('status', 'active') // AND condition
      .orGreaterThanOrEqual('age', 18) // OR condition
      .or('role', 'admin'); // OR condition
  // Results in: status=active&[or]age__gte=18&[or]role=admin
  // Logic: WHERE status = 'active' AND (age >= 18 OR role = 'admin')

  // ============================================================================
  // NAMED OR GROUPS (using [or:groupname] prefix)
  // ============================================================================

  // (age >= 18 OR role = admin) AND (country = USA OR country = UK)
  final query14 = QueryBuilder()
      .orGroup('age', 'age__gte', 18)
      .orGroup('age', 'role', 'admin')
      .orGroup('country', 'country', 'USA')
      .orGroup('country', 'country', 'UK');
  // Results in: [or:age]age__gte=18&[or:age]role=admin&[or:country]country=USA&[or:country]country=UK

  // (premium OR verified) AND (active OR pending)
  final query15 = QueryBuilder()
      .orGroup('tier', 'isPremium', true)
      .orGroup('tier', 'isVerified', true)
      .orGroup('status', 'status', 'active')
      .orGroup('status', 'status', 'pending');
  // Results in: [or:tier]isPremium=true&[or:tier]isVerified=true&[or:status]status=active&[or:status]status=pending

  // Complex: (in stock OR pre-order) AND (on sale OR discounted) AND price <= 100
  final query16 = QueryBuilder()
      .orGroup('availability', 'inStock', true)
      .orGroup('availability', 'isPreOrder', true)
      .orGroup('deals', 'onSale', true)
      .orGroup('deals', 'hasDiscount', true)
      .whereLessThanOrEqual('price', 100);
  // Results in: [or:availability]inStock=true&[or:availability]isPreOrder=true&[or:deals]onSale=true&[or:deals]hasDiscount=true&price__lte=100

  // ============================================================================
  // POPULATE (Relationships)
  // ============================================================================

  // Populate single relationship
  final query17 = QueryBuilder()
      .where('status', 'published')
      .populate('author');
  // Results in: status=published&populate=author

  // Populate multiple relationships
  final query18 = QueryBuilder()
      .where('status', 'published')
      .populate('author')
      .populate('category')
      .populate('tags');
  // Results in: status=published&populate=author&populate=category&populate=tags

  // Or use populateAll
  final query19 = QueryBuilder().where('status', 'published').populateAll([
    'author',
    'category',
    'tags',
  ]);
  // Results in: status=published&populate=author&populate=category&populate=tags

  // Nested population
  final query20 = QueryBuilder()
      .populate('post.author') // Populate post, then author within post
      .populate('comments.user');
  // Results in: populate=post.author&populate=comments.user

  // ============================================================================
  // FIELD SELECTION
  // ============================================================================

  // Select specific fields
  final query21 = QueryBuilder().select('name').select('email').select('age');
  // Results in: select=name&select=email&select=age

  // Or use selectAll
  final query22 = QueryBuilder().selectAll(['name', 'email', 'age']);
  // Results in: select=name&select=email&select=age

  // Combine with populate
  final query23 = QueryBuilder()
      .selectAll(['title', 'content', 'author.name', 'author.email'])
      .populate('author');
  // Results in: select=title&select=content&select=author.name&select=author.email&populate=author

  // ============================================================================
  // SORTING & PAGINATION
  // ============================================================================

  // Sort ascending
  final query24 = QueryBuilder().where('status', 'active').orderByAsc('age');
  // Results in: status=active&sort_by=age&order=asc

  // Sort descending
  final query25 = QueryBuilder()
      .where('status', 'active')
      .orderByDesc('createdAt');
  // Results in: status=active&sort_by=createdAt&order=desc

  // Pagination
  final query26 = QueryBuilder()
      .where('status', 'active')
      .limit(50)
      .offset(100);
  // Results in: status=active&limit=50&offset=100

  // Or use skip/take aliases
  final query27 = QueryBuilder().where('status', 'active').take(50).skip(100);
  // Results in: status=active&limit=50&offset=100

  // ============================================================================
  // REAL-WORLD COMPLEX EXAMPLES
  // ============================================================================

  // Example 1: E-commerce Product Search
  // Find available products: (in stock OR pre-order) AND (on sale OR new) AND price 50-200
  final productQuery = QueryBuilder()
      .orGroup('availability', 'inStock', true)
      .orGroup('availability', 'preOrder', true)
      .orGroup('promo', 'onSale', true)
      .orGroup('promo', 'isNew', true)
      .whereGreaterThanOrEqual('price', 50)
      .whereLessThanOrEqual('price', 200)
      .orderByAsc('price')
      .limit(20);

  // Example 2: User Management
  // Find risky users: (multiple failed logins OR suspicious activity) AND NOT banned
  final riskyUsersQuery = QueryBuilder()
      .orGreaterThanOrEqual('failedLogins', 5)
      .or('suspiciousActivity', true)
      .whereNotEqual('status', 'banned')
      .orderByDesc('lastLogin');

  // Example 3: Task Management
  // Find urgent tasks: (high priority OR overdue) AND (assigned to me OR unassigned) AND NOT completed
  final urgentTasksQuery = QueryBuilder()
      .orGroup('urgency', 'priority', 'high')
      .orGroup('urgency', 'isOverdue', true)
      .orGroup('assignment', 'assignedTo', 'user123')
      .orGroup('assignment', 'assignedTo__isnull', true)
      .whereNotEqual('status', 'completed');

  // Example 4: Social Media Posts
  // Find popular posts: (likes > 100 OR comments > 50) AND created in last week AND NOT reported
  final popularPostsQuery = QueryBuilder()
      .orGreaterThan('likes', 100)
      .orGreaterThan('comments', 50)
      .whereGreaterThanOrEqual('createdAt', '2025-01-05')
      .where('isReported', false)
      .populate('author')
      .orderByDesc('likes')
      .limit(50);

  // Example 5: Blog with Full Features
  // Find published posts by specific authors or categories, with author & category populated
  final blogQuery = QueryBuilder()
      .where('status', 'published')
      .searchInFields([
        'title',
        'content',
      ], 'flutter') // Search in title OR content
      .orIn('author_id', ['user1', 'user2', 'user3'])
      .populateAll(['author', 'category', 'tags'])
      .selectAll([
        'title',
        'excerpt',
        'createdAt',
        'author.name',
        'category.name',
      ])
      .orderByDesc('createdAt')
      .limit(10);

  // ============================================================================
  // USING QUERIES WITH COCOBASE
  // ============================================================================

  // List documents with query
  try {
    final users = await cocobase.listDocuments<Map<String, dynamic>>(
      'users',
      queryBuilder: query13, // Use any query from above
    );
    debugPrint('Found ${users.length} users');
  } catch (e) {
    debugPrint('Error: $e');
  }

  // Get single document with populate
  try {
    final post = await cocobase.getDocument<Map<String, dynamic>>(
      'posts',
      'post-id-123',
      populate: ['author', 'category'],
    );
    debugPrint('Post: ${post.data}');
  } catch (e) {
    debugPrint('Error: $e');
  }

  // Count documents with query
  try {
    final count = await cocobase.countDocuments('users', queryBuilder: query13);
    debugPrint('Total users: ${count.count}');
  } catch (e) {
    debugPrint('Error: $e');
  }

  // Aggregate with query
  try {
    final avgAge = await cocobase.aggregateDocuments(
      'users',
      field: 'age',
      operation: 'avg',
      queryBuilder: QueryBuilder().where('status', 'active'),
    );
    debugPrint('Average age: ${avgAge.result}');
  } catch (e) {
    debugPrint('Error: $e');
  }

  // Group by with query
  try {
    final groupedUsers = await cocobase.groupByField(
      'users',
      field: 'role',
      queryBuilder: QueryBuilder().where('status', 'active'),
    );
    for (var group in groupedUsers.items) {
      debugPrint('${group.value}: ${group.count} users');
    }
  } catch (e) {
    debugPrint('Error: $e');
  }

  // ============================================================================
  // QUERY BUILDER UTILITIES
  // ============================================================================

  // Clone a query
  final baseQuery = QueryBuilder()
      .where('status', 'active')
      .orderByDesc('createdAt');

  final query28 = baseQuery.clone().limit(10); // Clone and modify
  final query29 = baseQuery.clone().limit(50); // Clone with different limit

  // Clear a query
  final query30 = QueryBuilder().where('status', 'active').populate('author');
  query30.clear(); // Clears all filters, populate, sorting, etc.

  // Build query string
  final queryString = query13.build();
  debugPrint('Query string: $queryString');
  // Output: status=active&[or]age__gte=18&[or]role=admin
}
