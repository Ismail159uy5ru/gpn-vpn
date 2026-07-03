import 'package:flutter/material.dart';
import 'package:hiddify/features/gpn/ui/api/gpn_client.dart';
import 'package:hiddify/features/gpn/ui/screens/login_screen.dart';
import 'package:hiddify/features/gpn/ui/services/device_id_store.dart';
import 'package:hiddify/features/gpn/ui/services/session_store.dart';
import 'package:hiddify/features/gpn/ui/widgets/gpn_background.dart';
import 'package:url_launcher/url_launcher.dart';

typedef WelcomeLoggedInCallback = void Function(
  String token, {
  int? telegramId,
  String? subscriptionUrl,
  GpnSessionKind kind,
});

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onLoggedIn});

  final WelcomeLoggedInCallback onLoggedIn;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _deviceId = DeviceIdStore();
  GpnAppInfo? _info;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      final info = await GpnClient().fetchAppInfo();
      if (mounted) setState(() => _info = info);
    } catch (_) {}
  }

  Future<GpnClient> _client() async {
    final id = await _deviceId.getOrCreate();
    return GpnClient(deviceId: id);
  }

  Future<void> _trial() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await (await _client()).startTrial();
      widget.onLoggedIn(
        session.token,
        telegramId: session.telegramId,
        subscriptionUrl: session.subscriptionUrl,
        kind: GpnSessionKind.cabinet,
      );
    } on GpnApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Не удалось активировать пробный период');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _emergency() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await (await _client()).startEmergencyGuest();
      widget.onLoggedIn(
        session.token,
        telegramId: session.telegramId,
        subscriptionUrl: session.subscriptionUrl,
        kind: GpnSessionKind.emergency,
      );
    } on GpnApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Не удалось создать аварийный профиль');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _subscription() async {
    final has = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подписка'),
        content: const Text('Имеется активная подписка?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Нет')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Да')),
        ],
      ),
    );
    if (!mounted || has == null) return;

    if (has) {
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (ctx) => LoginScreen(
            title: 'Вход в подписку',
            onLoggedIn: (token, {telegramId, subscriptionUrl}) {
              Navigator.of(ctx).pop();
              widget.onLoggedIn(
                token,
                telegramId: telegramId,
                subscriptionUrl: subscriptionUrl,
                kind: GpnSessionKind.cabinet,
              );
            },
          ),
        ),
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await (await _client()).register();
      widget.onLoggedIn(
        session.token,
        telegramId: session.telegramId,
        kind: GpnSessionKind.cabinet,
      );
    } on GpnApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Не удалось создать учётку');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final trialDays = _info?.trialDays ?? 2;

    return GpnBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                const _BrandTitle(),
                const SizedBox(height: 8),
                const Text('Выберите способ входа', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 12),
                ],
                _MainButton(
                  onPressed: _busy ? null : _trial,
                  icon: Icons.card_giftcard,
                  label: 'Пробный период',
                  subtitle: '$trialDays дня бесплатно',
                ),
                const SizedBox(height: 12),
                _MainButton(
                  onPressed: _busy ? null : _subscription,
                  icon: Icons.verified_user_outlined,
                  label: 'Подписка',
                  subtitle: 'Есть подписка или купить',
                ),
                const SizedBox(height: 12),
                _MainButton(
                  onPressed: _busy ? null : _emergency,
                  icon: Icons.emergency_outlined,
                  label: 'Аварийный вход',
                  subtitle: '1 час VPN',
                  outlined: true,
                ),
                if (_busy) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
                const Spacer(),
                const Text('Контакты', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if ((_info?.vkUrl ?? '').isNotEmpty)
                      TextButton.icon(
                        onPressed: () => _openUrl(_info!.vkUrl),
                        icon: const Icon(Icons.groups_outlined, size: 20),
                        label: const Text('VK'),
                      ),
                    if ((_info?.telegramUrl ?? '').isNotEmpty)
                      TextButton.icon(
                        onPressed: () => _openUrl(_info!.telegramUrl),
                        icon: const Icon(Icons.telegram, size: 20),
                        label: const Text('Поддержка'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MainButton extends StatelessWidget {
  const _MainButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.subtitle,
    this.outlined = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final String subtitle;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8B5CF6)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );

    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0x668B5CF6)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2A1540),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: child,
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        children: [
          TextSpan(text: 'GPN', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
          TextSpan(text: 'VPN', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
        ],
      ),
    );
  }
}
