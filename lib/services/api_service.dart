import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../models/patient_model.dart';
import '../models/result_model.dart';

class ApiService {
  // Toggle this to false to use the production backend
  static const bool _useLocalBackend = false;

  static String get baseUrl {
    if (!_useLocalBackend) {
      return 'https://dentalscan-backend.onrender.com';
    }
    if (kIsWeb) {
      // Automatically use the host IP the web app is being served from
      return 'http://${Uri.base.host}:8000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000'; // Android emulator localhost
    } else {
      return 'http://127.0.0.1:8000'; // iOS simulator and others
    }
  }
  
  static String? _token;

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_photo');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Bypass-Tunnel-Reminder': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<ApiResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json', 'Bypass-Tunnel-Reminder': 'true'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await saveToken(data['access_token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', data['user']['name']);
        await prefs.setString('user_email', data['user']['email']);
        return ApiResult(success: true, data: data);
      }
      return ApiResult(success: false, error: data['detail'] ?? 'Signup failed');
    } catch (e) {
      return ApiResult(success: false, error: e.toString());
    }
  }

  static Future<ApiResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json', 'Bypass-Tunnel-Reminder': 'true'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await saveToken(data['access_token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', data['user']['name']);
        await prefs.setString('user_email', data['user']['email']);
        return ApiResult(success: true, data: data);
      }
      return ApiResult(success: false, error: data['detail'] ?? 'Login failed');
    } catch (e) {
      return ApiResult(success: false, error: e.toString());
    }
  }

  static Future<ApiResult> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json', 'Bypass-Tunnel-Reminder': 'true'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return ApiResult(success: true, data: data);
      return ApiResult(success: false, error: data['detail'] ?? 'Failed');
    } catch (e) {
      return ApiResult(success: false, error: e.toString());
    }
  }

  static Future<ApiResult> resetPassword(String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json', 'Bypass-Tunnel-Reminder': 'true'},
        body: jsonEncode({'token': token, 'newPassword': newPassword}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return ApiResult(success: true, data: data);
      return ApiResult(success: false, error: data['detail'] ?? 'Failed');
    } catch (e) {
      return ApiResult(success: false, error: e.toString());
    }
  }


  static Future<void> logout() async {
    await clearToken();
  }

  static Future<ApiResult> getCurrentUser() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(Uri.parse('$baseUrl/auth/me'), headers: headers);
      if (response.statusCode == 200) {
        return ApiResult(success: true, data: jsonDecode(response.body));
      }
      return ApiResult(success: false, error: 'Not authenticated');
    } catch (e) {
      return ApiResult(success: false, error: e.toString());
    }
  }

  static Future<ApiResult> savePatient(PatientModel patient) async {
    try {
      final headers = await _authHeaders();
      final body = jsonEncode(patient.toMap());
      final response = await http.post(Uri.parse('$baseUrl/patients'), headers: headers, body: body);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return ApiResult(success: true, data: data);
      return ApiResult(success: false, error: data['detail'] ?? 'Failed to save patient');
    } catch (e) {
      return ApiResult(success: false, error: e.toString());
    }
  }

  static Future<ApiResult> getPatients() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(Uri.parse('$baseUrl/patients'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final patients = jsonList.map((json) => PatientModel(
          id: json['id'],
          name: json['name'],
          age: json['age'],
          gender: json['gender'] ?? 'Unknown',
          date: DateTime.parse(json['date']),
          mobile: json['mobile'],
          createdAt: DateTime.parse(json['createdAt']),
        )).toList();
        return ApiResult(success: true, data: patients);
      }
      return ApiResult(success: false, error: 'Failed to fetch patients');
    } catch (e) {
      return ApiResult(success: false, error: e.toString());
    }
  }

  static Future<ApiResult> saveScanResult({
    required String patientId,
    required ScanResult result,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = jsonEncode(result.toMap());
      final response = await http.post(Uri.parse('$baseUrl/scans'), headers: headers, body: body);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return ApiResult(success: true, data: data);
      return ApiResult(success: false, error: data['detail'] ?? 'Failed to save scan');
    } catch (e) {
      return ApiResult(success: false, error: e.toString());
    }
  }

  static Future<ApiResult> getAllScans() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(Uri.parse('$baseUrl/scans'), headers: headers);
      if (response.statusCode == 200) {
        return ApiResult(success: true, data: jsonDecode(response.body));
      }
      return ApiResult(success: false, error: 'Failed to fetch scans');
    } catch (e) {
      return ApiResult(success: false, error: e.toString());
    }
  }

  static Future<ApiResult> getPatientScans(String patientId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(Uri.parse('$baseUrl/scans/$patientId'), headers: headers);
      if (response.statusCode == 200) {
        return ApiResult(success: true, data: jsonDecode(response.body));
      }
      return ApiResult(success: false, error: 'Failed to fetch patient scans');
    } catch (e) {
      return ApiResult(success: false, error: e.toString());
    }
  }

  static Future<ApiResult> getDashboardStats() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(Uri.parse('$baseUrl/dashboard/stats'), headers: headers);
      if (response.statusCode == 200) {
        return ApiResult(success: true, data: jsonDecode(response.body));
      }
      return ApiResult(success: false, error: 'Failed to fetch stats');
    } catch (e) {
      return ApiResult(success: false, error: e.toString());
    }
  }

  static Future<ApiResult> validateImage(File imageFile, String expectedType) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/validate-image'));
      final token = await getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      request.fields['expected_type'] = expectedType;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return ApiResult(success: true, data: jsonDecode(response.body));
      }
      return ApiResult(success: false, error: 'Validation failed');
    } catch (e) {
      return ApiResult(success: false, error: e.toString());
    }
  }
}

class ApiResult {
  final bool success;
  final dynamic data;
  final String? error;
  ApiResult({required this.success, this.data, this.error});
}