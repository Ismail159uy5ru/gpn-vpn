import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class GpnState {
  GpnState({
    required this.telegramId,
    required this.hasActiveSub,
    required this.daysLeft,
    required this.balanceRub,
    required this.subscriptionUrl,
    required this.deviceSlotsUsed,
    required this.deviceSlotsMax,
    required this.payDays,
    this.botUsername = '',
    this.subscriptionStatus = '',
    this.endAt,
  });

  final int telegramId;
  final bool hasActiveSub;
  final int daysLeft;
  final double balanceRub;
  final String subscriptionUrl;
  final int deviceSlotsUsed;
  final int deviceSlotsMax;
  final int payDays;
  final String botUsername;
  final String subscriptionStatus;
  final String? endAt;

  factory GpnState.fromJson(Map<String, dynamic> j) => GpnState(
        telegramId: (j['telegram_id'] as num?)?.toInt() ?? 0,
        hasActiveSub: j['has_active_sub'] == true,
        daysLeft: (j['days_left'] as num?)?.toInt() ?? 0,
        balanceRub: (j['balance_rub'] as num?)?.toDouble() ?? 0,
        subscriptionUrl: j['subscription_url']?.toString() ?? '',
        deviceSlotsUsed: (j['device_slots_used'] as num?)?.toInt() ?? 0,
        deviceSlotsMax: (j['device_slots_max'] as num?)?.toInt() ?? 3,
        payDays: (j['pay_days'] as num?)?.toInt() ?? 30,
        botUsername: j['bot_username']?.toString() ?? '',
        subscriptionStatus: j['subscription_status']?.toString() ?? '',
        endAt: j['end_at']?.toString(),
      );
}

class GpnPlan {
  GpnPlan({required this.devices, required this.priceRub});
  final int devices;
  final double priceRub;

  factory GpnPlan.fromJson(Map<String, dynamic> j) => GpnPlan(
        devices: (j['devices'] as num?)?.toInt() ?? 3,
        priceRub: (j['price_rub'] as num?)?.toDouble() ?? 0,
      );
}

class GpnDevice {
  GpnDevice({
    required this.id,
    required this.label,
    required this.firstSeenAt,
    required this.lastSeenAt,
  });

  final int id;
  final String label;
  final String firstSeenAt;
  final String lastSeenAt;

  factory GpnDevice.fromJson(Map<String, dynamic> j) => GpnDevice(
        id: (j['id'] as num?)?.toInt() ?? 0,
        label: j['label']?.toString() ?? '',
        firstSeenAt: j['first_seen_at']?.toString() ?? '',
        lastSeenAt: j['last_seen_at']?.toString() ?? '',
      );
}

class GpnDevicesResponse {
  GpnDevicesResponse({
    required this.devices,
    required this.slotsUsed,
    required this.slotsMax,
  });

  final List<GpnDevice> devices;
  final int slotsUsed;
  final int slotsMax;

  factory GpnDevicesResponse.fromJson(Map<String, dynamic> j) => GpnDevicesResponse(
        devices: (j['devices'] as List<dynamic>? ?? [])
            .map((e) => GpnDevice.fromJson(e as Map<String, dynamic>))
            .toList(),
        slotsUsed: (j['slots_used'] as num?)?.toInt() ?? 0,
        slotsMax: (j['slots_max'] as num?)?.toInt() ?? 3,
      );
}

class GpnAuthSession {
  GpnAuthSession({
    required this.token,
    required this.expiresAt,
    required this.telegramId,
    this.subscriptionUrl,
    this.profileExpiresAt,
  });

  final String token;
  final String expiresAt;
  final int telegramId;
  final String? subscriptionUrl;
  final String? profileExpiresAt;

  factory GpnAuthSession.fromJson(Map<String, dynamic> j) => GpnAuthSession(
        token: j['token']?.toString() ?? '',
        expiresAt: j['expires_at']?.toString() ?? j['session_expires_at']?.toString() ?? '',
        telegramId: (j['telegram_id'] as num?)?.toInt() ?? 0,
        subscriptionUrl: j['subscription_url']?.toString(),
        profileExpiresAt: j['expires_at']?.toString(),
      );
}

class GpnEmergencyStatus {
  GpnEmergencyStatus({required this.canIssue, this.nextAvailableAt, required this.cooldownHours});
  final bool canIssue;
  final String? nextAvailableAt;
  final int cooldownHours;

  factory GpnEmergencyStatus.fromJson(Map<String, dynamic> j) => GpnEmergencyStatus(
        canIssue: j['can_issue'] == true,
        nextAvailableAt: j['next_available_at']?.toString(),
        cooldownHours: (j['cooldown_hours'] as num?)?.toInt() ?? 24,
      );
}

