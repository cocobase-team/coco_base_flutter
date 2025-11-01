/// Models for CocoBase API responses
library;

class Collection {
  final String id;
  final String name;
  final DateTime createdAt;

  Collection({required this.id, required this.name, required this.createdAt});

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'created_at': createdAt.toIso8601String()};
  }
}

class Document<T> {
  final String id;
  final Map<String, dynamic> collection; // Can be String or Map
  final T data;
  final DateTime createdAt;
  final DateTime updatedAt;

  Document({
    required this.id,
    required this.collection,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    // Handle collection being either a String or a Map
    dynamic collectionValue = json['collection'];

    return Document<T>(
      id: json['id'],
      collection: collectionValue,
      data: json['data'] as T,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] == null
          ? DateTime.parse(json['created_at'])
          : DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collection': collection,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class BatchCreateResponse<T> {
  final int created;
  final List<Document<T>> documents;

  BatchCreateResponse({required this.created, required this.documents});

  factory BatchCreateResponse.fromJson(Map<String, dynamic> json) {
    return BatchCreateResponse<T>(
      created: json['created'],
      documents: (json['documents'] as List)
          .map((doc) => Document<T>.fromJson(doc))
          .toList(),
    );
  }
}

class BatchUpdateResponse {
  final int updated;

  BatchUpdateResponse({required this.updated});

  factory BatchUpdateResponse.fromJson(Map<String, dynamic> json) {
    return BatchUpdateResponse(updated: json['updated']);
  }
}

class BatchDeleteResponse {
  final int deleted;

  BatchDeleteResponse({required this.deleted});

  factory BatchDeleteResponse.fromJson(Map<String, dynamic> json) {
    return BatchDeleteResponse(deleted: json['deleted']);
  }
}

class CountResponse {
  final int count;

  CountResponse({required this.count});

  factory CountResponse.fromJson(Map<String, dynamic> json) {
    return CountResponse(count: json['count']);
  }
}

class AggregateResponse {
  final double result;

  AggregateResponse({required this.result});

  factory AggregateResponse.fromJson(Map<String, dynamic> json) {
    return AggregateResponse(result: (json['result'] as num).toDouble());
  }
}

class GroupByItem {
  final dynamic value;
  final int count;

  GroupByItem({required this.value, required this.count});

  factory GroupByItem.fromJson(Map<String, dynamic> json) {
    return GroupByItem(value: json['value'], count: json['count']);
  }

  Map<String, dynamic> toJson() {
    return {'value': value, 'count': count};
  }
}

class GroupByResponse {
  final List<GroupByItem> items;

  GroupByResponse({required this.items});

  factory GroupByResponse.fromJson(List<dynamic> json) {
    return GroupByResponse(
      items: json.map((item) => GroupByItem.fromJson(item)).toList(),
    );
  }
}

class SchemaField {
  final String name;
  final String type;
  final bool nullable;

  SchemaField({required this.name, required this.type, required this.nullable});

  factory SchemaField.fromJson(Map<String, dynamic> json) {
    return SchemaField(
      name: json['name'],
      type: json['type'],
      nullable: json['nullable'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'type': type, 'nullable': nullable};
  }
}

class SchemaResponse {
  final List<SchemaField> fields;

  SchemaResponse({required this.fields});

  factory SchemaResponse.fromJson(Map<String, dynamic> json) {
    return SchemaResponse(
      fields: (json['fields'] as List)
          .map((field) => SchemaField.fromJson(field))
          .toList(),
    );
  }
}

class TokenResponse {
  final String accessToken;
  final String tokenType;

  TokenResponse({required this.accessToken, required this.tokenType});

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'] ?? 'Bearer',
    );
  }
}

class AppUser {
  final String id;
  final String email;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.id,
    required this.email,
    this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      data: json['data'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Connection {
  final dynamic socket;
  final String name;
  bool closed;
  final Function() close;

  Connection({
    required this.socket,
    required this.name,
    required this.closed,
    required this.close,
  });
}
