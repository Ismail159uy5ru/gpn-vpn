import 'dart:io';
import 'package:flutter/services.dart';
import 'vpn_service.dart';

/// Встроенный VPN через hiddify-core (MethodChannel на Android).
/// Без внешнего приложения Hiddify.
class HiddifyRunner {
  HiddifyRunner._();
  static final HiddifyRunner instance = HiddifyRunner._();

  static const _channel = MethodChannel('space.giga.gpn/vpn');

  Future<void> connectProfile(String subscriptionUrl) async {
    final vpn = VpnService.instance;
    final url = subscriptionUrl.trim();
    if (url.isEmpty) {
      vpn.markConnectFailed('Нет ссылки подписки');
      return;
    }

    await vpn.prepareProfile(url);
    await vpn.connect();

    if (!Platform.isAndroid) {
      vpn.markConnectFailed('Встроенный VPN только в Android APK');
      return;
    }

    try {
      final ok = await _channel.invokeMethod<bool>('connect', {'url': url, 'name': 'GPN'});
      if (ok == true) {
        vpn.markConnected();
      } else {
        vpn.markConnectFailed('Не удалось запустить VPN');
      }
    } on PlatformException catch (e) {
      vpn.markConnectFailed(e.message ?? 'VPN ошибка');
    } catch (e) {
      vpn.markConnectFailed('Нативный VPN ещё подключается (сборка из форка hiddify)');
    }
  }

  Future<void> disconnect() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('disconnect');
      } catch (_) {}
    }
    await VpnService.instance.disconnect();
  }
}
