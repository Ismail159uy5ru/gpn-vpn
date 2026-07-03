import 'package:flutter/material.dart';
import 'package:hiddify/features/gpn/service/gpn_vpn_bridge.dart';
import 'package:hiddify/features/gpn/ui/api/gpn_client.dart';
import 'package:hiddify/features/gpn/ui/widgets/gpn_background.dart';
import 'package:hiddify/features/gpn/ui/widgets/gpn_card.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GpnHomeScreen extends ConsumerStatefulWidget {
  const GpnHomeScreen({super.key, required this.client, required this.onLogout});

  final GpnClient client;
  final VoidCallback onLogout;

  @override
  ConsumerState<GpnHomeScreen> createState() => _GpnHomeScreenState();
}

class _GpnHomeScreenState extends ConsumerState<GpnHomeScreen> {
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
      if (st.hasActiveSub && st.subscriptionUrl.isNotEmpty) {
        final err = await GpnVpnBridge.importSubscription(ref, st.subscriptionUrl);
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

  Future<void> _toggleVpn() async {
    if (GpnVpnBridge.isConnected(ref)) {
      await GpnVpnBridge.disconnect(ref);
      return;
    }
    final url = _state?.subscriptionUrl ?? '';
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет профиля. Используйте аварийный доступ или купите подписку.')),
      );
      return;
    }
    final err = await GpnVpnBridge.importSubscription(ref, url);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    await GpnVpnBridge.connect(ref);
  }

  bool get _hasProfile => _state?.hasActiveSub == true && (_state?.subscriptionUrl.isNotEmpty ?? false);

  bool get _connected => GpnVpnBridge.isConnected(ref);

  bool get _connecting => GpnVpnBridge.isSwitching(ref);

  String get _profileLabel {
    if (_connected) return 'VPN включён';
    if (_hasProfile) return 'Профиль готов';
    if (_state?.hasActiveSub == true) return 'Подписка активна';
    return 'Нет подписки';
  }

  @override
  Widget build(BuildContext context) {
    final connErr = GpnVpnBridge.connectionError(ref);

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
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        GpnCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_profileLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              if (_hasProfile)
                                const Text('Импортирован в ядро VPN', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _VpnConnectButton(
                          connected: _connected,
                          connecting: _connecting,
                          ready: _hasProfile,
                          onTap: _toggleVpn,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _connected
                                ? 'Отключить'
                                : _hasProfile
                                    ? 'Подключить VPN'
                                    : 'Сначала получите профиль',
                            style: TextStyle(color: _hasProfile ? Colors.white70 : Colors.white38),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFF7C3AED), Color(0xFF6D28D9)]),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Подписка', style: TextStyle(color: Color(0xFFE9D5FF), fontSize: 12)),
                              Text(
                                '${_state?.daysLeft ?? 0} дней',
                                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _state?.hasActiveSub == true
                                    ? 'Профиль на сервере — VPN по желанию'
                                    : 'Оплата или аварийный доступ',
                                style: const TextStyle(color: Color(0xFFE9D5FF), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (_importError != null || connErr != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _importError ?? connErr ?? '',
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _VpnConnectButton extends StatelessWidget {
  const _VpnConnectButton({
    required this.connected,
    required this.connecting,
    required this.ready,
    required this.onTap,
  });

  final bool connected;
  final bool connecting;
  final bool ready;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = connected
        ? const Color(0xFF22C55E)
        : ready
            ? const Color(0xFF8B5CF6)
            : const Color(0xFF4B5563);
    return Center(
      child: GestureDetector(
        onTap: connecting || !ready ? null : onTap,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 3),
            boxShadow: ready ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 40, spreadRadius: 4)] : null,
          ),
          child: Center(
            child: connecting
                ? const CircularProgressIndicator()
                : Icon(connected ? Icons.power_settings_new : Icons.shield, size: 64, color: color),
          ),
        ),
      ),
    );
  }
}
