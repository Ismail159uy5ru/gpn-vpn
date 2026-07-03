import 'package:shared_preferences/shared_preferences.dart';

/// Режим сессии: полный кабинет или только аварийный VPN.
enum GpnSessionKind { cabinet, emergency }

class SessionStore {
  static const _tokenKey = 'gpn_app_token';
  static const _tgIdKey = 'gpn_telegram_id';
  static const _kindKey = 'gpn_session_kind';
  static const _emergencyUrlKey = 'gpn_emergency_url';

  Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_tokenKey);
    if (t == null || t.isEmpty) return null;
    return t;
  }

  Future<GpnSessionKind> loadKind() async {
    final prefs = await SharedPreferences.getInstance();
    final k = prefs.getString(_kindKey);
    if (k == 'emergency') return GpnSessionKind.emergency;
    return GpnSessionKind.cabinet;
  }

  Future<void> saveToken(
    String token, {
    int? telegramId,
    GpnSessionKind kind = GpnSessionKind.cabinet,
    String? emergencyUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_kindKey, kind == GpnSessionKind.emergency ? 'emergency' : 'cabinet');
    if (telegramId != null && telegramId > 0) {
      await prefs.setInt(_tgIdKey, telegramId);
    }
    if (emergencyUrl != null && emergencyUrl.isNotEmpty) {
      await prefs.setString(_emergencyUrlKey, emergencyUrl);
    } else if (kind != GpnSessionKind.emergency) {
      await prefs.remove(_emergencyUrlKey);
    }
  }

  Future<String?> loadEmergencyUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final u = prefs.getString(_emergencyUrlKey);
    if (u == null || u.isEmpty) return null;
    return u;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tgIdKey);
    await prefs.remove(_kindKey);
    await prefs.remove(_emergencyUrlKey);
  }

  Future<int?> loadTelegramId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_tgIdKey);
    if (id == null || id <= 0) return null;
    return id;
  }
}
