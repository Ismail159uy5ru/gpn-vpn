import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../api/gpn_client.dart';
import '../widgets/gpn_card.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.client});

  final GpnClient client;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List<GpnPlan> _plans = [];
  double _balance = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        widget.client.fetchPlans(),
        widget.client.fetchState(),
      ]);
      if (!mounted) return;
      setState(() {
        _plans = results[0] as List<GpnPlan>;
        _balance = (results[1] as GpnState).balanceRub;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _paySbp(GpnPlan plan) async {
    try {
      final url = await widget.client.createSbpPayment(plan.devices);
      if (!mounted || url.isEmpty) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _PayWebView(url: url)),
      );
      await _load();
    } on GpnApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _payBalance(GpnPlan plan) async {
    if (_balance < plan.priceRub) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Недостаточно средств на балансе')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Оплата с баланса'),
        content: Text(
          'Списать ${plan.priceRub.toStringAsFixed(0)} ₽ за ${plan.devices} устр. / 30 дн.?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Оплатить')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.client.payFromBalance(plan.devices);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Подписка активирована')),
      );
      await _load();
    } on GpnApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оплата'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GpnCard(
                  child: Text(
                    'Баланс: ${_balance.toStringAsFixed(2)} ₽',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Если СБП недоступен — используйте оплату с баланса.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ..._plans.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GpnCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${p.devices} устройств',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '${p.priceRub.toStringAsFixed(0)} ₽ / 30 дн.',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _balance >= p.priceRub
                                      ? () => _payBalance(p)
                                      : null,
                                  child: const Text('С баланса'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _paySbp(p),
                                  child: const Text('СБП'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PayWebView extends StatelessWidget {
  const _PayWebView({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оплата СБП'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
      body: WebViewWidget(controller: c),
    );
  }
}
