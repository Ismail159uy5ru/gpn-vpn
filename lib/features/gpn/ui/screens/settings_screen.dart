import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/features/gpn/service/gpn_vpn_bridge.dart';
import 'package:hiddify/features/gpn/ui/api/gpn_client.dart';
import 'package:hiddify/features/gpn/ui/widgets/gpn_background.dart';
import 'package:hiddify/features/gpn/ui/widgets/gpn_card.dart';
import 'package:hiddify/features/settings/overview/settings_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, required this.client});

  final GpnClient client;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  GpnState? _state;
  GpnEmergencyStatus? _emergency;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        widget.client.fetchState(),
        widget.client.fetchEmergencyStatus(),
      ]);
      if (!mounted) return;
      setState(() {
        _state = results[0] as GpnState;
        _emergency = results[1] as GpnEmergencyStatus;
      });
    } catch (_) {
      if (mounted) setState(() => _state = null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copyUrl() async {
    final url = _state?.subscriptionUrl ?? '';
    if (url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ссылка скопирована')));
  }

  Future<void> _requestEmergency() async {
    try {
      final session = await widget.client.requestEmergency();
      final sub = session.subscriptionUrl ?? '';
      if (sub.isNotEmpty) {
        await GpnVpnBridge.importSubscription(ref, sub);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль на 1 ч создан (VPN не включался)')),
      );
      await _load();
    } on GpnApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _openAdvancedVpnSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = _state?.subscriptionUrl ?? '';
    return GpnBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Настройки'),
          actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Профиль подписки', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GpnCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SelectableText(
                          url.isEmpty ? 'Нет активной подписки' : url,
                          style: TextStyle(color: url.isEmpty ? Colors.white54 : Colors.white, fontSize: 12),
                        ),
                        if (url.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _copyUrl,
                            icon: const Icon(Icons.copy),
                            label: const Text('Копировать ссылку'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (url.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(data: url, size: 200),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text('Аварийный доступ', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GpnCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('1 час VPN, не чаще раза в сутки', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: (_emergency?.canIssue ?? false) ? _requestEmergency : null,
                          child: const Text('🆘 Аварийный доступ'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Расширенные настройки VPN', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GpnCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'DNS, маршрутизация, режим туннеля, per-app proxy — как в Hiddify.',
                          style: TextStyle(color: Colors.white54, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _openAdvancedVpnSettings,
                          icon: const Icon(Icons.tune),
                          label: const Text('Открыть настройки VPN'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
