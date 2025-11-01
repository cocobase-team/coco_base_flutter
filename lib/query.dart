/// QueryBuilder class for building complex queries with operators and relationships
class QueryBuilder {
  final Map<String, dynamic> _filters = {};
  final List<Map<String, dynamic>> _orConditions = [];
  final Map<String, List<Map<String, dynamic>>> _namedOrGroups = {};
  final List<String> _populate = [];
  final List<String> _select = [];
  String? _sortBy;
  String? _order;
  int? _limit;
  int? _offset;

  /// Add an equality filter
  QueryBuilder where(String field, dynamic value) {
    _filters[field] = value;
    return this;
  }

  /// Greater than operator
  QueryBuilder whereGreaterThan(String field, dynamic value) {
    _filters['${field}__gt'] = value;
    return this;
  }

  /// Greater than or equal operator
  QueryBuilder whereGreaterThanOrEqual(String field, dynamic value) {
    _filters['${field}__gte'] = value;
    return this;
  }

  /// Less than operator
  QueryBuilder whereLessThan(String field, dynamic value) {
    _filters['${field}__lt'] = value;
    return this;
  }

  /// Less than or equal operator
  QueryBuilder whereLessThanOrEqual(String field, dynamic value) {
    _filters['${field}__lte'] = value;
    return this;
  }

  /// Not equal operator
  QueryBuilder whereNotEqual(String field, dynamic value) {
    _filters['${field}__ne'] = value;
    return this;
  }

  /// In array operator
  QueryBuilder whereIn(String field, List<dynamic> values) {
    _filters['${field}__in'] = values.join(',');
    return this;
  }

  /// Not in array operator
  QueryBuilder whereNotIn(String field, List<dynamic> values) {
    _filters['${field}__notin'] = values.join(',');
    return this;
  }

  /// Is null operator
  QueryBuilder whereIsNull(String field, bool isNull) {
    _filters['${field}__isnull'] = isNull.toString();
    return this;
  }

  /// Contains text operator (case-insensitive substring match)
  QueryBuilder whereContains(String field, String value) {
    _filters['${field}__contains'] = value;
    return this;
  }

  /// Starts with operator
  QueryBuilder whereStartsWith(String field, String value) {
    _filters['${field}__startswith'] = value;
    return this;
  }

  /// Ends with operator
  QueryBuilder whereEndsWith(String field, String value) {
    _filters['${field}__endswith'] = value;
    return this;
  }

  /// Add multiple filters at once
  QueryBuilder whereAll(Map<String, dynamic> filters) {
    _filters.addAll(filters);
    return this;
  }

  // ============================================================================
  // OR QUERY METHODS
  // ============================================================================

  /// Add a simple OR condition using [or] prefix
  /// Example: .or('age__gte', 18).or('role', 'admin')
  /// Results in: [or]age_gte=18&[or]role=admin
  QueryBuilder or(String field, dynamic value) {
    _orConditions.add({field: value});
    return this;
  }

  /// Add a named OR group condition using [or:groupname] prefix
  /// Example: .orGroup('tier', 'isPremium', true).orGroup('tier', 'isVerified', true)
  /// Results in: [or:tier]isPremium=true&[or:tier]isVerified=true
  QueryBuilder orGroup(String groupName, String field, dynamic value) {
    if (!_namedOrGroups.containsKey(groupName)) {
      _namedOrGroups[groupName] = [];
    }
    _namedOrGroups[groupName]!.add({field: value});
    return this;
  }

  /// Add an OR condition with operator
  /// Example: .orGreaterThan('age', 18) -> [or]age_gt=18
  QueryBuilder orGreaterThan(String field, dynamic value) {
    _orConditions.add({'${field}__gt': value});
    return this;
  }

  /// Add an OR condition with greater than or equal operator
  QueryBuilder orGreaterThanOrEqual(String field, dynamic value) {
    _orConditions.add({'${field}__gte': value});
    return this;
  }

  /// Add an OR condition with less than operator
  QueryBuilder orLessThan(String field, dynamic value) {
    _orConditions.add({'${field}__lt': value});
    return this;
  }

  /// Add an OR condition with less than or equal operator
  QueryBuilder orLessThanOrEqual(String field, dynamic value) {
    _orConditions.add({'${field}__lte': value});
    return this;
  }

  /// Add an OR condition with not equal operator
  QueryBuilder orNotEqual(String field, dynamic value) {
    _orConditions.add({'${field}__ne': value});
    return this;
  }

  /// Add an OR condition with contains operator
  QueryBuilder orContains(String field, String value) {
    _orConditions.add({'${field}__contains': value});
    return this;
  }

  /// Add an OR condition with starts with operator
  QueryBuilder orStartsWith(String field, String value) {
    _orConditions.add({'${field}__startswith': value});
    return this;
  }

  /// Add an OR condition with ends with operator
  QueryBuilder orEndsWith(String field, String value) {
    _orConditions.add({'${field}__endswith': value});
    return this;
  }

  /// Add an OR condition with in operator
  QueryBuilder orIn(String field, List<dynamic> values) {
    _orConditions.add({'${field}__in': values.join(',')});
    return this;
  }

