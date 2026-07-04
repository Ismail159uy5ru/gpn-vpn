import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/gpn/service/gpn_subscription_sanitize.dart';

void main() {
  test('strips Happ serverDescription from vless fragment', () {
    const raw =
        'vless://uuid@1.2.3.4:443?security=reality#%E2%9B%94N%2FA-%D0%A1%D0%A8%D0%90?serverDescription=R1BO';
    final out = sanitizeGpnSubscriptionBody(raw);
    expect(out, isNot(contains('serverDescription')));
    expect(out, contains('#'));
    expect(out, contains('N/A'));
  });

  test('strips serverDescription from vmess json', () {
    const vmessJson =
        '{"v":"2","ps":"test","add":"1.2.3.4","port":"443","id":"uuid","aid":"0","net":"tcp","type":"none","host":"","path":"","tls":"","serverDescription":"GPN"}';
    final line = 'vmess://${base64.encode(utf8.encode(vmessJson))}';
    final out = sanitizeGpnSubscriptionBody(line);
    expect(out, isNot(contains('serverDescription')));
  });

  test('preserves comment lines and plain vless without fragment query', () {
    const body = '# profile-title: GPN\nvless://u@h:1#Poland\n';
    final out = sanitizeGpnSubscriptionBody(body);
    expect(out, contains('# profile-title: GPN'));
    expect(out, contains('#Poland'));
  });
}
