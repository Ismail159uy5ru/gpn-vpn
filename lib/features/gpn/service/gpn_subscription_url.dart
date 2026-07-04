/// URL подписки без ?did= — для хранения в БД и поиска профиля.
String gpnCanonicalSubUrl(String url) {
  final u = Uri.parse(url.trim());
  return Uri(scheme: u.scheme, host: u.host, path: u.path).toString();
}

/// Ключ для поиска профиля по токену /subp/{token}.
String? gpnSubpLookupKey(String url) {
  final m = RegExp(r'/subp/([^/?#]+)').firstMatch(url);
  if (m == null) return null;
  return '/subp/${m.group(1)}';
}
