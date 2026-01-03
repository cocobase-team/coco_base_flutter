# Collections Management

Learn how to create, read, update, and delete collections in CocoBase.

## Table of Contents

1. [What is a Collection?](#what-is-a-collection)
2. [Creating Collections](#creating-collections)
3. [Reading Collections](#reading-collections)
4. [Updating Collections](#updating-collections)
5. [Deleting Collections](#deleting-collections)
6. [Collection Schema](#collection-schema)
7. [Best Practices](#best-practices)

---

## What is a Collection?

A **collection** is like a table in traditional databases. It contains:

- Multiple documents (records)
- A schema that defines field types
- Metadata like creation/update timestamps
- Indexes for faster queries

Think of it as:

- Database Table ↔ Collection
- Table Row ↔ Document
- Column ↔ Field

---

## Creating Collections

### Basic Collection Creation

```dart
final collection = Collection(
  name: 'books',
  description: 'Book catalog',
);

final created = await db.createCollection(collection);
print('Created collection: ${created.name}');
```

### With Full Schema Definition

```dart
final collection = Collection(
  name: 'books',
  description: 'Book catalog with validation',
  fields: {
    'title': {'type': 'string', 'required': true},
    'author': {'type': 'string', 'required': true},
    'price': {'type': 'number', 'required': true},
    'published': {'type': 'boolean', 'required': false},
    'tags': {'type': 'array', 'required': false},
    'rating': {'type': 'number', 'default': 0},
  },
);

final created = await db.createCollection(collection);
```

### Valid Field Types

```dart
{
  'title': {'type': 'string'},         // Text
  'count': {'type': 'integer'},        // Whole numbers
  'price': {'type': 'number'},         // Decimals
  'active': {'type': 'boolean'},       // True/false
  'createdAt': {'type': 'datetime'},   // Date & time
  'metadata': {'type': 'object'},      // Nested object
  'tags': {'type': 'array'},           // List of values
  'userId': {'type': 'reference'},     // Link to other doc
}
```

### Field Options

```dart
{
  'email': {
    'type': 'string',
    'required': true,           // Must provide value
    'unique': true,             // No duplicates
    'default': '',              // Default value
    'indexed': true,            // Create index for faster queries
  }
}
```

---

## Reading Collections

### List All Collections

```dart
final collections = await db.listCollections();

for (var collection in collections) {
  print('Name: ${collection.name}');
  print('Description: ${collection.description}');
  print('Document count: ${collection.documentCount}');
}
```

### Get Specific Collection

```dart
final collection = await db.getCollection('books');

print('Collection: ${collection.name}');
print('Fields: ${collection.fields.keys}');
print('Documents: ${collection.documentCount}');
```

### Response Structure

Each collection object contains:

```dart
class Collection {
  final String name;
  final String? description;
  final Map<String, dynamic> fields;        // Field definitions
  final int documentCount;                  // Number of documents
  final DateTime createdAt;                 // When created
  final DateTime? updatedAt;                // Last modification
  final List<String>? indexes;              // Indexed fields
  final String? primaryKey;                 // Primary key field
}
```

---

## Updating Collections

### Add Description

```dart
final collection = await db.getCollection('books');

final updated = await db.updateCollection(
  Collection(
    name: 'books',
    description: 'Updated book catalog for 2024',
    fields: collection.fields,
  )
);

print('Updated: ${updated.description}');
```

### Add New Fields

```dart
final collection = await db.getCollection('books');

// Keep existing fields and add new one
final newFields = {...collection.fields};
newFields['isbn'] = {
  'type': 'string',
  'required': true,
  'unique': true,
};

final updated = await db.updateCollection(
  Collection(
    name: 'books',
    description: collection.description,
    fields: newFields,
  )
);

print('Added field: isbn');
```

### Modify Field Properties

```dart
final collection = await db.getCollection('books');

// Modify existing field
final updatedFields = {...collection.fields};
updatedFields['price'] = {
  'type': 'number',
  'required': true,
  'default': 0.0,
};

final updated = await db.updateCollection(
  Collection(
    name: 'books',
    description: collection.description,
    fields: updatedFields,
  )
);
```

---

## Deleting Collections

### Delete Collection

```dart
// This will delete the collection AND all documents in it!
final result = await db.deleteCollection('books');

if (result['success']) {
  print('Collection deleted');
} else {
  print('Error deleting collection');
}
```

### With Confirmation

```dart
bool confirmDelete(String collectionName) {
  // Show dialog to user, get confirmation
  return true;  // User confirmed
}

if (confirmDelete('books')) {
  await db.deleteCollection('books');
  print('Collection deleted');
}
```

---

## Collection Schema

### Get Collection Schema

```dart
final schema = await db.getCollectionSchema('books');

print('Schema:');
for (var field in schema.fields) {
  print('- ${field.name} (${field.type})');
  if (field.required) print('  Required: true');
  if (field.unique) print('  Unique: true');
  if (field.indexed) print('  Indexed: true');
}
```

### Schema Response Structure

```dart
class SchemaResponse {
  final List<SchemaField> fields;
  final String? primaryKey;
  final List<String>? indexes;
}

class SchemaField {
  final String name;
  final String type;
  final bool required;
  final bool unique;
  final bool indexed;
  final dynamic defaultValue;
}
```

---

## Collection Patterns

### Pattern 1: Hierarchical Collections

```dart
// Create related collections
await db.createCollection(Collection(
  name: 'authors',
  fields: {
    'name': {'type': 'string', 'required': true},
    'bio': {'type': 'string'},
  },
));

await db.createCollection(Collection(
  name: 'books',
  fields: {
    'title': {'type': 'string', 'required': true},
    'authorId': {'type': 'reference', 'required': true},
    'price': {'type': 'number'},
  },
));

// Now you can reference authors from books
final books = await db.listDocuments<Book>(
  "books",
  queryBuilder: QueryBuilder().populate('authorId'),
);
```

### Pattern 2: Multi-Tenant Collections

```dart
// Create tenant-specific collections
Future<void> createTenantCollections(String tenantId) async {
  // User-scoped collection
  await db.createCollection(Collection(
    name: 'users_$tenantId',
    description: 'Users for tenant $tenantId',
    fields: {
      'email': {'type': 'string', 'required': true, 'unique': true},
      'name': {'type': 'string', 'required': true},
    },
  ));

  // Data-scoped collection
  await db.createCollection(Collection(
    name: 'data_$tenantId',
    description: 'Data for tenant $tenantId',
    fields: {
      'title': {'type': 'string'},
      'content': {'type': 'string'},
    },
  ));
}

// Use it
await createTenantCollections('tenant-123');
final users = await db.listDocuments("users_tenant-123");
```

### Pattern 3: Temporal Collections

```dart
// Archive collections by date
Future<void> archiveOldData() async {
  final archive = await db.getCollection('events');

  // Create dated archive
  final dateStr = DateTime.now().subtract(Duration(days: 90))
      .toIso8601String().split('T')[0];

  await db.createCollection(Collection(
    name: 'events_archive_$dateStr',
    description: 'Archived events from $dateStr',
    fields: archive.fields,
  ));

  // Move old data to archive...
}
```

### Pattern 4: Document Versioning

```dart
// Create versioned collections
Future<void> createVersionedCollection(String name) async {
  await db.createCollection(Collection(
    name: name,
    fields: {
      'content': {'type': 'object', 'required': true},
      'version': {'type': 'integer', 'required': true},
      'previousVersionId': {'type': 'string'},
      'author': {'type': 'string'},
      'createdAt': {'type': 'datetime', 'indexed': true},
    },
  ));
}

// Use with version control
createVersionedCollection('documents');
```

---

## Best Practices

### ✅ DO

- **Create collections early** - Set up schema before writing code
- **Use required fields** - For essential data
- **Index frequently queried fields** - For performance
- **Use unique constraints** - For fields like email
- **Document your schema** - Add descriptions
- **Plan relationships** - Think about references before creation

### ❌ DON'T

- **Change schema frequently** - It affects data consistency
- **Create dynamic field names** - Use fixed schema
- **Store deeply nested objects** - Keep it flat
- **Ignore field types** - Use appropriate types
- **Create too many fields** - Keep it simple
- **Mix concerns** - One collection per domain entity

### Schema Design Tips

1. **Use meaningful names**

   ```dart
   // ✅ Good
   'createdAt', 'updatedAt', 'authorId'

   // ❌ Bad
   'ca', 'ua', 'aid'
   ```

2. **Be consistent with naming**

   ```dart
   // ✅ Good - camelCase
   'firstName', 'lastName', 'emailAddress'

   // ❌ Bad - mixed styles
   'first_name', 'LastName', 'EMAILADDRESS'
   ```

3. **Use specific types**

   ```dart
   // ✅ Good
   'age': {'type': 'integer'}
   'price': {'type': 'number'}

   // ❌ Bad - everything as string
   'age': {'type': 'string'}
   'price': {'type': 'string'}
   ```

4. **Plan for relationships**

   ```dart
   // ✅ Good - easy to join
   'books': {'authorId': 'ref-123'}

   // ❌ Bad - hard to query
   'books': {'author': {'id': '...', 'name': '...'}}
   ```

---

## Migration Guide

### Adding a Field to Existing Collection

```dart
final oldCollection = await db.getCollection('books');

final newFields = {...oldCollection.fields};
newFields['isbn'] = {
  'type': 'string',
  'required': false,  // Start as optional
  'indexed': true,
};

await db.updateCollection(Collection(
  name: 'books',
  description: oldCollection.description,
  fields: newFields,
));

print('Added isbn field to books collection');
```

### Removing a Field (Data Cleanup)

```dart
// Note: Most BaaS systems don't automatically delete field data.
// You may need to do this manually or contact support.

final collection = await db.getCollection('books');
final newFields = {...collection.fields};

// Remove the field from schema
newFields.remove('deprecatedField');

await db.updateCollection(Collection(
  name: 'books',
  description: collection.description,
  fields: newFields,
));
```

---

## Error Handling

```dart
try {
  final collection = Collection(
    name: 'books',
    fields: {'title': {'type': 'string', 'required': true}},
  );

  final created = await db.createCollection(collection);
  print('Success: ${created.name}');

} on DioException catch (e) {
  if (e.response?.statusCode == 409) {
    print('Collection already exists');
  } else {
    print('Network error: ${e.message}');
  }
} catch (e) {
  print('Unexpected error: $e');
}
```

---

**← [Type Conversion](02-TYPE_CONVERSION.md) | [Authentication →](04-AUTHENTICATION.md)**
