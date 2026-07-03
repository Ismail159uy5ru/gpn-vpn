import 'package:flutter/material.dart';
import 'package:hiddify/features/gpn/service/gpn_vpn_bridge.dart';
import 'package:hiddify/features/gpn/ui/api/gpn_client.dart';
import 'package:hiddify/features/gpn/ui/screens/gpn_shell.dart';
import 'package:hiddify/features/gpn/ui/screens/login_screen.dart';
import 'package:hiddify/features/gpn/ui/services/session_store.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Вход 6 цифр → личный кабинет (общий с ботом).
class GpnRoot extends ConsumerStatefulWidget {
  const GpnRoot({super.key});

  @override
  ConsumerState<GpnRoot> createState() => _GpnRootState();
}

class _GpnRootState extends ConsumerState<GpnRoot> {
  final _session = SessionStore();
  String? _token;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final token = await _session.loadToken();
    if (!mounted) return;
    setState(() {
      _token = token;
      _loading = false;
    });
  }

  Future<void> _onLoggedIn(
    String token, {
    int? telegramId,
    String? subscriptionUrl,
  }) async {
    await _session.saveToken(token, telegramId: telegramId);
    if (subscriptionUrl != null && subscriptionUrl.isNotEmpty) {
      await GpnVpnBridge.importSubscription(ref, subscriptionUrl);
    }
    if (!mounted) return;
    setState(() => _token = token);
  }

  Future<void> _logout() async {
    await GpnVpnBridge.disconnect(ref);
    await _session.clear();
    if (!mounted) return;
    setState(() => _token = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_token == null || _token!.isEmpty) {
      return LoginScreen(onLoggedIn: _onLoggedIn);
    }
    return GpnShell(
      client: GpnClient(appToken: _token),
      onLogout: _logout,
    );
  }
}
