// ignore_for_file: avoid_print
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:mobile/core/config/api_config.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(Supabase.instance.client);
});

final scanHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return await repo.fetchScanHistory();
});

class UserRepository {
  final SupabaseClient _supabase;

  UserRepository(this._supabase);

  Future<List<Map<String, dynamic>>> fetchScanHistory({int? limit}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    var query = _supabase
        .from('scan_history')
        .select('*, ingredients(parsed_json)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> clearScanHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    await _supabase
        .from('scan_history')
        .delete()
        .eq('user_id', user.id);
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    final Map<String, dynamic> userResponse = {
      'id': session.user.id,
      'email': session.user.email,
    };

    // 1. Fetch from public.users
    final userRow = await _supabase
        .from('users')
        .select('full_name, phone_number, age, blood_group, profile_image')
        .eq('id', session.user.id)
        .maybeSingle();

    if (userRow != null) {
      userResponse['full_name'] = userRow['full_name'];
      userResponse['phone_number'] = userRow['phone_number'];
      userResponse['age'] = userRow['age'];
      userResponse['blood_group'] = userRow['blood_group'];
      userResponse['profile_image'] = userRow['profile_image'];
    }

    // 2. Fetch from user_preferences
    final prefsResponse = await _supabase
        .from('user_preferences')
        .select('diets, allergies, health_goals')
        .eq('user_id', session.user.id)
        .maybeSingle();

    if (prefsResponse != null) {
      userResponse['diets'] = prefsResponse['diets'] ?? [];
      userResponse['allergies'] = prefsResponse['allergies'] ?? [];
      userResponse['health_goals'] = prefsResponse['health_goals'] ?? [];
    } else {
      userResponse['diets'] = [];
      userResponse['allergies'] = [];
      userResponse['health_goals'] = [];
    }

    return userResponse;
  }

  Future<void> updateHealthProfile({
    required String fullName,
    required String phoneNumber,
    required int age,
    required String bloodGroup,
    required String sugarLevel,
    required String bpLevel,
    required List<String> diets, 
    required List<String> allergies,
    required List<String> healthGoals,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // 1. Upsert public.users
    await _supabase.from('users').update({
      'full_name': fullName,
      'phone_number': phoneNumber,
      'age': age,
      'blood_group': bloodGroup,
      'sugar_level': sugarLevel,
      'bp_level': bpLevel,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);

    // 2. Upsert user_preferences
    await _supabase.from('user_preferences').upsert({
      'user_id': user.id,
      'diets': diets,
      'allergies': allergies,
      'health_goals': healthGoals,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateProfileImage(String imageUrl) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase.from('users').update({
      'profile_image': imageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);
  }

  Future<Map<String, dynamic>?> fetchWeeklySummary() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/user/summary/weekly');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching weekly summary: $e');
    }
    return null;
  }


}
