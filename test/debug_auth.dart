import "package:coco_base_flutter/coco_base_flutter.dart";
import "package:dio/dio.dart";

void main() async {
  final config = CocobaseConfig(
    apiKey: "YOUR_API_KEY_HERE",
  );
  final db = Cocobase(config);

  print('=== Testing Authentication API Responses ===\n');

  // Test 1: Try to register a user
  print('Test 1: Registration Request');
  try {
    final email =
        'testuser${DateTime.now().millisecondsSinceEpoch}@example.com';
    print('📧 Registering with email: $email');

    await db.register(email, 'TestPassword123!', data: {'name': 'Test User'});

    print('✅ Registration successful');
    print('✅ Token set: ${db.isAuthenticated()}');

    if (db.isAuthenticated()) {
      try {
        final user = await db.getCurrentUser();
        print('✅ Got user: ${user.email}');
      } catch (e) {
        print('⚠️  Could not fetch user: $e');
      }
    }
  } on DioException catch (e) {
    print('❌ DioException: ${e.response?.statusCode}');
    print('   Message: ${e.message}');
    print('   Response: ${e.response?.data}');
  } catch (e) {
    print('❌ Error: $e');
    print('   Type: ${e.runtimeType}');
  }

  print('\n---\n');

  // Test 2: Try to login
  print('Test 2: Login Request');
  try {
    print('🔑 Attempting login...');
    await db.login('testuser@example.com', 'TestPassword123!');

    print('✅ Login successful');
    print('✅ Token set: ${db.isAuthenticated()}');

    if (db.isAuthenticated()) {
      try {
        final user = await db.getCurrentUser();
        print('✅ Got user: ${user.email}');
      } catch (e) {
        print('⚠️  Could not fetch user: $e');
      }
    }
  } on DioException catch (e) {
    print('❌ DioException: ${e.response?.statusCode}');
    print('   Message: ${e.message}');
    print('   Response: ${e.response?.data}');
  } catch (e) {
    print('❌ Error: $e');
    print('   Type: ${e.runtimeType}');
  }

  print('\n=== Test Complete ===');
}
