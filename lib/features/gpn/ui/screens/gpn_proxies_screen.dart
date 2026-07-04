import 'package:flutter/material.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_page.dart';

/// Обёртка без GoRouter.
class GpnProxiesScreen extends StatelessWidget {
  const GpnProxiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProxiesOverviewPage();
  }
}
