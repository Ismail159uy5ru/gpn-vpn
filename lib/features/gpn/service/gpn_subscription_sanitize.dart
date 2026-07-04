import 'dart:convert';

/// Убирает Happ-разметку из plain-подписки — Hiddify/sing-box не понимают
/// fragment вида `#name?serverDescription=base64` и ломают тег outbound.
String sanitizeGpnSubscriptionBody(String body) {
  final lines = body.split('\n');
  final out = <String>[];
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      out.add(line);
      continue;
    }
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('vless://') ||
        lower.startsWith('trojan://') ||
        lower.startsWith('ss://') ||
        lower.startsWith('hy2://') ||
        lower.startsWith('hysteria2://')) {
      out.add(_stripHappFragment(trimmed));
    } else if (lower.startsWith('vmess://')) {
      out.add(_stripVmessServerDescription(trimmed));
    } else {
      out.add(line);
    }
  }
  return out.join('\n');
}

/// Панель иногда отдаёт base64; бэкенд обычно уже декодирует, но на всякий случай.
String normalizeGpnSubscriptionRawBody(String body) {
  final trimmed = body.trim();
  if (trimmed.contains('vless://') ||
      trimmed.contains('vmess://') ||
      trimmed.contains('trojan://') ||
      trimmed.startsWith('#')) {
    return body;
  }
  final oneLine = trimmed.replaceAll(RegExp(r'\s+'), '');
  if (oneLine.isEmpty) return body;
  try {
    final decoded = utf8.decode(base64.decode(oneLine));
    if (decoded.contains('://')) return decoded;
  } catch (_) {}
  try {
    final decoded = utf8.decode(base64.decode(base64.normalize(oneLine)));
    if (decoded.contains('://')) return decoded;
  } catch (_) {}
  return body;
}

String _stripHappFragment(String uri) {
  var line = uri;
  if (line.contains('%')) {
    try {
      line = Uri.decodeFull(line);
    } catch (_) {}
  }
  final hash = line.indexOf('#');
  if (hash < 0) return line;
  var frag = line.substring(hash + 1);
  try {
    frag = Uri.decodeComponent(frag);
  } catch (_) {}
  final q = frag.toLowerCase().indexOf('?serverdescription=');
  if (q >= 0) frag = frag.substring(0, q).trim();
  return '${line.substring(0, hash + 1)}$frag';
}

String _stripVmessServerDescription(String line) {
  const prefix = 'vmess://';
  if (!line.toLowerCase().startsWith(prefix)) return line;
  final b64 = line.substring(prefix.length).trim();
  try {
    final jsonStr = utf8.decode(base64.decode(b64));
    final m = jsonDecode(jsonStr) as Map<String, dynamic>;
    if (m.remove('serverDescription') == null) return line;
    return '$prefix${base64.encode(utf8.encode(jsonEncode(m)))}';
  } catch (_) {
    return line;
  }
}
