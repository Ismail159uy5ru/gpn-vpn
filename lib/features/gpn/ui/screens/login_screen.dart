import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hiddify/features/gpn/ui/services/device_id_store.dart';
import 'package:hiddify/features/gpn/ui/widgets/gpn_background.dart';

typedef GpnLoggedInCallback = void Function(
  String token, {
  int? telegramId,
  String? subscriptionUrl,
});

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLoggedIn,
    this.title = 'Вход через Telegram',
  });

  final GpnLoggedInCallback onLoggedIn;
  final String title;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinController = TextEditingController();
  final _deviceId = DeviceIdStore();
  bool _busy = false;
  String? _error;
  String? _botUsername;

  @override
  void initState() {
    super.initState();
    _loadBotUsername();
  }

  Future<void> _loadBotUsername() async {
    try {
      final name = await GpnClient().fetchBotUsername();
      if (mounted) setState(() => _botUsername = name);
    } catch (_) {}
  }

  String get _code => _pinController.text.trim();

  Future<void> _login() async {
    if (_code.length != 6) {
      setState(() => _error = 'Введите 6 цифр из бота');
      return;
    }
    await _finishAuth((c) => c.loginWithCode(_code));
  }

  Future<void> _finishAuth(
    Future<GpnAuthSession> Function(GpnClient) call,
  ) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await _deviceId.getOrCreate();
      final session = await call(GpnClient(deviceId: id));
      if (session.token.isEmpty) throw Exception('empty');
      final sub = session.subscriptionUrl ?? '';
      widget.onLoggedIn(
        session.token,
        telegramId: session.telegramId,
        subscriptionUrl: sub.isNotEmpty ? sub : null,
      );
    } on GpnApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Не удалось. Запросите новый код в боте.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openTelegram({required String start}) async {
    final user = _botUsername;
    if (user == null || user.isEmpty) {
      setState(() => _error = 'Не удалось открыть бота');
      return;
    }
    await launchUrl(Uri.parse('https://t.me/$user?start=$start'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GpnBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const _BrandTitle(),
                const SizedBox(height: 8),
                Text(widget.title, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 32),
                Pinput(
                  controller: _pinController,
                  length: 6,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  defaultPinTheme: PinTheme(
                    width: 48,
                    height: 56,
                    textStyle: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0B2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x668B5CF6)),
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    width: 48,
                    height: 56,
                    textStyle: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1540),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
                    ),
                  ),
                  onCompleted: (_) => _login(),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _login,
                    child: _busy
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Войти'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _openTelegram(start: 'app_login'),
                    icon: const Icon(Icons.telegram),
                    label: const Text('Получить код в Telegram'),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        children: [
          TextSpan(text: 'GPN', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          TextSpan(text: 'VPN', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
        ],
      ),
    );
  }
}
