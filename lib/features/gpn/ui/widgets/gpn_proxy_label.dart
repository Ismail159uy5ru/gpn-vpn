/// Человекочитаемое имя сервера из tag Hiddify (без Happ ?serverDescription=…).
String gpnProxyDisplayName(String raw) {
  var s = raw.trim();
  final q = s.indexOf('?serverDescription=');
  if (q >= 0) s = s.substring(0, q).trim();
  if (s.startsWith('N/A-')) s = s.substring(4);
  if (s.startsWith('N/A ')) s = s.substring(4);
  return s.isEmpty ? 'Сервер' : s;
}
