import 'package:flutter/material.dart';

/// Заглушка до интеграции форка Hiddify (sing-box внутри приложения).
class VpnPlaceholderScreen extends StatelessWidget {
  const VpnPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VPN')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.construction, size: 48, color: Color(0xFF8B5CF6)),
            SizedBox(height: 16),
            Text(
              'VPN-движок Hiddify',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 12),
            Text(
              'На следующем шаге сюда встраивается форк hiddify-app:\n'
              '• подключение / отключение\n'
              '• выбор узла\n'
              '• настройки туннеля\n\n'
              'Пока используйте «Подключить VPN» на главной — импорт подписки.',
              style: TextStyle(color: Colors.white70, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
