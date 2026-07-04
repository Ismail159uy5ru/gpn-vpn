import 'package:flutter/material.dart';
import 'package:hiddify/features/gpn/service/gpn_profile_import.dart';
import 'package:hiddify/features/gpn/service/gpn_vpn_bridge.dart';
import 'package:hiddify/features/gpn/ui/api/gpn_client.dart';
import 'package:hiddify/features/gpn/ui/screens/emergency_vpn_screen.dart';
import 'package:hiddify/features/gpn/ui/screens/gpn_shell.dart';
import 'package:hiddify/features/gpn/ui/screens/welcome_screen.dart';
import 'package:hiddify/features/gpn/ui/services/device_id_store.dart';
import 'package:hiddify/features/gpn/ui/services/session_store.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
/// Стартовый экран → кабинет или аварийный VPN.
class GpnRoot extends ConsumerStatefulWidget {
  const GpnRoot({super.key});

  @override
  ConsumerState<GpnRoot> createState() => _GpnRootState();
}

class _GpnRootState extends ConsumerState<GpnRoot> {
  final _session = SessionStore();
  final _deviceId = DeviceIdStore();
  String? _token;
  GpnSessionKind _kind = GpnSessionKind.cabinet;
  String _emergencyUrl = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await _loadSession();
  }

  Future<void> _loadSession() async {
    final token = await _session.loadToken();
    final kind = await _session.loadKind();
    final emergencyUrl = await _session.loadEmergencyUrl();
    if (!mounted) return;
    setState(() {
      _token = token;
      _kind = kind;
      _emergencyUrl = emergencyUrl ?? '';
      _loading = false;
    });
  }

  Future<void> _onLoggedIn(
    String token, {
    int? telegramId,
    String? subscriptionUrl,
    GpnSessionKind kind = GpnSessionKind.cabinet,
  }) async {
    await _session.saveToken(
      token,
      telegramId: telegramId,
      kind: kind,
      emergencyUrl: kind == GpnSessionKind.emergency ? subscriptionUrl : null,
    );
    if (!mounted) return;
    setState(() {
      _token = token;
      _kind = kind;
      if (kind == GpnSessionKind.emergency) {
        _emergencyUrl = subscriptionUrl?.trim() ?? '';
      }
    });
    _closeAuthOverlays();

    if (kind == GpnSessionKind.emergency) return;
  }

  Future<void> _logout() async {
    await GpnVpnBridge.disconnect(ref);
    await gpnClearAllProfiles(ref);
    await _session.clear();
    if (!mounted) return;
    setState(() {
      _token = null;
      _kind = GpnSessionKind.cabinet;
      _emergencyUrl = '';
    });
  }

  Future<GpnClient> _client() async {
    final id = await _deviceId.getOrCreate();
    return GpnClient(appToken: _token, deviceId: id);
  }

  /// LoginScreen пушится поверх Welcome — без pop кабинет остаётся под ним.
  void _closeAuthOverlays() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nav = Navigator.of(context);
      while (nav.canPop()) {
        nav.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_token == null || _token!.isEmpty) {
      return WelcomeScreen(onLoggedIn: _onLoggedIn);
    }
    if (_kind == GpnSessionKind.emergency) {
      return EmergencyVpnScreen(
        initialUrl: _emergencyUrl,
        onExit: _logout,
      );
    }
    return FutureBuilder<GpnClient>(
      future: _client(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return GpnShell(
          client: snap.data!,
          onLogout: _logout,
        );
      },
    );
  }
}
