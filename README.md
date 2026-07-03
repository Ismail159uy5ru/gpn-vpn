# GPN VPN

Полноценное Android-приложение: **личный кабинет GPN** (общий с Telegram-ботом) + **встроенный VPN** на ядре Hiddify (sing-box).

Отдельный Hiddify из магазина **не нужен**.

## Что внутри

| Часть | Описание |
|-------|----------|
| Кабинет | Вход 6 цифр из бота, подписка, баланс, устройства, оплата СБП |
| VPN | Ядро hiddify-core: импорт `/subp/{token}`, connect/disconnect |
| Настройки VPN | DNS, маршрутизация, per-app — экран Hiddify в «Расширенные настройки» |

## Сборка APK

```powershell
cd c:\Users\venya\cursorProject\gpn-vpn

# Скачать нативное ядро (AAR в android/app/libs/)
make android-prepare
# или на Windows без make — см. Makefile target android-libs

flutter pub get
flutter build apk --release --dart-define=GPN_API_BASE=https://giga-gpn.space
```

APK: `GPN-VPN-release.apk` в корне проекта (или `build/app/outputs/flutter-apk/app-release.apk`)

Одной командой:

```powershell
cd c:\Users\venya\cursorProject\gpn-vpn
.\scripts\build-apk.ps1
```

## Бэкенд

Репозиторий `vpn_bot-2` на VPS, API `https://giga-gpn.space`:

- `POST /app/auth/code` — вход 6 цифр
- `GET /mini/state` — состояние кабинета
- `POST /app/emergency` — аварийный профиль 1 ч

## Структура

```
lib/features/gpn/
  widget/gpn_main_app.dart   — точка входа UI
  widget/gpn_root.dart       — логин / кабинет
  service/gpn_vpn_bridge.dart — связка с Hiddify VPN
  ui/                        — экраны кабинета (мини-апп стиль)
```

Ядро Hiddify: `lib/hiddifycore/`, `android/.../bg/VPNService.kt`
