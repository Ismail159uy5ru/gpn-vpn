import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _tokenKey = 'gpn_app_token';
  static const _tgIdKey = 'gpn_telegram_id';

  Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_tokenKey);
    if (t == null || t.isEmpty) return null;
    return t;
  }

  Future<void> saveToken(String token, {int? telegramId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (telegramId != null && telegramId > 0) {
      await prefs.setInt(_tgIdKey, telegramId);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tgIdKey);
  }

  Future<int?> loadTelegramId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_tgIdKey);
    if (id == null || id <= 0) return null;
    return id;
  }
}
