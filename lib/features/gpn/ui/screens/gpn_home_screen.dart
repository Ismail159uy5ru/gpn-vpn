import 'package:flutter/material.dart';
import 'package:hiddify/features/gpn/service/gpn_vpn_bridge.dart';
import 'package:hiddify/features/gpn/ui/api/gpn_client.dart';
import 'package:hiddify/features/gpn/ui/services/device_id_store.dart';
import 'package:hiddify/features/gpn/ui/widgets/gpn_background.dart';
import 'package:hiddify/features/gpn/ui/widgets/gpn_card.dart';
import 'package:hiddify/features/gpn/ui/widgets/gpn_connection_button.dart';
import 'package:hiddify/features/gpn/ui/widgets/gpn_proxy_footer.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GpnHomeScreen extends ConsumerStatefulWidget {
  const GpnHomeScreen({super.key, required this.client, required this.onLogout});

  final GpnClient client;
  final VoidCallback onLogout;

  @override
  ConsumerState<GpnHomeScreen> createState() => _GpnHomeScreenState();
}

class _GpnHomeScreenState extends ConsumerState<GpnHomeScreen> {
  final _deviceId = DeviceIdStore();
  GpnState? _state;
  bool _loading = true;
  String? _error;
  String? _importError;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
      _importError = null;
    });
    try {
      final st = await widget.client.fetchState();
      if (!mounted) return;
      setState(() => _state = st);
      final url = st.subscriptionUrl.trim();
      if (url.isNotEmpty) {
        final did = await _deviceId.getOrCreate();
        final err = await GpnVpnBridge.importSubscription(ref, url, deviceId: did);
        if (!mounted) return;
        if (err != null) setState(() => _importError = err);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Не удалось загрузить данные');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _importProfile() async {
    final url = _state?.subscriptionUrl.trim() ?? '';
    if (url.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет ссылки подписки. Оформите trial или подписку.')),
      );
      return;
    }
    setState(() => _importError = null);
    final did = await _deviceId.getOrCreate();
    final err = await GpnVpnBridge.importSubscription(ref, url, deviceId: did);
    if (!mounted) return;
    if (err != null) {
      setState(() => _importError = err);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль обновлён')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasProfile = ref.watch(hasAnyProfileProvider).value ?? false;
    final activeProfile = ref.watch(activeProfileProvider);

    return GpnBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: RichText(
            text: const TextSpan(
              children: [
                TextSpan(text: 'GPN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                TextSpan(text: 'VPN', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
              ],
            ),
          ),
          actions: [
            if (_state != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Text(
                    '${_state!.balanceRub.toStringAsFixed(0)} ₽',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ),
            IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
            IconButton(onPressed: widget.onLogout, icon: const Icon(Icons.logout)),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _reload, child: const Text('Повторить')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        GpnCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _state?.hasActiveSub == true ? 'Подписка активна' : 'Нет активной подписки',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${_state?.daysLeft ?? 0} дн. · профиль ${hasProfile ? "загружен" : "не загружен"}',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                              if (!hasProfile && (_state?.subscriptionUrl.isNotEmpty ?? false)) ...[
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: _importProfile,
                                  icon: const Icon(Icons.download),
                                  label: const Text('Загрузить профиль'),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Center(child: GpnConnectionButton()),
                        const SizedBox(height: 8),
                        const Center(child: ActiveProxyDelayIndicator()),
                        const SizedBox(height: 24),
                        const GpnProxyFooter(),
                        if (_importError != null) ...[
                          const SizedBox(height: 12),
                          Text(_importError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ],
                        if (activeProfile case AsyncError(:final error)) ...[
                          const SizedBox(height: 12),
                          Text(error.toString(), style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}
