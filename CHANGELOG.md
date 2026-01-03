## 1.0.2

- Fixed null handling in AppUser and TokenResponse models to prevent type casting errors
- Improved error handling in login and register methods to gracefully handle edge cases
- Made getCurrentUser() calls optional in authentication flows to prevent cascading failures
- Enhanced AppUser.fromJson to accept both 'id' and '\_id' field names for API compatibility
- Fixed TokenResponse.fromJson to handle camelCase and snake_case field variations

## 1.0.1

- Initial stable release with full authentication API
- Comprehensive QueryBuilder with 12 operators and filter maps
- Real-time WebSocket support with Connection lifecycle management
- Type-safe Document<T> model with generic support
- CocobaseConverters registry for automatic type conversion
- Complete API documentation and examples

## 0.0.1

- Initial project scaffold and basic setup
