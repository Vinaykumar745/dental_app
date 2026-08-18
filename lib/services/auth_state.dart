import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  static String? _token;
  static String? _userName;
  static String? _userEmail;
  static String? _avatarPath;
  static int? _userAge;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _userName = prefs.getString('user_name');
    _userEmail = prefs.getString('user_email');
    _avatarPath = prefs.getString('avatar_path');
    _userAge = prefs.getInt('user_age');
  }

  static String? get token => _token;
  static String? get userName => _userName ?? 'Doctor';
  static String? get userEmail => _userEmail ?? '';
  static String? get avatarPath => _avatarPath;
  static int get userAge => _userAge ?? 0;
  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  static Future<void> clear() async {
    _token = null;
    _userName = null;
    _userEmail = null;
    _avatarPath = null;
    _userAge = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> save({
    required String token,
    required String name,
    required String email,
  }) async {
    _token = token;
    _userName = name;
    _userEmail = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
  }

  static Future<void> updateAvatar(String path) async {
    _avatarPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar_path', path);
  }
}
