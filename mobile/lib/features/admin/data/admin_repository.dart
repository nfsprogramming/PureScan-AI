// ignore_for_file: avoid_print
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:mobile/core/config/api_config.dart';

sealed class AdminResult<T> {
  const AdminResult();
}

class AdminSuccess<T> extends AdminResult<T> {
  final T data;
  const AdminSuccess(this.data);
}

class AdminAuthenticationRequired<T> extends AdminResult<T> {
  const AdminAuthenticationRequired();
}

class AdminUnauthorized<T> extends AdminResult<T> {
  const AdminUnauthorized();
}

class AdminNetworkError<T> extends AdminResult<T> {
  final String message;
  const AdminNetworkError(this.message);
}

class AdminDatabaseError<T> extends AdminResult<T> {
  final String message;
  final String? code;
  const AdminDatabaseError(this.message, {this.code});
}

class AdminUnknownError<T> extends AdminResult<T> {
  final String message;
  const AdminUnknownError(this.message);
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

class AdminRepository {
  String get _baseUrl => ApiConfig.baseUrl;

  Future<AdminResult<Map<String, dynamic>>> fetchStats() async {
    print('\nADMIN_DEBUG:\nfetchStats() started');
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session == null) {
      print('ADMIN_DEBUG:\nauthenticated = false');
      return const AdminAuthenticationRequired();
    }

    print('ADMIN_DEBUG:\nauthenticated = true');
    print('ADMIN_DEBUG:\nuserId = ${session.user.id}');
    print('ADMIN_DEBUG:\ndatabase request started');
    print('ADMIN_DEBUG:\nEndpoint: $_baseUrl/api/v1/admin/stats');

    final url = Uri.parse('$_baseUrl/api/v1/admin/stats');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      ).timeout(const Duration(seconds: 10));

      print('ADMIN_DEBUG:\nHTTP status = ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('ADMIN_DEBUG:\nSuccessful response');
        return AdminSuccess(data);
      } else if (response.statusCode == 401) {
        return const AdminAuthenticationRequired();
      } else if (response.statusCode == 403) {
        return const AdminUnauthorized();
      } else if (response.statusCode >= 500) {
        print('ADMIN_DEBUG:\ndatabase request failed with 500+ error\nmessage = ${response.body}');
        return AdminDatabaseError('Server error: ${response.statusCode}');
      } else {
        return AdminUnknownError('Unexpected status code: ${response.statusCode}');
      }
    } catch (e, stacktrace) {
      print('ADMIN_DEBUG:\ndatabase request failed');
      print('ADMIN_DEBUG:\nexception = $e');
      print('ADMIN_DEBUG:\nstacktrace = $stacktrace');
      
      if (e.toString().contains('TimeoutException') || e.toString().contains('SocketException')) {
        return AdminNetworkError(e.toString());
      }
      return AdminUnknownError(e.toString());
    }
  }

  Future<AdminResult<List<dynamic>>> fetchSubmissions() async {
    print('\nADMIN_DEBUG:\nfetchSubmissions() started');
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session == null) {
      print('ADMIN_DEBUG:\nauthenticated = false');
      return const AdminAuthenticationRequired();
    }

    print('ADMIN_DEBUG:\nauthenticated = true');
    print('ADMIN_DEBUG:\nuserId = ${session.user.id}');
    print('ADMIN_DEBUG:\ndatabase request started');
    print('ADMIN_DEBUG:\nEndpoint: $_baseUrl/api/v1/admin/submissions');

    final url = Uri.parse('$_baseUrl/api/v1/admin/submissions');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      ).timeout(const Duration(seconds: 10));

      print('ADMIN_DEBUG:\nHTTP status = ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded == null ? [] : decoded as List<dynamic>;
        print('ADMIN_DEBUG:\nSuccessful response\nNumber of records returned: ${list.length}');
        return AdminSuccess(list);
      } else if (response.statusCode == 401) {
        return const AdminAuthenticationRequired();
      } else if (response.statusCode == 403) {
        return const AdminUnauthorized();
      } else if (response.statusCode >= 500) {
        print('ADMIN_DEBUG:\ndatabase request failed with 500+ error\nmessage = ${response.body}');
        return AdminDatabaseError('Server error: ${response.statusCode}');
      } else {
        return AdminUnknownError('Unexpected status code: ${response.statusCode}');
      }
    } catch (e, stacktrace) {
      print('ADMIN_DEBUG:\ndatabase request failed');
      print('ADMIN_DEBUG:\nexception = $e');
      print('ADMIN_DEBUG:\nstacktrace = $stacktrace');
      
      if (e.toString().contains('TimeoutException') || e.toString().contains('SocketException')) {
        return AdminNetworkError(e.toString());
      }
      return AdminUnknownError(e.toString());
    }
  }

  Future<bool> approveSubmission(String id, String newName) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return false;

    final url = Uri.parse('$_baseUrl/api/v1/admin/submissions/$id/approve');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'product_name': newName,
        }),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print('Error approving: $e');
      return false;
    }
  }

  Future<bool> rejectSubmission(String id) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return false;

    final url = Uri.parse('$_baseUrl/api/v1/admin/submissions/$id/reject');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print('Error rejecting: $e');
      return false;
    }
  }
}
