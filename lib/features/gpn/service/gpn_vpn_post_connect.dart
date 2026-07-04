import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// После импорта / подключения: выбрать первый сервер, запустить ping.
Future<void> gpnAfterProfileImported(WidgetRef ref) async {
  for (var i = 0; i < 40; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (ref.read(connectionNotifierProvider).valueOrNull?.isConnected == true) break;
  }
  if (ref.read(connectionNotifierProvider).valueOrNull?.isConnected != true) return;

  final proxyRepo = ref.read(proxyRepositoryProvider);
  final either = await proxyRepo.watchProxies().first;
  await either.fold((_) async {}, (group) async {
    if (group == null) return;
    final server = group.items.where((e) => !e.isGroup).firstOrNull;
    if (server != null) {
      await proxyRepo.selectProxy(group.tag, server.tag).run();
    }
  });

  for (var attempt = 0; attempt < 3; attempt++) {
    await Future<void>.delayed(Duration(milliseconds: 600 + attempt * 800));
    try {
      await ref.read(activeProxyNotifierProvider.notifier).urlTest('');
      await ref.read(proxiesOverviewNotifierProvider.notifier).urlTest('');
    } catch (_) {}
  }
}
