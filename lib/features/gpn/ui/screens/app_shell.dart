import 'package:flutter/material.dart';
import '../api/gpn_client.dart';
import 'devices_screen.dart';
import 'home_screen.dart';
import 'payment_screen.dart';
import 'vpn_placeholder_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.client,
    required this.onLogout,
  });

  final GpnClient client;
  final VoidCallback onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(client: widget.client, onLogout: widget.onLogout),
      PaymentScreen(client: widget.client),
      DevicesScreen(client: widget.client),
      const VpnPlaceholderScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.payment_outlined), selectedIcon: Icon(Icons.payment), label: 'Оплата'),
          NavigationDestination(icon: Icon(Icons.devices_outlined), selectedIcon: Icon(Icons.devices), label: 'Устройства'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'VPN'),
        ],
      ),
    );
  }
}
