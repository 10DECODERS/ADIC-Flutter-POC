import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:adic_poc/models/staff.dart';
import 'package:adic_poc/services/auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = 'https://your-api-endpoint.com/api';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final String? token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Staff API operations
  Future<List<Staff>> fetchAllStaff() async {
    try {
      final String? idToken = await _authService.getIdToken();
      
      if (idToken == null) {
        throw Exception('No authentication token available');
      }
      
      final response = await http.get(
        Uri.parse('https://apigateway-adic-enavete4d2abeyc3.centralindia-01.azurewebsites.net/api/gateway/employees'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
          'accept': '*/*',
        },
      );

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          return data.map((json) => Staff.fromJson(json)).toList();
        } catch (e) {
          print('Failed to parse staff data: $e');
          print('Response body: ${response.body}');
          throw Exception('Failed to parse staff data: $e');
        }
      } else {
        print('Failed to load staff data: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load staff data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching remote data: $e');
      throw Exception('Failed to fetch staff data: $e');
    }
  }

  Future<Staff> fetchStaffById(int id) async {
    try {
      final String? idToken = await _authService.getIdToken();
      
      if (idToken == null) {
        throw Exception('No authentication token available');
      }
      
      final response = await http.get(
        Uri.parse('https://apigateway-adic-enavete4d2abeyc3.centralindia-01.azurewebsites.net/api/gateway/employees/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
          'accept': '*/*',
        },
      );

      if (response.statusCode == 200) {
        try {
          return Staff.fromJson(json.decode(response.body));
        } catch (e) {
          print('Failed to parse staff data: $e');
          print('Response body: ${response.body}');
          throw Exception('Failed to parse staff data: $e');
        }
      } else {
        print('Failed to load staff: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load staff: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching staff: $e');
      throw Exception('Failed to fetch staff: $e');
    }
  }

  Future<Staff> createStaff(Staff staff) async {
    try {
      final String? idToken = await _authService.getIdToken();
      
      if (idToken == null) {
        throw Exception('No authentication token available');
      }
      
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
          'department': staff.department
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          return Staff.fromJson(json.decode(response.body));
        } catch (e) {
          print('Failed to parse created staff data: $e');
          print('Response body: ${response.body}');
          
          // Return the original staff with updated sync status as fallback
          staff.syncStatus = SyncStatus.synced;
          return staff;
        }
      } else {
        print('Failed to create staff: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to create staff: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating staff: $e');
      throw Exception('Failed to create staff: $e');
    }
  }

  Future<Staff> updateStaff(Staff staff) async {
    try {
      final String? idToken = await _authService.getIdToken();
      
      if (idToken == null) {
        throw Exception('No authentication token available');
      }
      
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
          'department': staff.department
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        try {
          return Staff.fromJson(json.decode(response.body));
        } catch (e) {
          print('Failed to parse updated staff data: $e');
          print('Response body: ${response.body}');
          
          // Return the original staff with updated sync status as fallback
          staff.syncStatus = SyncStatus.synced;
          return staff;
        }
      } else {
        print('Failed to update staff: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to update staff: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating staff: $e');
      throw Exception('Failed to update staff: $e');
    }
  }

  Future<bool> deleteStaff(int id) async {
    try {
      final String? idToken = await _authService.getIdToken();
      
      if (idToken == null) {
        throw Exception('No authentication token available');
      }
      
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
        print('Failed to delete staff: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting staff: $e');
      return false;
    }
  }
} 