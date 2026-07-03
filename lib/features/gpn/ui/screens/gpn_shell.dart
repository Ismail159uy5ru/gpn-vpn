import 'package:flutter/material.dart';
import '../api/gpn_client.dart';
import '../widgets/gpn_background.dart';
import 'devices_screen.dart';
import 'gpn_home_screen.dart';
import 'payment_screen.dart';
import 'settings_screen.dart';

class GpnShell extends StatefulWidget {
  const GpnShell({super.key, required this.client, required this.onLogout});

  final GpnClient client;
  final VoidCallback onLogout;

  @override
  State<GpnShell> createState() => _GpnShellState();
}

class _GpnShellState extends State<GpnShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      GpnHomeScreen(client: widget.client, onLogout: widget.onLogout),
      DevicesScreen(client: widget.client),
      PaymentScreen(client: widget.client),
      SettingsScreen(client: widget.client),
    ];

    return GpnBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: NavigationBar(
          backgroundColor: const Color(0xE60A0015),
          indicatorColor: const Color(0x338B5CF6),
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield),
              label: 'VPN',
            ),
            NavigationDestination(
              icon: Icon(Icons.devices_outlined),
              selectedIcon: Icon(Icons.devices),
              label: 'Устройства',
            ),
            NavigationDestination(
              icon: Icon(Icons.payment_outlined),
              selectedIcon: Icon(Icons.payment),
              label: 'Оплата',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Настройки',
            ),
          ],
        ),
      ),
    );
  }
}