class GpnApiException implements Exception {
  GpnApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class GpnClient {
  GpnClient({this.baseUrl = kApiBase, this.appToken});

  final String baseUrl;
  String? appToken;

  Map<String, String> _headers({bool json = false}) {
    return <String, String>{
      if (json) 'Content-Type': 'application/json',
      if (appToken != null && appToken!.isNotEmpty) 'X-App-Token': appToken!,
    };
  }

  Future<bool> ping() async {
    final r = await http.get(Uri.parse('$baseUrl/app/ping'));
    return r.statusCode == 200;
  }

  Future<String> fetchBotUsername() async {
    final r = await http.get(Uri.parse('$baseUrl/app/ping'));
    if (r.statusCode != 200) return '';
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return j['bot_username']?.toString() ?? '';
  }

  Future<List<GpnPlan>> fetchPlans() async {
    final r = await http.get(Uri.parse('$baseUrl/app/plans'));
    if (r.statusCode != 200) throw GpnApiException('plans ${r.statusCode}');
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final list = j['plans'] as List<dynamic>? ?? [];
    return list.map((e) => GpnPlan.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GpnAuthSession> exchangeBotAuth(String botAuth) async {
    final r = await http.post(
      Uri.parse('$baseUrl/app/auth/exchange'),
      headers: _headers(json: true),
      body: jsonEncode({'bot_auth': botAuth}),
    );
    if (r.statusCode != 200) {
      throw GpnApiException('auth ${r.statusCode}', statusCode: r.statusCode);
    }
    return GpnAuthSession.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<GpnAuthSession> loginWithCode(String code) async {
    final r = await http.post(
      Uri.parse('$baseUrl/app/auth/code'),
      headers: _headers(json: true),
      body: jsonEncode({'code': code}),
    );
    if (r.statusCode != 200) {
      throw GpnApiException('Неверный или просроченный код', statusCode: r.statusCode);
    }
    return GpnAuthSession.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<GpnAuthSession> emergencyWithCode(String code) async {
    final r = await http.post(
      Uri.parse('$baseUrl/app/emergency'),
      headers: _headers(json: true),
      body: jsonEncode({'code': code}),
    );
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode == 429) {
      throw GpnApiException('Аварийный доступ: раз в сутки', statusCode: 429);
    }
    if (r.statusCode != 200) {
      throw GpnApiException('Не удалось создать аварийный профиль', statusCode: r.statusCode);
    }
    return GpnAuthSession.fromJson(body);
  }

  Future<GpnEmergencyStatus> fetchEmergencyStatus() async {
    final r = await http.get(
      Uri.parse('$baseUrl/app/emergency/status'),
      headers: _headers(),
    );
    if (r.statusCode != 200) throw GpnApiException('status ${r.statusCode}');
    return GpnEmergencyStatus.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<GpnAuthSession> requestEmergency() async {
    final r = await http.post(
      Uri.parse('$baseUrl/app/emergency'),
      headers: _headers(json: true),
      body: jsonEncode({}),
    );
    if (r.statusCode == 429) {
      throw GpnApiException('Аварийный доступ: раз в сутки', statusCode: 429);
    }
    if (r.statusCode != 200) throw GpnApiException('emergency ${r.statusCode}');
    return GpnAuthSession.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<GpnState> fetchState() async {
    final r = await http.get(
      Uri.parse('$baseUrl/mini/state'),
      headers: _headers(),
    );
    if (r.statusCode != 200) {
      throw GpnApiException('state ${r.statusCode}', statusCode: r.statusCode);
    }
    return GpnState.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<GpnDevicesResponse> fetchDevices() async {
    final r = await http.get(
      Uri.parse('$baseUrl/mini/devices'),
      headers: _headers(),
    );
    if (r.statusCode != 200) {
      throw GpnApiException('devices ${r.statusCode}', statusCode: r.statusCode);
    }
    return GpnDevicesResponse.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<GpnDevice> addDevice(String label) async {
    final r = await http.post(
      Uri.parse('$baseUrl/mini/devices'),
      headers: _headers(json: true),
      body: jsonEncode({'label': label}),
    );
    if (r.statusCode == 409) {
      throw GpnApiException('Лимит устройств достигнут', statusCode: 409);
    }
    if (r.statusCode != 200) {
      throw GpnApiException('add device ${r.statusCode}', statusCode: r.statusCode);
    }
    return GpnDevice.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<void> deleteDevice(int id) async {
    final r = await http.delete(
      Uri.parse('$baseUrl/mini/devices?id=$id'),
      headers: _headers(),
    );
    if (r.statusCode != 204 && r.statusCode != 200) {
      throw GpnApiException('delete ${r.statusCode}', statusCode: r.statusCode);
    }
  }

  Future<void> renameDevice(int id, String label) async {
    final r = await http.patch(
      Uri.parse('$baseUrl/mini/devices'),
      headers: _headers(json: true),
      body: jsonEncode({'id': id, 'label': label}),
    );
    if (r.statusCode != 204 && r.statusCode != 200) {
      throw GpnApiException('rename ${r.statusCode}', statusCode: r.statusCode);
    }
  }

  Future<String> createSbpPayment(int devices) async {
    final j = await _createPayment(method: 'sbp', devices: devices);
    return j['pay_url']?.toString() ?? '';
  }

  Future<void> payFromBalance(int devices) async {
    await _createPayment(method: 'balance', devices: devices);
  }

  Future<Map<String, dynamic>> _createPayment({
    required String method,
    required int devices,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/mini/payment/create'),
      headers: _headers(json: true),
      body: jsonEncode({'method': method, 'devices': devices}),
    );
    if (r.statusCode != 200) {
      final body = r.body;
      if (r.statusCode == 402 || body.contains('insufficient')) {
        throw GpnApiException('Недостаточно средств на балансе', statusCode: r.statusCode);
      }
      if (r.statusCode == 503) {
        throw GpnApiException('СБП временно недоступен', statusCode: r.statusCode);
      }
      throw GpnApiException('payment ${r.statusCode}', statusCode: r.statusCode);
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}
