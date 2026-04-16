import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/dio_client.dart';

class AuthService {
  final DioClient _client = DioClient();

  Future<void> _persistUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  String _extractErrorMessage(
    Object error, {
    String fallback = 'Something went wrong',
  }) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['message'] is String) {
        return data['message'] as String;
      }
      return error.message ?? fallback;
    }
    return error.toString();
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String company,
    required String designation,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        '/auth/signup',
        data: {
          'name': name,
          'email': email,
          'company': company,
          'designation': designation,
          'password': password,
        },
      );
      return response.data;
    } catch (e) {
      return {'message': _extractErrorMessage(e, fallback: 'Signup failed')};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _client.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data;
      if (data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await _persistUser(data['user']);
      }
      return data;
    } catch (e) {
      return {'message': _extractErrorMessage(e, fallback: 'Login failed')};
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _client.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return response.data;
    } catch (e) {
      return {
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to send reset link',
        ),
      };
    }
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final response = await _client.get('/auth/profile');
      final data = response.data as Map<String, dynamic>;
      if (data['user'] is Map<String, dynamic>) {
        await _persistUser(data['user'] as Map<String, dynamic>);
      }
      return data;
    } catch (e) {
      return {
        'message': _extractErrorMessage(e, fallback: 'Failed to fetch profile'),
      };
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String company,
    required String designation,
  }) async {
    try {
      final response = await _client.dio.put(
        '/auth/profile',
        data: {'name': name, 'company': company, 'designation': designation},
      );
      final data = response.data as Map<String, dynamic>;
      if (data['user'] is Map<String, dynamic>) {
        await _persistUser(data['user'] as Map<String, dynamic>);
      }
      return data;
    } catch (e) {
      return {
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to update profile',
        ),
      };
    }
  }

  Future<Map<String, dynamic>> saveHabitReport({
    required String dateKey,
    required List<String> checkedHabitIds,
    required int totalHabits,
    bool isOffDay = false,
  }) async {
    try {
      final response = await _client.dio.put(
        '/auth/habit-report',
        data: {
          'dateKey': dateKey,
          'checkedHabitIds': checkedHabitIds,
          'totalHabits': totalHabits,
          'isOffDay': isOffDay,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to save habit report',
        ),
      };
    }
  }

  Future<Map<String, dynamic>> fetchMonthlyHabitReport({String? month}) async {
    try {
      final response = await _client.get(
        '/auth/habit-report/monthly',
        queryParameters: month == null ? null : {'month': month},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to fetch monthly report',
        ),
      };
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) return jsonDecode(userStr);
    return null;
  }
}
