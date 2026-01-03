# Examples & Real-World Patterns

Complete, production-ready code examples for common scenarios.

## Table of Contents

1. [Todo App](#todo-app)
2. [E-Commerce App](#e-commerce-app)
3. [Social Media Feed](#social-media-feed)
4. [Notes App](#notes-app)
5. [Messaging App](#messaging-app)

---

## Todo App

A complete todo application with real-time sync.

### Models

```dart
class Todo {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final DateTime dueDate;
  final int priority;  // 1-5
  final DateTime createdAt;
  final DateTime updatedAt;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
    required this.dueDate,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      completed: json['completed'] as bool? ?? false,
      dueDate: DateTime.parse(json['dueDate'] as String),
      priority: json['priority'] as int? ?? 3,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'completed': completed,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority,
    };
  }
}
```

### Service Layer

```dart
class TodoService {
  final Cocobase db;

  TodoService(this.db) {
    CocobaseConverters.register<Todo>(Todo.fromJson);
  }

  // Create
  Future<Document<Todo>> createTodo({
    required String title,
    required String description,
    required DateTime dueDate,
    int priority = 3,
  }) async {
    return await db.createDocument<Todo>(
      "todos",
      {
        'title': title,
        'description': description,
        'completed': false,
        'dueDate': dueDate.toIso8601String(),
        'priority': priority,
      },
    );
  }

  // Read - All todos
  Future<List<Document<Todo>>> getTodos() async {
    return await db.listDocuments<Todo>("todos");
  }

  // Read - Pending todos sorted by priority
  Future<List<Document<Todo>>> getPendingTodos() async {
    return await db.listDocuments<Todo>(
      "todos",
      queryBuilder: QueryBuilder()
        .where('completed', false)
        .orderByDesc('priority')
        .orderByAsc('dueDate'),
    );
  }

  // Read - Due today
  Future<List<Document<Todo>>> getTodaysTodos() async {
    final today = DateTime.now();
    final tomorrow = today.add(Duration(days: 1));

    return await db.listDocuments<Todo>(
      "todos",
      filters: {
        'dueDate__gte': today.toIso8601String(),
        'dueDate__lt': tomorrow.toIso8601String(),
        'completed': false,
      },
    );
  }

  // Update
  Future<Document<Todo>> updateTodo(
    String todoId,
    Map<String, dynamic> updates,
  ) async {
    return await db.updateDocument<Todo>(
      "todos",
      todoId,
      updates,
    );
  }

  // Toggle completion
  Future<Document<Todo>> toggleTodo(
    String todoId,
    bool completed,
  ) async {
    return await updateTodo(todoId, {'completed': completed});
  }

  // Delete
  Future<void> deleteTodo(String todoId) async {
    await db.deleteDocument("todos", todoId);
  }

  // Watch for changes
  Future<void> watchTodos(Function(WatchEvent) onEvent) async {
    await db.watchCollection(
      "todos",
      onEvent,
      converter: Todo.fromJson,
    );
  }
}
```

### UI Widget

```dart
class TodoListScreen extends StatefulWidget {
  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  late TodoService todoService;
  List<Document<Todo>> todos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final db = Cocobase(CocobaseConfig(apiKey: 'YOUR_KEY'));
    todoService = TodoService(db);
    _loadTodos();
  }

  void _loadTodos() async {
    try {
      final todos = await todoService.getPendingTodos();
      setState(() {
        this.todos = todos;
        isLoading = false;
      });
      _watchTodos();
    } catch (e) {
      print('Error: $e');
    }
  }

  void _watchTodos() {
    todoService.watchTodos((event) {
      if (!mounted) return;
      _loadTodos();  // Reload on changes
    });
  }

  void _createTodo() async {
    final title = 'New Todo';
    final result = await todoService.createTodo(
      title: title,
      description: 'Edit this todo',
      dueDate: DateTime.now().add(Duration(days: 1)),
    );
    setState(() => todos.add(result));
  }

  void _toggleTodo(Document<Todo> todo) async {
    await todoService.toggleTodo(todo.id, !todo.data.completed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Todos')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];
                return CheckboxListTile(
                  title: Text(
                    todo.data.title,
                    style: TextStyle(
                      decoration: todo.data.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  value: todo.data.completed,
                  onChanged: (_) => _toggleTodo(todo),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTodo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

---

## E-Commerce App

Product catalog with shopping cart and orders.

### Models

```dart
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final List<String> images;
  final double rating;
  final int reviews;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.images,
    required this.rating,
    required this.reviews,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int? ?? 0,
      images: List<String>.from(json['images'] as List? ?? []),
      rating: (json['rating'] as num? ?? 0).toDouble(),
      reviews: json['reviews'] as int? ?? 0,
    );
  }
}

class CartItem {
  final String productId;
  final int quantity;
  final double price;

  CartItem({
    required this.productId,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;
}

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double total;
  final String status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['userId'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) {
            final i = item as Map<String, dynamic>;
            return CartItem(
              productId: i['productId'] as String,
              quantity: i['quantity'] as int,
              price: (i['price'] as num).toDouble(),
            );
          })
          .toList(),
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
```

### E-Commerce Service

```dart
class ECommerceService {
  final Cocobase db;
  final List<CartItem> _cart = [];

  ECommerceService(this.db) {
    CocobaseConverters.register<Product>(Product.fromJson);
    CocobaseConverters.register<Order>(Order.fromJson);
  }

  // Products
  Future<List<Document<Product>>> getProducts() async {
    return await db.listDocuments<Product>(
      "products",
      filters: {'stock__gt': 0},
    );
  }

  Future<List<Document<Product>>> searchProducts(String query) async {
    return await db.listDocuments<Product>(
      "products",
      queryBuilder: QueryBuilder()
        .searchInFields(['name', 'description'], query)
        .where('stock__gt', 0),
    );
  }

  Future<List<Document<Product>>> getProductsByCategory(String category) async {
    return await db.listDocuments<Product>(
      "products",
      filters: {'category': category, 'stock__gt': 0},
    );
  }

  // Cart
  void addToCart(String productId, int quantity, double price) {
    final existing = _cart.firstWhereOrNull((item) => item.productId == productId);
    if (existing != null) {
      _cart.remove(existing);
      _cart.add(CartItem(
        productId: productId,
        quantity: existing.quantity + quantity,
        price: price,
      ));
    } else {
      _cart.add(CartItem(productId: productId, quantity: quantity, price: price));
    }
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((item) => item.productId == productId);
  }

  void clearCart() => _cart.clear();

  List<CartItem> getCart() => _cart;

  double getCartTotal() => _cart.fold(0, (sum, item) => sum + item.total);

  // Orders
  Future<Document<Order>> createOrder(String userId) async {
    if (_cart.isEmpty) throw Exception('Cart is empty');

    return await db.createDocument<Order>(
      "orders",
      {
        'userId': userId,
        'items': _cart.map((item) => {
          'productId': item.productId,
          'quantity': item.quantity,
          'price': item.price,
        }).toList(),
        'total': getCartTotal(),
        'status': 'pending',
      },
    );
  }

  Future<List<Document<Order>>> getUserOrders(String userId) async {
    return await db.listDocuments<Order>(
      "orders",
      filters: {'userId': userId},
      queryBuilder: QueryBuilder().orderByDesc('createdAt'),
    );
  }
}
```

---

## Social Media Feed

Real-time feed with likes and comments.

### Models

```dart
class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final List<String> images;
  final int likes;
  final int comments;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.images,
    required this.likes,
    required this.comments,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      content: json['content'] as String,
      images: List<String>.from(json['images'] as List? ?? []),
      likes: json['likes'] as int? ?? 0,
      comments: json['comments'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      postId: json['postId'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
```

### Feed Service

```dart
class FeedService {
  final Cocobase db;
  final String userId;

  FeedService(this.db, this.userId) {
    CocobaseConverters.register<Post>(Post.fromJson);
    CocobaseConverters.register<Comment>(Comment.fromJson);
  }

  // Posts
  Future<List<Document<Post>>> getFeed() async {
    return await db.listDocuments<Post>(
      "posts",
      queryBuilder: QueryBuilder()
        .orderByDesc('createdAt')
        .limit(20),
    );
  }

  Future<Document<Post>> createPost(
    String content,
    List<String> images,
  ) async {
    final user = await db.getCurrentUser();
    return await db.createDocument<Post>(
      "posts",
      {
        'authorId': userId,
        'authorName': user.name ?? 'Anonymous',
        'content': content,
        'images': images,
        'likes': 0,
        'comments': 0,
      },
    );
  }

  // Likes
  Future<void> likePost(String postId) async {
    await db.updateDocument(
      "posts",
      postId,
      {'likes': FieldValue.increment(1)},
    );
  }

  // Comments
  Future<Document<Comment>> addComment(
    String postId,
    String text,
  ) async {
    final user = await db.getCurrentUser();
    return await db.createDocument<Comment>(
      "comments",
      {
        'postId': postId,
        'authorId': userId,
        'authorName': user.name ?? 'Anonymous',
        'text': text,
      },
    );
  }

  Future<List<Document<Comment>>> getPostComments(String postId) async {
    return await db.listDocuments<Comment>(
      "comments",
      filters: {'postId': postId},
      queryBuilder: QueryBuilder().orderByAsc('createdAt'),
    );
  }

  // Real-time
  Future<void> watchFeed(Function(WatchEvent) onEvent) async {
    await db.watchCollection(
      "posts",
      onEvent,
      queryBuilder: QueryBuilder().limit(20),
      converter: Post.fromJson,
    );
  }
}
```

---

## Notes App

Rich notes with tagging and search.

### Service

```dart
class NotesService {
  final Cocobase db;

  NotesService(this.db);

  Future<Document> createNote({
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    return await db.createDocument(
      "notes",
      {
        'title': title,
        'content': content,
        'tags': tags,
        'pinned': false,
        'color': 'yellow',
      },
    );
  }

  Future<List<Document>> searchNotes(String query) async {
    return await db.listDocuments(
      "notes",
      queryBuilder: QueryBuilder()
        .searchInFields(['title', 'content'], query)
        .orderByDesc('updatedAt'),
    );
  }

  Future<List<Document>> getNotesByTag(String tag) async {
    return await db.listDocuments(
      "notes",
      filters: {'tags__in': tag},
    );
  }

  Future<List<Document>> getPinnedNotes() async {
    return await db.listDocuments(
      "notes",
      filters: {'pinned': true},
    );
  }
}
```

---

## Messaging App

Real-time messaging with typing indicators.

### Models & Service

```dart
class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String conversationId;
  final String text;
  final bool read;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.conversationId,
    required this.text,
    required this.read,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      conversationId: json['conversationId'] as String,
      text: json['text'] as String,
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class MessagingService {
  final Cocobase db;
  final String userId;

  MessagingService(this.db, this.userId);

  Future<void> sendMessage(
    String conversationId,
    String text,
  ) async {
    final user = await db.getCurrentUser();
    await db.createDocument(
      "messages",
      {
        'senderId': userId,
        'senderName': user.name ?? 'Anonymous',
        'conversationId': conversationId,
        'text': text,
        'read': false,
      },
    );
  }

  Future<List<Document<Message>>> getMessages(
    String conversationId,
  ) async {
    return await db.listDocuments<Message>(
      "messages",
      filters: {'conversationId': conversationId},
      queryBuilder: QueryBuilder().orderByAsc('createdAt').limit(50),
      converter: Message.fromJson,
    );
  }

  Future<void> watchMessages(
    String conversationId,
    Function(WatchEvent) onMessage,
  ) async {
    await db.watchCollection(
      "messages",
      onMessage,
      filters: {'conversationId': conversationId},
      converter: Message.fromJson,
    );
  }
}
```

---

**← [Advanced Features](06-ADVANCED_FEATURES.md) | [Common Issues →](08-COMMON_ISSUES.md)**
