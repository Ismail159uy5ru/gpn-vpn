import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/gpn_client.dart';
import '../widgets/gpn_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.client,
    required this.onLogout,
  });

  final GpnClient client;
  final VoidCallback onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GpnState? _state;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final st = await widget.client.fetchState();
      if (!mounted) return;
      setState(() => _state = st);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Не удалось загрузить данные');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _activateVpn() async {
    final url = _state?.subscriptionUrl ?? '';
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет активной подписки')),
      );
      return;
    }
    final bridge = Uri.parse(
      '${widget.client.baseUrl}/hiddify/open?url=${Uri.encodeComponent(url)}&name=GPN',
    );
    await launchUrl(bridge, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPN VPN'),
        actions: [
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
                            Text(
                              _state!.hasActiveSub
                                  ? '${_state!.daysLeft} дней'
                                  : 'Нет подписки',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Баланс: ${_state!.balanceRub.toStringAsFixed(2)} ₽',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Устройства: ${_state!.deviceSlotsUsed} / ${_state!.deviceSlotsMax}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _state!.hasActiveSub ? _activateVpn : null,
                        icon: const Icon(Icons.shield),
                        label: const Text('Подключить VPN'),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Оплата и устройства — во вкладках внизу. '
                        'Встроенный VPN (форк Hiddify) — вкладка VPN.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
    );
  }
}
