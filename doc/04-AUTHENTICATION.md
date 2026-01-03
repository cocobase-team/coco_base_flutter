# Authentication & User Management

Secure your app with user authentication, registration, and profile management.

## Table of Contents

1. [Authentication Overview](#authentication-overview)
2. [User Registration](#user-registration)
3. [User Login](#user-login)
4. [Authentication State](#authentication-state)
5. [User Profile Management](#user-profile-management)
6. [Logout](#logout)
7. [Error Handling](#error-handling)
8. [Security Best Practices](#security-best-practices)

---

## Authentication Overview

CocoBase provides built-in authentication with:

- Email/password r}

`````

### API Key Management

```dart
// ❌ Bad - hardcoded key
const apiKey = 'YOUR_API_KEY_HERE';

// ✅ Good - from environment
const apiKey = String.fromEnvironment('COCOBASE_API_KEY');

// ✅ Better - from secure config
class AppConfig {
  static const apiKey = 'load_from_env_or_build_config';
}
````ure login with JWT tokens
- Automatic token management
- Session persistence

### Architecture

`````

User → Register/Login → CocoBase API
↓
Verify Credentials
↓
Generate JWT Token
↓
Store Token Securely
↓
Use Token for API Requests

````

---

## User Registration

### Basic Registration

```dart
final result = await db.register(
  email: 'user@example.com',
  password: 'SecurePassword123!',
);

print('Registered successfully!');
print('User ID: ${result.userId}');
print('Token: ${result.token}');
````

### Registration Response

The `register()` method returns:

```dart
class TokenResponse {
  final String userId;           // User ID
  final String token;            // JWT token
  final String? refreshToken;    // Refresh token (if available)
  final int? expiresIn;         // Token expiration in seconds
}
```

### Full Registration Flow

```dart
try {
  final result = await db.register(
    email: 'newuser@example.com',
    password: 'SecurePassword123!',
  );

  // Token is automatically stored
  print('✅ Registration successful!');
  print('User ID: ${result.userId}');

  // Immediately logged in - proceed to app
  final user = await db.getCurrentUser();
  print('Current user: ${user.email}');

} on DioException catch (e) {
  if (e.response?.statusCode == 400) {
    print('❌ Invalid email or password');
  } else if (e.response?.statusCode == 409) {
    print('❌ Email already registered');
  } else {
    print('❌ Error: ${e.message}');
  }
}
```

### Validation Before Registration

```dart
bool isValidEmail(String email) {
  return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
}

bool isValidPassword(String password) {
  // At least 8 chars, 1 uppercase, 1 number, 1 special char
  return password.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(password) &&
      RegExp(r'[0-9]').hasMatch(password) &&
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
}

Future<void> registerUser(String email, String password) async {
  if (!isValidEmail(email)) {
    print('Invalid email format');
    return;
  }

  if (!isValidPassword(password)) {
    print('Password must have 8+ chars, uppercase, number, symbol');
    return;
  }

  try {
    await db.register(email: email, password: password);
    print('✅ Registration successful!');
  } catch (e) {
    print('❌ Registration failed: $e');
  }
}
```

---

## User Login

### Basic Login

```dart
final result = await db.login(
  email: 'user@example.com',
  password: 'SecurePassword123!',
);

print('Logged in successfully!');
print('Token: ${result.token}');
```

### Login Response

Same as registration - returns `TokenResponse` with user ID and token.

### Full Login Flow

```dart
Future<bool> loginUser(String email, String password) async {
  try {
    final result = await db.login(
      email: email,
      password: password,
    );

    // Token is automatically stored
    print('✅ Login successful!');

    // Get user info
    final user = await db.getCurrentUser();
    print('Logged in as: ${user.email}');

    return true;

  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      print('❌ Invalid email or password');
    } else {
      print('❌ Login failed: ${e.message}');
    }
    return false;
  }
}
```

### Login in UI

```dart
// In a Login Widget
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  void _handleLogin() async {
    setState(() => isLoading = true);

    try {
      final config = CocobaseConfig(apiKey: 'YOUR_API_KEY');
      final db = Cocobase(config);

      await db.login(
        email: emailController.text,
        password: passwordController.text,
      );

      // Navigate to home
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _handleLogin,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Authentication State

### Check if Authenticated

```dart
final isAuthenticated = await db.isAuthenticated();

if (isAuthenticated) {
  print('User is logged in');
} else {
  print('User needs to log in');
}
```

### Get Current User

```dart
try {
  final user = await db.getCurrentUser();

  print('ID: ${user.id}');
  print('Email: ${user.email}');
  print('Name: ${user.name}');
  print('Created: ${user.createdAt}');

} catch (e) {
  print('No user logged in');
}
```

### User Object Structure

```dart
class AppUser {
  final String id;
  final String email;
  final String? name;
  final String? avatar;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

### Monitor Authentication State

```dart
// Check on app start
void main() async {
  final config = CocobaseConfig(apiKey: 'YOUR_API_KEY');
  final db = Cocobase(config);

  final isLoggedIn = await db.isAuthenticated();

  if (isLoggedIn) {
    final user = await db.getCurrentUser();
    print('Welcome back, ${user.email}!');
    // Show home screen
  } else {
    // Show login screen
  }
}
```

---

## User Profile Management

### Update User Profile

```dart
await db.updateUser(
  name: 'John Doe',
  metadata: {
    'avatar': 'https://example.com/avatar.jpg',
    'bio': 'Flutter developer',
    'location': 'San Francisco',
  },
);

print('Profile updated successfully!');
```

### Fetch Updated Profile

```dart
final user = await db.getCurrentUser();

print('Name: ${user.name}');
print('Avatar: ${user.metadata?['avatar']}');
print('Bio: ${user.metadata?['bio']}');
```

### Full Profile Update Flow

```dart
Future<void> updateUserProfile({
  required String name,
  required String bio,
  String? avatarUrl,
}) async {
  try {
    await db.updateUser(
      name: name,
      metadata: {
        'bio': bio,
        if (avatarUrl != null) 'avatar': avatarUrl,
      },
    );

    print('✅ Profile updated!');

    // Fetch and display updated profile
    final user = await db.getCurrentUser();
    print('Updated: ${user.name}');

  } catch (e) {
    print('❌ Update failed: $e');
  }
}
```

### Change Password

```dart
Future<bool> changePassword(
  String currentPassword,
  String newPassword,
) async {
  try {
    // Most auth systems require re-login with new password
    // You may need to:
    // 1. Verify current password
    // 2. Update password in your auth system
    // 3. Ask user to login again

    // This is system-dependent - contact your BaaS provider
    print('Password change not yet implemented');
    return false;

  } catch (e) {
    print('Error: $e');
    return false;
  }
}
```

---

## Logout

### Basic Logout

```dart
await db.logout();
print('Logged out successfully');
```

### Logout with Cleanup

```dart
Future<void> logoutUser() async {
  try {
    // Logout from backend
    await db.logout();

    // Clear any local data
    // (handles by SDK automatically with SharedPreferences)

    // Navigate to login
    // Navigator.of(context).pushReplacementNamed('/login');

    print('✅ Logged out successfully');

  } catch (e) {
    print('❌ Logout failed: $e');
  }
}
```

### Logout in UI

```dart
class UserMenu extends StatelessWidget {
  final Cocobase db;

  const UserMenu({required this.db});

  void _handleLogout(BuildContext context) async {
    try {
      await db.logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          child: const Text('Logout'),
          onTap: () => _handleLogout(context),
        ),
      ],
    );
  }
}
```

---

## Error Handling

### Common Authentication Errors

```dart
import 'package:dio/dio.dart';

Future<void> handleAuthError(DioException e) {
  final statusCode = e.response?.statusCode;

  switch (statusCode) {
    case 400:
      print('Invalid email or password format');
      break;
    case 401:
      print('Invalid credentials');
      break;
    case 409:
      print('Email already registered');
      break;
    case 500:
      print('Server error - try again later');
      break;
    default:
      print('Unknown error: ${e.message}');
  }
}
```

### Token Expiration Handling

```dart
Future<T> withTokenRefresh<T>(
  Future<T> Function() request,
) async {
  try {
    return await request();
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      // Token expired - user needs to login again
      print('Session expired - please login again');
      // Navigate to login screen
      throw Exception('Session expired');
    }
    rethrow;
  }
}

// Use it
final books = await withTokenRefresh(() =>
  db.listDocuments<Book>("books")
);
```

---

## Security Best Practices

### ✅ DO

- **Hash passwords client-side before sending** (if HTTPS is not used)
- **Use HTTPS** - Always!
- **Store tokens securely** - SDK does this via SharedPreferences
- **Validate input** - Check email/password format before sending
- **Handle token expiration** - Refresh or re-login
- **Log out on uninstall** - Clear tokens when user removes app
- **Use strong passwords** - Enforce minimum requirements
- **Protect API keys** - Never commit them to version control

### ❌ DON'T

- **Store passwords in SharedPreferences** - SDK doesn't do this
- **Send credentials in URLs** - Always in request body with HTTPS
- **Hardcode API keys** - Use environment variables
- **Log sensitive data** - Don't print tokens/passwords
- **Cache user data too long** - Refresh on app start
- **Trust client-side validation alone** - Always validate server-side
- **Reuse tokens across devices** - One token per session

### Secure Storage Example

```dart
// SDK handles this automatically via SharedPreferences
// But here's what it does under the hood:

import 'package:shared_preferences/shared_preferences.dart';

class SecureAuthStore {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
```

### API Key Management

```dart
// ❌ Bad - hardcoded key
const apiKey = 'YOUR_API_KEY_HERE';

// ✅ Good - from environment
const apiKey = String.fromEnvironment('COCOBASE_API_KEY');

// ✅ Better - from secure config
class AppConfig {
  static const apiKey = 'load_from_env_or_build_config';
}
```

### Rate Limiting Protection

```dart
class AuthRetry {
  static const maxAttempts = 5;
  static const lockoutDuration = Duration(minutes: 15);

  static int _failedAttempts = 0;
  static DateTime? _lockedUntil;

  static bool canAttempt() {
    if (_lockedUntil != null && DateTime.now().isBefore(_lockedUntil!)) {
      return false;  // Account locked
    }
    return true;
  }

  static void recordFailure() {
    _failedAttempts++;
    if (_failedAttempts >= maxAttempts) {
      _lockedUntil = DateTime.now().add(lockoutDuration);
      _failedAttempts = 0;
    }
  }

  static void recordSuccess() {
    _failedAttempts = 0;
    _lockedUntil = null;
  }
}

// Use it
if (!AuthRetry.canAttempt()) {
  print('Too many failed attempts. Try again later.');
  return;
}

try {
  await db.login(email: email, password: password);
  AuthRetry.recordSuccess();
} catch (e) {
  AuthRetry.recordFailure();
  print('Login failed');
}
```

---

## Advanced Patterns

### Pattern 1: Social Login Integration

```dart
// For Google Sign-In or similar
Future<void> loginWithGoogle() async {
  try {
    // 1. Get token from Google
    // final googleToken = await GoogleSignIn().signIn();

    // 2. Exchange with CocoBase
    // final result = await db.loginWithOAuth('google', googleToken);

    print('Social login not yet implemented');

  } catch (e) {
    print('Social login failed: $e');
  }
}
```

### Pattern 2: Persistent Login

```dart
// Automatically login on app start if session exists
class AuthService {
  final Cocobase db;

  AuthService(this.db);

  Future<bool> restoreSession() async {
    try {
      final isAuthenticated = await db.isAuthenticated();
      if (isAuthenticated) {
        final user = await db.getCurrentUser();
        print('✅ Session restored for ${user.email}');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Session restore failed: $e');
      return false;
    }
  }
}

// In main.dart
void main() async {
  final db = Cocobase(CocobaseConfig(apiKey: 'YOUR_KEY'));
  final authService = AuthService(db);

  final hasSession = await authService.restoreSession();

  runApp(MyApp(initialRoute: hasSession ? '/home' : '/login'));
}
```

### Pattern 3: Two-Factor Authentication

```dart
// When implementing 2FA
Future<void> loginWith2FA(String email, String password) async {
  try {
    // Step 1: Initial login
    final result = await db.login(email: email, password: password);

    // Step 2: Send OTP
    // await db.sendOTP(email);

    // Step 3: Wait for user to verify
    // final verified = await showOTPDialog();

    // Step 4: Complete authentication
    // await db.verifyOTP(email, otpCode);

    print('2FA flow initiated');

  } catch (e) {
    print('2FA login failed: $e');
  }
}
```

---

## Testing Authentication

```dart
// In tests
void main() {
  group('Authentication Tests', () {
    late Cocobase db;

    setUpAll(() {
      db = Cocobase(CocobaseConfig(apiKey: 'test-key'));
    });

    test('Register new user', () async {
      final result = await db.register(
        email: 'test@example.com',
        password: 'TestPassword123!',
      );

      expect(result.userId, isNotEmpty);
      expect(result.token, isNotEmpty);
    });

    test('Login with valid credentials', () async {
      final result = await db.login(
        email: 'test@example.com',
        password: 'TestPassword123!',
      );

      expect(result.token, isNotEmpty);
    });

    test('Get current user after login', () async {
      await db.login(
        email: 'test@example.com',
        password: 'TestPassword123!',
      );

      final user = await db.getCurrentUser();
      expect(user.email, equals('test@example.com'));
    });

    test('Logout clears session', () async {
      await db.login(
        email: 'test@example.com',
        password: 'TestPassword123!',
      );

      await db.logout();

      final isAuth = await db.isAuthenticated();
      expect(isAuth, isFalse);
    });
  });
}
```

---

**← [Collections](03-COLLECTIONS.md) | [Real-Time Data →](05-REAL_TIME_DATA.md)**
