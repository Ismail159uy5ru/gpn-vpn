import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/features/gpn/service/gpn_subscription_url.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

/// Импорт как в stock Hiddify: upsertRemote + setAsActive.
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
  final ds = ref.read(profileDataSourceProvider);

  final result = await repo
      .upsertRemote(
        trimmed,
        userOverride: const UserOverride(name: 'GPN'),
        cancelToken: CancelToken(),
      )
      .run();

  if (result.isLeft()) {
    return 'Не удалось импортировать профиль. Проверьте лимит устройств в кабинете.';
  }

  final lookup = gpnSubpLookupKey(trimmed) ?? gpnCanonicalSubUrl(trimmed);
  final entry = await ds.getByUrl(trimmed) ?? await ds.getByUrl(lookup);
  if (entry != null) {
    await repo.setAsActive(entry.id).run();
  }

  return null;
}