  /// Add an OR condition with not in operator
  QueryBuilder orNotIn(String field, List<dynamic> values) {
    _orConditions.add({'${field}__notin': values.join(',')});
    return this;
  }

  /// Add an OR condition with is null operator
  QueryBuilder orIsNull(String field, bool isNull) {
    _orConditions.add({'${field}__isnull': isNull.toString()});
    return this;
  }

  /// Multi-field OR search (same value across multiple fields)
  /// Example: .multiFieldOr(['name', 'email'], 'john', operator: 'contains')
  /// Results in: name__or__email_contains=john
  QueryBuilder multiFieldOr(
    List<String> fields,
    dynamic value, {
    String? operator,
  }) {
    if (fields.isEmpty) return this;

    final fieldKey = fields.join('__or__');
    final key = operator != null ? '${fieldKey}__$operator' : fieldKey;
    _filters[key] = value;
    return this;
  }

  /// Convenience method for multi-field contains search
  /// Example: .searchInFields(['name', 'email', 'username'], 'john')
  /// Results in: name__or__email__or__username_contains=john
  QueryBuilder searchInFields(List<String> fields, String searchTerm) {
    return multiFieldOr(fields, searchTerm, operator: 'contains');
  }

  // ============================================================================
  // EXISTING METHODS
  // ============================================================================

  /// Populate a relationship field
  /// Supports nested relationships like 'author' or 'post.author'
  QueryBuilder populate(String field) {
    _populate.add(field);
    return this;
  }

  /// Populate multiple relationship fields
  QueryBuilder populateAll(List<String> fields) {
    _populate.addAll(fields);
    return this;
  }

  /// Select specific fields to return
  QueryBuilder select(String field) {
    _select.add(field);
    return this;
  }

  /// Select multiple fields to return
  QueryBuilder selectAll(List<String> fields) {
    _select.addAll(fields);
    return this;
  }

  /// Sort by a field
  QueryBuilder sortBy(String field, {String order = 'asc'}) {
    _sortBy = field;
    _order = order;
    return this;
  }

  /// Sort in ascending order
  QueryBuilder orderByAsc(String field) {
    _sortBy = field;
    _order = 'asc';
    return this;
  }

  /// Sort in descending order
  QueryBuilder orderByDesc(String field) {
    _sortBy = field;
    _order = 'desc';
    return this;
  }

  /// Set limit for pagination
  QueryBuilder limit(int value) {
    _limit = value;
    return this;
  }

  /// Set offset for pagination
  QueryBuilder offset(int value) {
    _offset = value;
    return this;
  }

  /// Skip documents (alias for offset)
  QueryBuilder skip(int value) {
    _offset = value;
    return this;
  }

  /// Take documents (alias for limit)
  QueryBuilder take(int value) {
    _limit = value;
    return this;
  }

  /// Build the query string for URL parameters
  String build() {
    List<String> params = [];

    // Add regular filters (AND conditions)
    _filters.forEach((key, value) {
      params.add('$key=${Uri.encodeComponent(value.toString())}');
    });

    // Add simple OR conditions [or]field=value
    for (var condition in _orConditions) {
      condition.forEach((key, value) {
        params.add('[or]$key=${Uri.encodeComponent(value.toString())}');
      });
    }

    // Add named OR groups [or:groupname]field=value
    _namedOrGroups.forEach((groupName, conditions) {
      for (var condition in conditions) {
        condition.forEach((key, value) {
          params.add(
            '[or:$groupName]$key=${Uri.encodeComponent(value.toString())}',
          );
        });
      }
    });

    // Add populate parameters
    for (var field in _populate) {
      params.add('populate=${Uri.encodeComponent(field)}');
    }

    // Add select parameters
    for (var field in _select) {
      params.add('select=${Uri.encodeComponent(field)}');
    }

    // Add sorting
    if (_sortBy != null) {
      params.add('sort_by=${Uri.encodeComponent(_sortBy!)}');
      if (_order != null) {
        params.add('order=$_order');
      }
    }

    // Add pagination
    if (_limit != null) {
      params.add('limit=$_limit');
    }
    if (_offset != null) {
      params.add('offset=$_offset');
    }

    return params.join('&');
  }

  /// Clear all query parameters
  void clear() {
    _filters.clear();
    _orConditions.clear();
    _namedOrGroups.clear();
    _populate.clear();
    _select.clear();
    _sortBy = null;
    _order = null;
    _limit = null;
    _offset = null;
  }

  /// Clone the query builder
  QueryBuilder clone() {
    final cloned = QueryBuilder()
      .._filters.addAll(_filters)
      .._populate.addAll(_populate)
      .._select.addAll(_select)
      .._sortBy = _sortBy
      .._order = _order
      .._limit = _limit
      .._offset = _offset;

    // Clone OR conditions
    for (var condition in _orConditions) {
      cloned._orConditions.add(Map<String, dynamic>.from(condition));
    }

    // Clone named OR groups
    _namedOrGroups.forEach((groupName, conditions) {
      cloned._namedOrGroups[groupName] = conditions
          .map((c) => Map<String, dynamic>.from(c))
          .toList();
    });

    return cloned;
  }
}
