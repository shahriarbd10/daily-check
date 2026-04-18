import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/dio_client.dart';

class AuthService {
  final DioClient _client = DioClient();
  static const String _officeStartPrefsKey = 'office_start_time';
  static const String _officeEndPrefsKey = 'office_end_time';

  bool _isHmFormat(String value) =>
      RegExp(r'^\d{2}:\d{2}$').hasMatch(value.trim());

  Future<Map<String, dynamic>> _normalizeUser(
    Map<String, dynamic> rawUser, {
    String? preferredOfficeStart,
    String? preferredOfficeEnd,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStart = (prefs.getString(_officeStartPrefsKey) ?? '08:15').trim();
    final cachedEnd = (prefs.getString(_officeEndPrefsKey) ?? '18:00').trim();
    final preferredStart = (preferredOfficeStart ?? '').trim();
    final preferredEnd = (preferredOfficeEnd ?? '').trim();
    final serverStart = (rawUser['officeStartTime'] ?? '').toString().trim();
    final serverEnd = (rawUser['officeEndTime'] ?? '').toString().trim();

    final officeStart = _isHmFormat(serverStart)
        ? serverStart
        : (_isHmFormat(preferredStart)
              ? preferredStart
              : (_isHmFormat(cachedStart) ? cachedStart : '08:15'));
    final officeEnd = _isHmFormat(serverEnd)
        ? serverEnd
        : (_isHmFormat(preferredEnd)
              ? preferredEnd
              : (_isHmFormat(cachedEnd) ? cachedEnd : '18:00'));

    final normalized = Map<String, dynamic>.from(rawUser)
      ..['officeStartTime'] = officeStart
      ..['officeEndTime'] = officeEnd;

    await prefs.setString(_officeStartPrefsKey, officeStart);
    await prefs.setString(_officeEndPrefsKey, officeEnd);
    return normalized;
  }

  Future<void> _persistUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
    final officeStart = (user['officeStartTime'] ?? '').toString().trim();
    final officeEnd = (user['officeEndTime'] ?? '').toString().trim();
    if (_isHmFormat(officeStart)) {
      await prefs.setString(_officeStartPrefsKey, officeStart);
    }
    if (_isHmFormat(officeEnd)) {
      await prefs.setString(_officeEndPrefsKey, officeEnd);
    }
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
        if (data['user'] is Map<String, dynamic>) {
          final normalized = await _normalizeUser(
            data['user'] as Map<String, dynamic>,
          );
          data['user'] = normalized;
          await _persistUser(normalized);
        }
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
        final normalized = await _normalizeUser(
          data['user'] as Map<String, dynamic>,
        );
        data['user'] = normalized;
        await _persistUser(normalized);
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
    String? officeStartTime,
    String? officeEndTime,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name,
        'company': company,
        'designation': designation,
      };
      if (officeStartTime != null && officeStartTime.trim().isNotEmpty) {
        payload['officeStartTime'] = officeStartTime.trim();
      }
      if (officeEndTime != null && officeEndTime.trim().isNotEmpty) {
        payload['officeEndTime'] = officeEndTime.trim();
      }
      final response = await _client.put(
        '/auth/profile',
        data: payload,
      );
      final data = response.data as Map<String, dynamic>;
      if (data['user'] is Map<String, dynamic>) {
        final normalized = await _normalizeUser(
          data['user'] as Map<String, dynamic>,
          preferredOfficeStart: payload['officeStartTime']?.toString(),
          preferredOfficeEnd: payload['officeEndTime']?.toString(),
        );
        data['user'] = normalized;
        await _persistUser(normalized);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final cached = await getUser() ?? <String, dynamic>{};
        final merged = <String, dynamic>{
          ...cached,
          'name': name,
          'company': company,
          'designation': designation,
          if (payload['officeStartTime'] != null)
            'officeStartTime': payload['officeStartTime'],
          if (payload['officeEndTime'] != null)
            'officeEndTime': payload['officeEndTime'],
        };
        final normalized = await _normalizeUser(
          merged,
          preferredOfficeStart: payload['officeStartTime']?.toString(),
          preferredOfficeEnd: payload['officeEndTime']?.toString(),
        );
        data['user'] = normalized;
        await prefs.setString('user', jsonEncode(normalized));
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
      final response = await _client.put(
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
    if (userStr != null) {
      try {
        final decoded = jsonDecode(userStr);
        if (decoded is Map<String, dynamic>) {
          final normalized = await _normalizeUser(decoded);
          await _persistUser(normalized);
          return normalized;
        }
      } catch (_) {}
    }
    return null;
  }
}
