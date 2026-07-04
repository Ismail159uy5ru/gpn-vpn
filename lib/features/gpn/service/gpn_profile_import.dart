import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/core/http_client/http_client_provider.dart';
import 'package:hiddify/features/gpn/service/gpn_subscription_sanitize.dart';
import 'package:hiddify/features/gpn/service/gpn_subscription_url.dart';
import 'package:hiddify/features/profile/data/profile_data_mapper.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/data/profile_parser.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Удаляет VPN-профили (только при выходе из учётки).
Future<void> gpnClearAllProfiles(WidgetRef ref) async {
  final repo = await ref.read(profileRepositoryProvider.future);
  final either = await repo.watchAll().first;
  either.fold((_) {}, (profiles) async {
    for (final p in profiles) {
      await repo.deleteById(p.id, p.active).run();
    }
  });
}

/// Скачивает подписку, убирает Happ serverDescription и импортирует как remote-профиль.
Future<String?> gpnImportSubscriptionProfile(
  WidgetRef ref,
  String fetchUrl, {
  bool replaceExistingProfiles = false,
}) async {
  final trimmed = fetchUrl.trim();
  if (trimmed.isEmpty) return 'Нет ссылки подписки';

  if (replaceExistingProfiles) {
    await gpnClearAllProfiles(ref);
  }

  final repo = await ref.read(profileRepositoryProvider.future);
  final pathResolver = ref.read(profilePathResolverProvider);
  final http = ref.read(httpClientProvider);
  final ds = ref.read(profileDataSourceProvider);
  final cancelToken = CancelToken();
  const userOverride = UserOverride(name: 'GPN');

  final lookup = gpnSubpLookupKey(trimmed) ?? gpnCanonicalSubUrl(trimmed);
  final profEntry = await ds.getByUrl(trimmed) ?? await ds.getByUrl(lookup);

  final id = profEntry?.id ?? const Uuid().v4();
  final file = pathResolver.file(id);
  final tempFile = pathResolver.tempFile(id);
  final isUpdate = profEntry != null;

  try {
    final Response<dynamic> rs;
    try {
      rs = await http.download(trimmed, tempFile.path, cancelToken: cancelToken);
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return null;
      return 'Не удалось загрузить подписку. Проверьте интернет и лимит устройств.';
    }

    var body = await tempFile.readAsString();
    body = sanitizeGpnSubscriptionBody(normalizeGpnSubscriptionRawBody(body));
    await tempFile.writeAsString(body);

    await _gpnExpandRemoteLines(ref, tempFile.path, http, cancelToken);

    final remoteHeaders = rs.headers.map.map((key, value) {
      if (value.length == 1) return MapEntry(key, value.first);
      return MapEntry(key, value);
    });

    final content = await tempFile.readAsString();
    final headersEither = ProfileParser.populateHeaders(content: content, remoteHeaders: remoteHeaders);
    if (headersEither.isLeft()) {
      return 'Не удалось разобрать подписку.';
    }

    final profEntity = profEntry?.toEntity();
    final profile = isUpdate && profEntity is RemoteProfileEntity
        ? profEntity.copyWith(url: trimmed, userOverride: userOverride, populatedHeaders: headersEither.getOrElse((_) => {}))
        : ProfileEntity.remote(
            id: id,
            active: true,
            name: '',
            url: trimmed,
            lastUpdate: DateTime.now(),
            userOverride: userOverride,
            populatedHeaders: headersEither.getOrElse((_) => {}),
          );

    final parseEither = ProfileParser.parse(tempFilePath: tempFile.path, profile: profile);
    if (parseEither.isLeft()) {
      return 'Не удалось импортировать профиль. Проверьте лимит устройств в кабинете.';
    }
    final parsed = parseEither.getOrElse((_) => throw StateError('unreachable'));

    final validateResult = await repo
        .validateConfig(
          file.path,
          tempFile.path,
          parsed.profileOverride(),
          false,
        )
        .run();
    if (validateResult.isLeft()) {
      return 'Не удалось импортировать профиль. Проверьте лимит устройств в кабинете.';
    }

    if (isUpdate) {
      await ds.edit(id, parsed.toUpdateEntry());
    } else {
      await ds.insert(parsed.toInsertEntry());
    }

    await repo.setAsActive(id).run();
    return null;
  } finally {
    if (tempFile.existsSync()) tempFile.deleteSync();
  }
}

Future<void> _gpnExpandRemoteLines(
  WidgetRef ref,
  String tempFilePath,
  DioHttpClient http,
  CancelToken cancelToken,
) async {
  final content = await File(tempFilePath).readAsString();
  if (!content.contains('https://') && !content.contains('http://')) return;

  final ua = ref.read(ConfigOptions.useXrayCoreWhenPossible)
      ? http.userAgent.replaceAll('HiddifyNext', 'HiddifyNextX')
      : null;
  final lines = content.split('\n');
  final results = List<String?>.filled(lines.length, null);
  var index = 0;

  Future<void> worker() async {
    while (true) {
      if (cancelToken.isCancelled) return;
      final i = index++;
      if (i >= lines.length) return;
      final line = lines[i];
      if (!line.startsWith('http://') && !line.startsWith('https://')) {
        results[i] = line.trim();
        continue;
      }
      try {
        final tmpPath = '$tempFilePath.$i';
        await http.download(line, tmpPath, cancelToken: cancelToken, userAgent: ua);
        results[i] = (await File(tmpPath).readAsString()).trim();
      } catch (err) {
        if (err is DioException && CancelToken.isCancel(err)) return;
        results[i] = '';
      }
    }
  }

  await Future.wait(List.generate(4, (_) => worker()));
  if (results.any((e) => e != null)) {
    await File(tempFilePath).writeAsString(results.join('\n'));
  }
}
