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
    final response = await http.get(
      Uri.parse('$_baseUrl/staff'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Staff.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load staff data: ${response.statusCode}');
    }
  }

  Future<Staff> fetchStaffById(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/staff/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Staff.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load staff: ${response.statusCode}');
    }
  }

  Future<Staff> createStaff(Staff staff) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/staff'),
      headers: await _getHeaders(),
      body: json.encode(staff.toJson()),
    );

    if (response.statusCode == 201) {
      return Staff.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create staff: ${response.statusCode}');
    }
  }

  Future<Staff> updateStaff(Staff staff) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/staff/${staff.serverId}'),
      headers: await _getHeaders(),
      body: json.encode(staff.toJson()),
    );

    if (response.statusCode == 200) {
      return Staff.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update staff: ${response.statusCode}');
    }
  }

  Future<bool> deleteStaff(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/staff/$id'),
      headers: await _getHeaders(),
    );

    return response.statusCode == 204;
  }
} 