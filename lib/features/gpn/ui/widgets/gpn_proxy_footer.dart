import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/gpn/ui/screens/gpn_proxies_screen.dart';
import 'package:hiddify/features/gpn/ui/widgets/gpn_proxy_label.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Выбор сервера — как в Hiddify, без GoRouter.
class GpnProxyFooter extends ConsumerWidget {
  const GpnProxyFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(
      connectionNotifierProvider.select((value) => value.valueOrNull ?? const Disconnected()),
    );
    final activeProxy = ref.watch(activeProxyNotifierProvider.select((value) => value.valueOrNull));
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    return Material(
      color: const Color(0xFF1A0B2E),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const GpnProxiesScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.public, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connectionState == const Connected() && activeProxy != null
                          ? gpnProxyDisplayName(activeProxy.tagDisplay)
                          : 'Выбрать сервер',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      connectionState == const Connected() && activeProxy != null
                          ? (activeProxy.ipinfo.ip.isNotEmpty ? activeProxy.ipinfo.ip : activeProxy.type)
                          : t.pages.proxies.title,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}
