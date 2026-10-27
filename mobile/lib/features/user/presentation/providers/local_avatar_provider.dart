import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class LocalAvatarNotifier extends Notifier<String?> {
  static const _key = 'local_avatar_path';

  @override
  String? build() {
    _loadLocalAvatar();
    return null; // Initial state while loading
  }

  Future<void> _loadLocalAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(_key);
      if (path != null && File(path).existsSync()) {
        state = path;
      } else {
        state = null;
      }
    } catch (_) {
      state = null;
    }
  }

  Future<void> saveLocalAvatar(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      // Use a stable filename to prevent clutter
      final localPath = '${directory.path}/profile_image.jpg';
      
      final savedFile = await imageFile.copy(localPath);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, savedFile.path);
      
      // Update state so UI reflects immediately
      state = savedFile.path;
    } catch (e) {
      // Ignore errors but print
      print("Failed to save local avatar: $e");
    }
  }

  Future<void> clearLocalAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(_key);
      if (path != null) {
        final file = File(path);
        if (file.existsSync()) {
          await file.delete();
        }
      }
      await prefs.remove(_key);
      state = null;
    } catch (_) {}
  }
}

final localAvatarProvider = NotifierProvider<LocalAvatarNotifier, String?>(() {
  return LocalAvatarNotifier();
});
