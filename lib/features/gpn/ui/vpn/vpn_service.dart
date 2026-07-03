/// VPN-движок: этап 2 — Hiddify libcore. Пока профиль готовится без автоподключения.
import 'package:flutter/foundation.dart';

enum VpnStatus { noProfile, profileReady, connecting, connected, error }

class VpnService extends ChangeNotifier {
  VpnService._();
  static final VpnService instance = VpnService._();

  VpnStatus _status = VpnStatus.noProfile;
  String? _profileUrl;
  String? _profileName;
  String? _error;

  VpnStatus get status => _status;
  String? get profileUrl => _profileUrl;
  String? get profileName => _profileName;
  String? get error => _error;
  bool get isConnected => _status == VpnStatus.connected;
  bool get hasProfile => _profileUrl != null && _profileUrl!.isNotEmpty;

  /// Импорт подписки в локальный профиль (без подключения VPN).
  Future<void> prepareProfile(String subscriptionUrl, {String name = 'GPN'}) async {
    final url = subscriptionUrl.trim();
    if (url.isEmpty) {
      _status = VpnStatus.noProfile;
      _profileUrl = null;
      notifyListeners();
      return;
    }
    _profileUrl = url;
    _profileName = name;
    _error = null;
    _status = VpnStatus.profileReady;
    notifyListeners();
    // TODO(hiddify): ProfileService.addProfile(url) через libcore
  }

  Future<void> connect() async {
    if (_profileUrl == null || _profileUrl!.isEmpty) {
      _status = VpnStatus.error;
      _error = 'Сначала нужен активный профиль';
      notifyListeners();
      return;
    }
    _status = VpnStatus.connecting;
    _error = null;
    notifyListeners();
  }

  /// Вызывается Hiddify-адаптером когда туннель поднят.
  void markConnected() {
    _status = VpnStatus.connected;
    notifyListeners();
  }

  void markConnectFailed(String message) {
    _status = VpnStatus.profileReady;
    _error = message;
    notifyListeners();
  }

  Future<void> disconnect() async {
    if (_profileUrl != null && _profileUrl!.isNotEmpty) {
      _status = VpnStatus.profileReady;
    } else {
      _status = VpnStatus.noProfile;
    }
    notifyListeners();
    // TODO(hiddify): CoreService.stop()
  }

  void reset() {
    _status = VpnStatus.noProfile;
    _profileUrl = null;
    _profileName = null;
    _error = null;
    notifyListeners();
  }
}
