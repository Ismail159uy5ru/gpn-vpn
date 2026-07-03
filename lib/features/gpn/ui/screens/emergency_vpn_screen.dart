import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/features/gpn/service/gpn_vpn_bridge.dart';
import 'package:hiddify/features/gpn/ui/widgets/gpn_background.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Простой VPN-экран (как Hiddify): URL/QR + кнопка включения.
class EmergencyVpnScreen extends ConsumerStatefulWidget {
  const EmergencyVpnScreen({
    super.key,
    required this.initialUrl,
    required this.onExit,
  });

  final String initialUrl;
  final VoidCallback onExit;

  @override
  ConsumerState<EmergencyVpnScreen> createState() => _EmergencyVpnScreenState();
}

class _EmergencyVpnScreenState extends ConsumerState<EmergencyVpnScreen> {
  late final TextEditingController _urlCtrl;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.initialUrl);
    if (widget.initialUrl.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _import(widget.initialUrl));
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _import(String url) async {
    final err = await GpnVpnBridge.importSubscription(ref, url);
    if (!mounted) return;
    setState(() => _error = err);
  }

  Future<void> _toggleVpn() async {
    if (GpnVpnBridge.isConnected(ref)) {
      await GpnVpnBridge.disconnect(ref);
      setState(() {});
      return;
    }
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Вставьте ссылку или отсканируйте QR');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await GpnVpnBridge.importSubscription(ref, url);
    if (err != null) {
      if (mounted) setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    await GpnVpnBridge.connect(ref);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _scanQr() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _QrScanPage()),
    );
    if (code == null || code.isEmpty || !mounted) return;
    _urlCtrl.text = code;
    await _import(code);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final connected = GpnVpnBridge.isConnected(ref);
    final switching = GpnVpnBridge.isSwitching(ref) || _busy;

    return GpnBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Аварийный VPN'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await GpnVpnBridge.disconnect(ref);
              widget.onExit();
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Профиль на 1 час. Вставьте ссылку или отсканируйте QR.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'https://...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1A0B2E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _scanQr,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('QR'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final t = _urlCtrl.text.trim();
                        if (t.isEmpty) return;
                        await Clipboard.setData(ClipboardData(text: t));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Скопировано')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Копировать'),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: switching ? null : _toggleVpn,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (connected ? const Color(0xFF22C55E) : const Color(0xFF8B5CF6)).withValues(alpha: 0.15),
                    border: Border.all(
                      color: connected ? const Color(0xFF22C55E) : const Color(0xFF8B5CF6),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: switching
                        ? const CircularProgressIndicator()
                        : Icon(
                            connected ? Icons.power_settings_new : Icons.shield,
                            size: 56,
                            color: connected ? const Color(0xFF22C55E) : const Color(0xFF8B5CF6),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                connected ? 'Отключить' : 'Включить VPN',
                style: const TextStyle(color: Colors.white70),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrScanPage extends StatelessWidget {
  const _QrScanPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сканировать QR')),
      body: MobileScanner(
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          for (final b in barcodes) {
            final raw = b.rawValue;
            if (raw != null && raw.isNotEmpty) {
              Navigator.of(context).pop(raw);
              return;
            }
          }
        },
      ),
    );
  }
}
