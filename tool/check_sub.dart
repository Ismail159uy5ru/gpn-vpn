import 'dart:io';

import 'package:hiddify/features/gpn/service/gpn_subscription_sanitize.dart';

void main(List<String> args) {
  final raw = args.length >= 2 && args[0] == '--file'
      ? File(args[1]).readAsStringSync()
      : args.join('\n');
  final out = sanitizeGpnSubscriptionBody(normalizeGpnSubscriptionRawBody(raw));
  final bad = out.toLowerCase().contains('serverdescription');
  print(bad ? 'STILL_HAS_serverDescription' : 'CLEAN');
  for (final line in out.split('\n')) {
    if (line.contains('vless://') || line.contains('trojan://')) print(line);
  }
}
