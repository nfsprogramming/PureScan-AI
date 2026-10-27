// ignore_for_file: avoid_print
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsState {
  final String clinicalThreshold;
  final bool alertsEnabled;
  final bool dailyDigestEnabled;

  SettingsState({
    required this.clinicalThreshold,
    required this.alertsEnabled,
    required this.dailyDigestEnabled,
  });

  SettingsState copyWith({
    String? clinicalThreshold,
    bool? alertsEnabled,
    bool? dailyDigestEnabled,
  }) {
    return SettingsState(
      clinicalThreshold: clinicalThreshold ?? this.clinicalThreshold,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      dailyDigestEnabled: dailyDigestEnabled ?? this.dailyDigestEnabled,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadSettings();
    return SettingsState(
      clinicalThreshold: 'Medium',
      alertsEnabled: true,
      dailyDigestEnabled: false,
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      clinicalThreshold: prefs.getString('clinicalThreshold') ?? 'Medium',
      alertsEnabled: prefs.getBool('alertsEnabled') ?? true,
      dailyDigestEnabled: prefs.getBool('dailyDigestEnabled') ?? false,
    );
  }

  Future<void> updateClinicalThreshold(String threshold) async {
    state = state.copyWith(clinicalThreshold: threshold);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('clinicalThreshold', threshold);
  }

  Future<void> toggleAlerts(bool value) async {
    state = state.copyWith(alertsEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alertsEnabled', value);
    _syncToSupabase('alerts_enabled', value);
  }

  Future<void> toggleDailyDigest(bool value) async {
    state = state.copyWith(dailyDigestEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dailyDigestEnabled', value);
    _syncToSupabase('daily_digest_enabled', value);
  }

  Future<void> _syncToSupabase(String column, bool value) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    try {
      await Supabase.instance.client
          .from('user_preferences')
          .update({column: value})
          .eq('user_id', session.user.id);
    } catch (e) {
      print('Failed to sync setting to Supabase: $e');
    }
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
