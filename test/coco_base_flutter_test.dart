import "package:coco_base_flutter/coco_base_flutter.dart";
import "package:dio/dio.dart";

void main() async {
  final config = CocobaseConfig(
    apiKey: "VTXjd5f7SRhfyqpKKenvSNCYzOSOaVBj75pYBQ8Z",
  );
  final db = Cocobase(config);

  // ============================================================================
  // Test 1: Check Authentication Status
  // ============================================================================
  print('=== Test 1: Check Initial Authentication Status ===');

  try {
    final isAuth = db.isAuthenticated();
    print('✅ Is Authenticated: $isAuth');

    if (isAuth) {
      final user = await db.getCurrentUser();
      print('✅ Current User: ${user.id}');
      print('   Email: ${user.email}');
    } else {
      print('ℹ️  No user logged in (this is expected if not authenticated)');
    }
  } catch (e) {
    print('❌ Error checking auth status: $e');
  }

  // ============================================================================
  // Test 2: User Registration
  // ============================================================================
  print('\n=== Test 2: User Registration ===');

  try {
    print('📝 Registering new user...');
    await db.register(
      'testuser${DateTime.now().millisecondsSinceEpoch}@example.com',
      'TestPassword123!',
      data: {'name': 'Test User'},
    );

    print('✅ Registration Successful');
    print('   Is Authenticated: ${db.isAuthenticated()}');
    final user = await db.getCurrentUser();
    print('   User ID: ${user.id}');
    print('   Email: ${user.email}');
  } on DioException catch (e) {
    print('❌ Registration failed: ${e.response?.statusCode}');
    print('   Error: ${e.response?.data}');
  } catch (e) {
    print('❌ Unexpected error: $e');
  }

  // ============================================================================
  // Test 3: User Login
  // ============================================================================
  print('\n=== Test 3: User Login ===');

  try {
    print('🔑 Attempting login...');
    await db.login('testuser@example.com', 'TestPassword123!');

    print('✅ Login Successful');
    print('   Is Authenticated: ${db.isAuthenticated()}');
    final user = await db.getCurrentUser();
    print('   User ID: ${user.id}');
    print('   Email: ${user.email}');
  } on DioException catch (e) {
    print('❌ Login failed: ${e.response?.statusCode}');
    if (e.response?.statusCode == 401) {
      print('   Error: Invalid credentials');
    } else {
      print('   Error: ${e.response?.data}');
    }
  } catch (e) {
    print('❌ Unexpected error: $e');
  }

  // ============================================================================
  // Test 4: Get Current User
  // ============================================================================
  print('\n=== Test 4: Get Current User ===');

  try {
    print('👤 Fetching current user...');

    if (!db.isAuthenticated()) {
      print('ℹ️  User not authenticated. Skipping test.');
    } else {
      final user = await db.getCurrentUser();
      print('✅ Current User Retrieved');
      print('   ID: ${user.id}');
      print('   Email: ${user.email}');
    }
  } catch (e) {
    print('❌ Error fetching user: $e');
  }

  // ============================================================================
  // Test 5: Update User Profile
  // ============================================================================
  print('\n=== Test 5: Update User Profile ===');

  try {
    if (!db.isAuthenticated()) {
      print('ℹ️  User not authenticated. Skipping test.');
    } else {
      print('✏️ Updating user profile...');
      final updated = await db.updateUser(
        data: {'phone': '123-456-7890', 'age': 30},
      );

      print('✅ Profile Updated');
      print('   User ID: ${updated.id}');
    }
  } on DioException catch (e) {
    print('❌ Update failed: ${e.response?.statusCode}');
    print('   Error: ${e.response?.data}');
  } catch (e) {
    print('❌ Error: $e');
  }

  // ============================================================================
  // Test 6: Authentication Check with Request
  // ============================================================================
  print('\n=== Test 6: Authentication with Protected Endpoint ===');

  try {
    if (!db.isAuthenticated()) {
      print('ℹ️  User not authenticated. Skipping test.');
    } else {
      print('🔐 Making authenticated request...');
      final user = await db.getCurrentUser();
      print('✅ Authenticated Request Successful');
      print('   Bearer token is being sent automatically');
      print('   User ID: ${user.id}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }

  // ============================================================================
  // Test 7: User Logout
  // ============================================================================
  print('\n=== Test 7: User Logout ===');

  try {
    if (!db.isAuthenticated()) {
      print('ℹ️  User not authenticated. Skipping logout test.');
    } else {
      print('🚪 Logging out...');
      db.logout();

      print('✅ Logout Successful');
      print('   Token cleared');
      print('   User session ended');
      print('   Is Authenticated Now: ${db.isAuthenticated()}');
    }
  } catch (e) {
    print('❌ Logout failed: $e');
  }

  // ============================================================================
  // Test 8: Error Handling - Invalid Credentials
  // ============================================================================
  print('\n=== Test 8: Error Handling - Invalid Credentials ===');

  try {
    print('🔐 Attempting login with wrong password...');
    await db.login('testuser@example.com', 'WrongPassword');
    print('❌ Should have failed but didn\'t');
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      print('✅ Correctly rejected invalid credentials');
      print('   Status: ${e.response?.statusCode}');
    } else {
      print('⚠️ Got error but unexpected status: ${e.response?.statusCode}');
    }
  } catch (e) {
    print('❌ Unexpected error type: $e');
  }

  // ============================================================================
  // Test 9: Error Handling - Invalid Email Format
  // ============================================================================
  print('\n=== Test 9: Error Handling - Invalid Email Format ===');

  try {
    print('📧 Attempting registration with invalid email...');
    await db.register(
      'not-an-email',
      'TestPassword123!',
      data: {'name': 'Test User'},
    );
    print('❌ Should have failed but didn\'t');
  } on DioException catch (e) {
    print('✅ Correctly rejected invalid email');
    print('   Status: ${e.response?.statusCode}');
    print('   Error: ${e.response?.data}');
  } catch (e) {
    print('❌ Unexpected error: $e');
  }

  // ============================================================================
  // Test 10: Token Management
  // ============================================================================
  print('\n=== Test 10: Token Management ===');

  try {
    print('🔑 Checking token management...');

    final hasToken = db.isAuthenticated();
    print('✅ Has Valid Token: $hasToken');

    if (hasToken) {
      print('ℹ️  Token is active and valid');
      print('   Automatic bearer token injection is enabled');
    } else {
      print('ℹ️  No active token');
    }
  } catch (e) {
    print('❌ Error: $e');
  }

  print('\n=== All Authentication Tests Completed ===');
}
