import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Стабильный ID установки — одна учётка на устройство до привязки Telegram.
class DeviceIdStore {
  static const _key = 'gpn_device_id';

  Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_key, id);
    }
    return id;
  }
}
