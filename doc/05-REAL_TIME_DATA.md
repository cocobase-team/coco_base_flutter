# Real-Time Data & Subscriptions

Watch collections for live updates and build reactive applications.

## Table of Contents

1. [Real-Time Overview](#real-time-overview)
2. [Watching Collections](#watching-collections)
3. [Event Types](#event-types)
4. [Building UI with Real-Time Data](#building-ui-with-real-time-data)
5. [Error Handling](#error-handling)
6. [Best Practices](#best-practices)

---

## Real-Time Overview

CocoBase uses WebSockets to push live updates when documents change. This enables:

- ✅ Live collaboration
- ✅ Real-time notifications
- ✅ Instant UI updates
- ✅ Multiplayer features

### How It Works

```
App                    CocoBase Server
 |                           |
 |------- WebSocket Connect  |
 |<------ Connected ----------|
 |                           |
 |---- Watch Collection ---  |
 |<-- Document Updates -----|
 |                           |
 |                   (document changes)
 |<--- Document Changed -----|
 |                           |
 |---- Close Connection -----|
```

---

## Watching Collections

### Basic Watching

```dart
// Watch a collection for changes
Connection conn = db.watchCollection(
  "books",              // Collection name
  (event) {            // onEvent callback
    print('Event: ${event['event']}');
    print('Data: ${event['data']}');
  },
);

// Close when done
db.closeConnection(conn);
```

### With Callbacks

```dart
// Add callbacks for connection events
Connection conn = db.watchCollection(
  "books",
  (event) {
    print('Event: ${event['event']}');
    print('Data: ${event['data']}');
  },
  connectionName: 'books-watcher',
  onConnected: () => print('✅ Connected'),
  onConnectionError: () => print('❌ Error'),
);

// Close when done
db.closeConnection(conn);
```

### Handling Events

```dart
Connection conn = db.watchCollection(
  "books",
  (event) {
    final eventType = event['event'];    // 'create', 'update', or 'delete'
    final data = event['data'];          // The changed document
    
    switch (eventType) {
      case 'create':
        print('📝 New book: ${data['title']}');
        break;
      case 'update':
        print('✏️ Updated: ${data['title']}');
        break;
      case 'delete':
        print('🗑️ Deleted');
        break;
    }
  },
);
```

---

## Event Types

### Event Object Structure

```dart
class WatchEvent {
  final String type;              // 'create', 'update', 'delete', 'connected'
  final Document<dynamic> data;   // The document that changed
  final DateTime timestamp;       // When the change occurred
}
```

### Event Types Explained

#### 1. Connected Event

```dart
await db.watchCollection("books", (event) {
  if (event.type == 'connected') {
    print('✅ Connected to real-time updates');
  }
});
```

Fired when the WebSocket connection is established.

#### 2. Create Event

```dart
await db.watchCollection("books", (event) {
  if (event.type == 'create') {
    print('📝 New book created: ${event.data.data['title']}');
    // Update UI with new book
  }
});
```

Fired when a new document is created in the watched collection.

#### 3. Update Event

```dart
await db.watchCollection("books", (event) {
  if (event.type == 'update') {
    print('✏️ Book updated: ${event.data.id}');
    print('New price: ${event.data.data['price']}');
    // Update UI with changed data
  }
});
```

Fired when an existing document is modified.

#### 4. Delete Event

```dart
await db.watchCollection("books", (event) {
  if (event.type == 'delete') {
    print('🗑️ Book deleted: ${event.data.id}');
    // Remove from UI
  }
});
```

Fired when a document is deleted.

### Handling All Event Types

```dart
await db.watchCollection("books", (event) {
  switch (event.type) {
    case 'connected':
      print('✅ Connected');
      break;
    case 'create':
      print('📝 Created: ${event.data.id}');
      break;
    case 'update':
      print('✏️ Updated: ${event.data.id}');
      break;
    case 'delete':
      print('🗑️ Deleted: ${event.data.id}');
      break;
    default:
      print('Unknown event: ${event.type}');
  }
});
```

---

## Building UI with Real-Time Data

### Flutter Widget Example

```dart
class BookListWidget extends StatefulWidget {
  @override
  State<BookListWidget> createState() => _BookListWidgetState();
}

class _BookListWidgetState extends State<BookListWidget> {
  final db = Cocobase(CocobaseConfig(apiKey: 'YOUR_KEY'));
  final List<Document<Book>> books = [];
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadBooksAndWatch();
  }

  void _loadBooksAndWatch() async {
    // Load initial books
    try {
      final initialBooks = await db.listDocuments<Book>(
        "books",
        converter: Book.fromJson,
      );
      setState(() => books.addAll(initialBooks));
    } catch (e) {
      print('Error loading books: $e');
    }

    // Watch for changes
    try {
      await db.watchCollection(
        "books",
        (event) {
          if (!mounted) return;

          switch (event.type) {
            case 'connected':
              setState(() => isConnected = true);
              break;

            case 'create':
              setState(() {
                books.add(event.data as Document<Book>);
              });
              _showSnackBar('New book added!');
              break;

            case 'update':
              setState(() {
                final index = books.indexWhere(
                  (book) => book.id == event.data.id,
                );
                if (index != -1) {
                  books[index] = event.data as Document<Book>;
                }
              });
              _showSnackBar('Book updated!');
              break;

            case 'delete':
              setState(() {
                books.removeWhere((book) => book.id == event.data.id);
              });
              _showSnackBar('Book deleted!');
              break;
          }
        },
        converter: Book.fromJson,
      );
    } catch (e) {
      print('Error watching collection: $e');
      if (mounted) {
        _showSnackBar('Connection lost');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: isConnected
                  ? const Text('🟢 Live')
                  : const Text('🔴 Offline'),
            ),
          ),
        ],
      ),
      body: books.isEmpty
          ? const Center(child: Text('No books'))
          : ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return ListTile(
                  title: Text(book.data.title),
                  subtitle: Text(book.data.author),
                  trailing: Text('\$${book.data.price}'),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    db.closeConnection();
    super.dispose();
  }
}
```

---

## Real-Time Patterns

### Pattern 1: Live Collaboration

```dart
// Multiple users editing the same document
class CollaborativeEditor extends StatefulWidget {
  final String documentId;

  @override
  State<CollaborativeEditor> createState() => _CollaborativeEditorState();
}

class _CollaborativeEditorState extends State<CollaborativeEditor> {
  final db = Cocobase(CocobaseConfig(apiKey: 'YOUR_KEY'));
  late Document<DocumentModel> document;
  final editorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAndWatch();
  }

  void _loadAndWatch() async {
    // Load current document
    document = await db.getDocument<DocumentModel>(
      "documents",
      widget.documentId,
      converter: DocumentModel.fromJson,
    );
    editorController.text = document.data.content;

    // Watch for remote changes
    await db.watchCollection(
      "documents",
      (event) {
        if (event.type == 'update' && event.data.id == widget.documentId) {
          // Someone else edited this document
          final updatedDoc = event.data as Document<DocumentModel>;
          setState(() {
            document = updatedDoc;
            // Show indicator that document changed
            _showRemoteChangeIndicator();
          });
        }
      },
      queryBuilder: QueryBuilder().where('id', widget.documentId),
      converter: DocumentModel.fromJson,
    );
  }

  void _showRemoteChangeIndicator() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document updated by another user'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _saveDocument() async {
    await db.updateDocument(
      "documents",
      widget.documentId,
      {'content': editorController.text},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collaborative Editor')),
      body: TextField(
        controller: editorController,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          hintText: 'Start typing...',
          border: InputBorder.none,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveDocument,
        child: const Icon(Icons.save),
      ),
    );
  }

  @override
  void dispose() {
    db.closeConnection();
    editorController.dispose();
    super.dispose();
  }
}
```

### Pattern 2: Activity Feed

```dart
class ActivityFeedWidget extends StatefulWidget {
  @override
  State<ActivityFeedWidget> createState() => _ActivityFeedWidgetState();
}

class _ActivityFeedWidgetState extends State<ActivityFeedWidget> {
  final db = Cocobase(CocobaseConfig(apiKey: 'YOUR_KEY'));
  final List<ActivityEvent> events = [];

  @override
  void initState() {
    super.initState();
    _watchActivity();
  }

  void _watchActivity() async {
    await db.watchCollection(
      "activities",
      (event) {
        if (event.type != 'connected') {
          setState(() {
            events.insert(
              0,
              ActivityEvent.fromDocument(event.data),
            );
            // Keep only recent 50 events
            if (events.length > 50) {
              events.removeLast();
            }
          });
        }
      },
      queryBuilder: QueryBuilder().orderByDesc('createdAt').limit(50),
      converter: ActivityEvent.fromJson,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return ListTile(
          title: Text(event.message),
          subtitle: Text(event.timestamp.toString()),
          leading: CircleAvatar(
            child: Text(event.userId.substring(0, 1).toUpperCase()),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    db.closeConnection();
    super.dispose();
  }
}
```

### Pattern 3: Live Notifications

```dart
class NotificationService {
  final Cocobase db;

  NotificationService(this.db);

  void watchNotifications(String userId) async {
    await db.watchCollection(
      "notifications",
      (event) {
        if (event.type == 'create') {
          final notification = event.data.data;

          // Show OS notification
          _showOSNotification(
            notification['title'] as String,
            notification['message'] as String,
          );

          // Play sound
          _playNotificationSound();

          // Update badge count
          _updateBadgeCount();
        }
      },
      queryBuilder: QueryBuilder().where('userId', userId),
    );
  }

  void _showOSNotification(String title, String message) {
    // Implement OS notification (requires flutter_local_notifications)
    print('OS Notification: $title - $message');
  }

  void _playNotificationSound() {
    // Play sound using audio_service or similar
    print('Playing notification sound...');
  }

  void _updateBadgeCount() {
    // Update app badge count
    print('Updating badge count...');
  }
}
```

---

## Error Handling

### Connection Errors

```dart
try {
  await db.watchCollection("books", (event) {
    print('Event: ${event.type}');
  });
} on DioException catch (e) {
  print('Connection error: ${e.message}');
  // Retry with exponential backoff
  _retryConnection();
} catch (e) {
  print('Unexpected error: $e');
}
```

### Reconnection Logic

```dart
class ResilientWatcher {
  final Cocobase db;
  int _retryCount = 0;
  static const maxRetries = 5;
  static const initialDelay = Duration(seconds: 2);

  ResilientWatcher(this.db);

  Future<void> watch(String collection) async {
    try {
      await db.watchCollection(collection, (event) {
        if (event.type == 'connected') {
          _retryCount = 0;  // Reset on successful connection
          print('✅ Connected');
        }
      });
    } catch (e) {
      if (_retryCount < maxRetries) {
        _retryCount++;
        final delay = initialDelay * (1 << _retryCount);  // Exponential backoff
        print('Retrying in ${delay.inSeconds}s (attempt $_retryCount)');
        await Future.delayed(delay);
        await watch(collection);  // Retry
      } else {
        print('❌ Max retries reached');
        rethrow;
      }
    }
  }
}

// Use it
final watcher = ResilientWatcher(db);
await watcher.watch("books");
```

---

## Performance Considerations

### ✅ DO

- **Filter with QueryBuilder** - Watch only relevant documents
- **Close connections** - Call `closeConnection()` when done
- **Debounce UI updates** - Don't update on every event
- **Use type safety** - Validate data types
- **Handle disconnections** - Implement retry logic

### ❌ DON'T

- **Watch entire collections** - Always filter!
- **Process events without checking type** - Validate first
- **Keep many connections open** - One per collection
- **Ignore memory leaks** - Dispose properly
- **Update UI too frequently** - Can cause jank

### Memory-Efficient Watching

```dart
class OptimizedWatcher {
  final Cocobase db;
  static const maxBufferedEvents = 100;
  final List<WatchEvent> _buffer = [];
  late Future<void> _processingFuture;

  OptimizedWatcher(this.db);

  void watch(String collection) async {
    await db.watchCollection(
      collection,
      (event) {
        _buffer.add(event);

        // Process buffer in batches to avoid memory spikes
        if (_buffer.length >= maxBufferedEvents) {
          _processBuffer();
        }
      },
      // Always filter to reduce network and memory
      queryBuilder: QueryBuilder().limit(100),
    );
  }

  void _processBuffer() {
    // Batch process events
    for (var event in _buffer) {
      // Handle event
    }
    _buffer.clear();
  }
}
```

---

## Connection Lifecycle

```dart
class ConnectionManager {
  final Cocobase db;
  bool _isConnected = false;

  Future<void> connect() async {
    try {
      await db.watchCollection("collections", (_) {});
      _isConnected = true;
      print('✅ Connected to real-time service');
    } catch (e) {
      _isConnected = false;
      print('❌ Connection failed: $e');
    }
  }

  void disconnect() {
    if (_isConnected) {
      db.closeConnection();
      _isConnected = false;
      print('✅ Disconnected');
    }
  }

  bool get isConnected => _isConnected;
}
```

---

## Testing Real-Time Features

```dart
void main() {
  group('Real-Time Tests', () {
    late Cocobase db;

    setUpAll(() {
      db = Cocobase(CocobaseConfig(apiKey: 'test-key'));
    });

    test('Watch collection triggers on create', () async {
      bool eventReceived = false;

      unawaited(db.watchCollection("books", (event) {
        if (event.type == 'create') {
          eventReceived = true;
        }
      }));

      await Future.delayed(Duration(seconds: 1));

      // Create a book
      await db.createDocument("books", {'title': 'Test'});

      await Future.delayed(Duration(seconds: 1));
      expect(eventReceived, isTrue);
    });

    test('Close connection stops watching', () async {
      int eventCount = 0;

      unawaited(db.watchCollection("books", (_) {
        eventCount++;
      }));

      await Future.delayed(Duration(seconds: 1));
      db.closeConnection();
      await Future.delayed(Duration(seconds: 1));

      final initialCount = eventCount;

      // Create a document
      await db.createDocument("books", {'title': 'Test'});

      await Future.delayed(Duration(seconds: 1));
      // Event count shouldn't increase
      expect(eventCount, equals(initialCount));
    });
  });
}
```

---

**← [Authentication](04-AUTHENTICATION.md) | [Advanced Features →](06-ADVANCED_FEATURES.md)**
