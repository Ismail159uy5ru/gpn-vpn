import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Кнопка VPN без диалогов и тяжёлых анимаций Hiddify.
class GpnConnectionButton extends ConsumerWidget {
  const GpnConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final conn = ref.watch(connectionNotifierProvider);
    final hasProfile = ref.watch(hasAnyProfileProvider).value ?? false;

    final status = conn.valueOrNull;
    final switching = status?.isSwitching ?? conn.isLoading;
    final connected = status?.isConnected ?? false;

    final color = connected
        ? const Color(0xFF22C55E)
        : hasProfile
            ? const Color(0xFF8B5CF6)
            : const Color(0xFF4B5563);

    String label;
    if (switching) {
      label = t.connection.connecting;
    } else if (connected) {
      label = t.connection.connected;
    } else if (hasProfile) {
      label = t.connection.connect;
    } else {
      label = 'Загрузите профиль';
    }

    Future<void> onTap() async {
      if (switching) return;
      if (!hasProfile) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сначала загрузите профиль подписки')),
        );
        return;
      }
      final wasConnected = connected;
      await ref.read(connectionNotifierProvider.notifier).toggleConnection();
      if (wasConnected) return;
    }

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: switching ? null : onTap,
            customBorder: const CircleBorder(),
            child: Ink(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
                border: Border.all(color: color, width: 3),
                boxShadow: hasProfile && !switching
                    ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 24)]
                    : null,
              ),
              child: Center(
                child: switching
                    ? SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(strokeWidth: 3, color: color),
                      )
                    : Icon(
                        connected ? Icons.power_settings_new : Icons.shield,
                        size: 56,
                        color: color,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
