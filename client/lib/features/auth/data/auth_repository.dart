import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';

class AuthRepository {
  Future<void> _saveUserProfile(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data['token'] != null) {
      await prefs.setString('auth_token', data['token']);
    }
    if (data['role'] != null) {
      await prefs.setString('user_role', data['role']);
    }
    if (data['name'] != null) {
      await prefs.setString('user_name', data['name']);
    }
    if (data['email'] != null) {
      await prefs.setString('user_email', data['email']);
    }
    final details = data['additionalDetails'] as Map<String, dynamic>?;
    if (details != null) {
      if (details['college'] != null) {
        await prefs.setString('user_college', details['college']);
      }
      if (details['rollNumber'] != null) {
        await prefs.setString('user_roll_number', details['rollNumber']);
      }
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveUserProfile(data);
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to login');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    Map<String, dynamic>? additionalDetails,
  }) async {
    try {
      final requestBody = {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        ...?(additionalDetails),
      };

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        await _saveUserProfile({
          ...data,
          'additionalDetails': additionalDetails,
        });
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to register');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

}
