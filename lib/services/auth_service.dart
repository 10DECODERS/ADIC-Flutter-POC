import 'dart:convert';
import 'dart:io';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService {
  // Azure AD OAuth settings - replace with your values
  static const String clientId = '5e55e62b-9428-4315-8708-a1dbf6929abe';
  static const String tenantId = '4649f97a-c37c-49ae-98c9-a1981a56f28b';
  
  // Platform-specific redirect URLs
  static String get redirectUrl {
    if (Platform.isAndroid) {
      return 'msauth://com.example.flutter_application/auth';
    } else if (Platform.isIOS) {
      return 'msauth://com.example.flutter_application/auth';
    } else {
      return 'http://localhost';
    }
  }

  // OAuth endpoints
  final String _tokenUrl = 'https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token';
  final String _authorizationUrl = 'https://login.microsoftonline.com/$tenantId/oauth2/v2.0/authorize';

  // OAuth scopes
  static const List<String> _scopes = ['openid', 'profile', 'email', 'offline_access', 'User.Read'];

  // AppAuth instance
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  
  // Secure storage
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // User information
  User? _currentUser;
  User? get currentUser => _currentUser;

  // Get access token
  Future<String?> getAccessToken() async {
    if (_currentUser != null) {
      if (_currentUser!.isTokenExpired) {
        final bool refreshed = await _refreshToken(_currentUser!.refreshToken);
        if (!refreshed) {
          return null;
        }
      }
      return _currentUser!.accessToken;
    }
    
    final bool isLoggedInVal = await isLoggedIn();
    if (isLoggedInVal && _currentUser != null) {
      return _currentUser!.accessToken;
    }
    
    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final String? userJson = await _secureStorage.read(key: 'user');
    
    if (userJson == null) {
      return false;
    }
    
    try {
      final User user = User.fromJson(json.decode(userJson));
      
      if (user.isTokenExpired) {
        // Token expired, try to refresh
        final bool refreshed = await _refreshToken(user.refreshToken);
        return refreshed;
      }
      
      _currentUser = user;
      return true;
    } catch (e) {
      return false;
    }
  }

  // Login with Azure AD
  Future<bool> login() async {
    try {
      final AuthorizationTokenResponse? result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          redirectUrl,
          discoveryUrl: 'https://login.microsoftonline.com/$tenantId/v2.0/.well-known/openid-configuration',
          scopes: _scopes,
          promptValues: ['login'],
        ),
      );
      
      if (result != null) {
        final User user = await _getUserProfile(
          result.accessToken!,
          result.refreshToken!,
          result.accessTokenExpirationDateTime!,
        );
        
        await _secureStorage.write(key: 'user', value: json.encode(user.toJson()));
        _currentUser = user;
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _secureStorage.delete(key: 'user');
    _currentUser = null;
  }

  // Refresh token
  Future<bool> _refreshToken(String refreshToken) async {
    try {
      final TokenResponse? response = await _appAuth.token(
        TokenRequest(
          clientId,
          redirectUrl,
          refreshToken: refreshToken,
          discoveryUrl: 'https://login.microsoftonline.com/$tenantId/v2.0/.well-known/openid-configuration',
          scopes: _scopes,
          grantType: 'refresh_token',
        ),
      );
      
      if (response != null && response.accessToken != null) {
        final User user = await _getUserProfile(
          response.accessToken!,
          response.refreshToken ?? refreshToken,
          response.accessTokenExpirationDateTime!,
        );
        
        await _secureStorage.write(key: 'user', value: json.encode(user.toJson()));
        _currentUser = user;
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get user profile from Microsoft Graph API
  Future<User> _getUserProfile(String accessToken, String refreshToken, DateTime expiresAt) async {
    final http.Response response = await http.get(
      Uri.parse('https://graph.microsoft.com/v1.0/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> profile = json.decode(response.body);
      
      return User(
        id: profile['id'],
        displayName: profile['displayName'],
        email: profile['userPrincipalName'],
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      );
    } else {
      throw Exception('Failed to get user profile');
    }
  }
} 