import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends StateNotifier<AsyncValue<String?>> {
  AuthController() : super(const AsyncValue.loading()) {
    loadUsername();
  }

  static const String _keyUsername = 'registered_username';

  Future<void> loadUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_keyUsername);
      state = AsyncValue.data(name);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> registerUsername(String name) async {
    state = const AsyncValue.loading();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUsername, name);
      state = AsyncValue.data(name);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateUsername(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUsername, name);
      state = AsyncValue.data(name);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> clearUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUsername);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final authProvider = StateNotifierProvider<AuthController, AsyncValue<String?>>((ref) {
  return AuthController();
});
