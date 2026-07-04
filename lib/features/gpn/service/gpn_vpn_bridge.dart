import 'package:dio/dio.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Импорт подписки GPN в профили Hiddify и connect/disconnect через ядро.
class GpnVpnBridge {
  GpnVpnBridge._();

  static Future<String?> importSubscription(WidgetRef ref, String url, {String? deviceId}) async {
    final trimmed = withDeviceId(url.trim(), deviceId);
    if (trimmed.isEmpty) return 'Нет ссылки подписки';

    final repo = ref.read(profileRepositoryProvider).requireValue;
    final result = await repo
        .upsertRemote(
          trimmed,
          userOverride: const UserOverride(name: 'GPN'),
          cancelToken: CancelToken(),
        )
        .run();

    if (result.isLeft()) {
      return 'Не удалось импортировать профиль. Проверьте лимит устройств в кабинете.';
    }

    final entry = await ref.read(profileDataSourceProvider).getByUrl(trimmed);
    if (entry != null) {
      await repo.setAsActive(entry.id).run();
    }
    return null;
  }

  /// Пробрасывает device_id в /subp для учёта слота устройства.
  static String withDeviceId(String url, String? deviceId) {
    final id = deviceId?.trim() ?? '';
    if (id.isEmpty || !url.contains('/subp/')) return url;
    final uri = Uri.parse(url);
    if (uri.queryParameters.containsKey('did')) return url;
    return uri.replace(queryParameters: {...uri.queryParameters, 'did': id}).toString();
  }

  static Future<void> connect(WidgetRef ref) async {
    await ref.read(Preferences.startedByUser.notifier).update(true);
    final conn = ref.read(connectionNotifierProvider);
    if (conn case AsyncData(:final value) when value.isDisconnected) {
      await ref.read(connectionNotifierProvider.notifier).toggleConnection();
    }
  }

  static Future<void> disconnect(WidgetRef ref) async {
    await ref.read(Preferences.startedByUser.notifier).update(false);
    final conn = ref.read(connectionNotifierProvider);
    if (conn case AsyncData(:final value) when value.isConnected) {
      await ref.read(connectionNotifierProvider.notifier).toggleConnection();
    }
  }

  static bool isConnected(WidgetRef ref) {
    final conn = ref.watch(connectionNotifierProvider);
    return conn.when(
      data: (s) => s.isConnected,
      loading: () => false,
      error: (_, _) => false,
    );
  }

  static bool isSwitching(WidgetRef ref) {
    final conn = ref.watch(connectionNotifierProvider);
    return conn.when(
      data: (s) => s.isSwitching,
      loading: () => true,
      error: (_, _) => false,
    );
  }

  static String? connectionError(WidgetRef ref) {
    final conn = ref.watch(connectionNotifierProvider);
    if (conn case AsyncData(:final value)) {
      if (value case Disconnected(:final connectionFailure?)) {
        return connectionFailure.toString();
      }
    }
    return null;
  }

  /// Пробрасывает device_id в /subp для учёта слота устройства.
  static String withDeviceId(String url, String? deviceId) {
    final id = deviceId?.trim() ?? '';
    if (id.isEmpty || !url.contains('/subp/')) return url;
    final uri = Uri.parse(url);
    if (uri.queryParameters.containsKey('did')) return url;
    return uri.replace(queryParameters: {...uri.queryParameters, 'did': id}).toString();
  }
}
