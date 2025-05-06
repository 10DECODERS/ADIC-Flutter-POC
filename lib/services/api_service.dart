import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:adic_poc/models/staff.dart';
import 'package:adic_poc/services/auth_service.dart';
import 'package:adic_poc/services/telemetry_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = 'https://your-api-endpoint.com/api';
  final AuthService _authService = AuthService();
  final TelemetryService _telemetry = TelemetryService();

  Future<Map<String, String>> _getHeaders() async {
    final String? token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<T> _trackApiCall<T>({
    required String endpoint,
    required String method,
    required Future<T> Function() requestFunction,
  }) async {
    final stopwatch = Stopwatch()..start();
    _telemetry.logEvent('API_Call_Started', properties: {
      'endpoint': endpoint,
      'method': method,
    });

    try {
      final result = await requestFunction();
      stopwatch.stop();

      _telemetry.logEvent('API_Call_Success', properties: {
        'endpoint': endpoint,
        'method': method,
        'durationMs': stopwatch.elapsedMilliseconds.toString(),
      });

      return result;
    } catch (e, stack) {
      stopwatch.stop();

      _telemetry.logError('API_Call_Failure', stack, properties: {
        'endpoint': endpoint,
        'method': method,
        'durationMs': stopwatch.elapsedMilliseconds.toString(),
        'error': e.toString(),
      });

      rethrow;
    }
  }

  // Staff API operations
  Future<List<Staff>> fetchAllStaff() async {
    return _trackApiCall(
      endpoint: '/gateway/employees',
      method: 'GET',
      requestFunction: () async {
        final String? idToken = await _authService.getIdToken();
        if (idToken == null) throw Exception('No authentication token available');

        final response = await http.get(
          Uri.parse('https://apigateway-adic-enavete4d2abeyc3.centralindia-01.azurewebsites.net/api/gateway/employees'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
            'accept': '*/*',
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          return data.map((json) => Staff.fromJson(json)).toList();
        } else {
          throw Exception('Failed to load staff data: ${response.statusCode}');
        }
      },
    );
  }

  Future<Staff> fetchStaffById(int id) async {
    return _trackApiCall(
      endpoint: '/gateway/employees/$id',
      method: 'GET',
      requestFunction: () async {
        final String? idToken = await _authService.getIdToken();
        if (idToken == null) throw Exception('No authentication token available');

        final response = await http.get(
          Uri.parse('https://apigateway-adic-enavete4d2abeyc3.centralindia-01.azurewebsites.net/api/gateway/employees/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
            'accept': '*/*',
          },
        );

        if (response.statusCode == 200) {
          return Staff.fromJson(json.decode(response.body));
        } else {
          throw Exception('Failed to load staff: ${response.statusCode}');
        }
      },
    );
  }

  Future<Staff> createStaff(Staff staff) async {
    return _trackApiCall(
      endpoint: '/gateway/employees',
      method: 'POST',
      requestFunction: () async {
        final String? idToken = await _authService.getIdToken();
        if (idToken == null) throw Exception('No authentication token available');

        final response = await http.post(
          Uri.parse('https://apigateway-adic-enavete4d2abeyc3.centralindia-01.azurewebsites.net/api/gateway/employees'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
            'accept': '*/*',
          },
          body: json.encode({
            'name': staff.name,
            'email': staff.email,
            'phone': staff.phone,
            'position': staff.position,
            'department': staff.department,
          }),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          return Staff.fromJson(json.decode(response.body));
        } else {
          throw Exception('Failed to create staff: ${response.statusCode}');
        }
      },
    );
  }

  Future<Staff> updateStaff(Staff staff) async {
    return _trackApiCall(
      endpoint: '/gateway/employees/${staff.serverId}',
      method: 'PUT',
      requestFunction: () async {
        final String? idToken = await _authService.getIdToken();
        if (idToken == null) throw Exception('No authentication token available');

        final response = await http.put(
          Uri.parse('https://apigateway-adic-enavete4d2abeyc3.centralindia-01.azurewebsites.net/api/gateway/employees/${staff.serverId}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
            'accept': '*/*',
          },
          body: json.encode({
            'name': staff.name,
            'email': staff.email,
            'phone': staff.phone,
            'position': staff.position,
            'department': staff.department,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          return Staff.fromJson(json.decode(response.body));
        } else {
          throw Exception('Failed to update staff: ${response.statusCode}');
        }
      },
    );
  }

  Future<bool> deleteStaff(int id) async {
    return _trackApiCall(
      endpoint: '/gateway/employees/$id',
      method: 'DELETE',
      requestFunction: () async {
        final String? idToken = await _authService.getIdToken();
        if (idToken == null) throw Exception('No authentication token available');

        final response = await http.delete(
          Uri.parse('https://apigateway-adic-enavete4d2abeyc3.centralindia-01.azurewebsites.net/api/gateway/employees/$id'),
          headers: {
            'Authorization': 'Bearer $idToken',
            'accept': '*/*',
          },
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return true;
        } else {
          throw Exception('Failed to delete staff: ${response.statusCode}');
        }
      },
    );
  }
}
