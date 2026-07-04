import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/go_router/go_router_notifier.dart';
import 'package:hiddify/features/connection/widget/connection_wrapper.dart';
import 'package:hiddify/features/gpn/ui/theme/gpn_theme.dart';
import 'package:hiddify/features/gpn/widget/gpn_root.dart';
import 'package:hiddify/features/per_app_proxy/overview/per_app_proxy_service_notifier.dart';
import 'package:hiddify/features/profile/notifier/profiles_update_notifier.dart';
import 'package:hiddify/features/window/widget/window_wrapper.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:toastification/toastification.dart';

/// GPN: кабинет + ядро Hiddify в одном приложении.
class GpnMainApp extends HookConsumerWidget {
  const GpnMainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _setupLifecycle(ref);
    _ensureHiddifyReady(ref);

    ref.listen(foregroundProfilesUpdateNotifierProvider, (_, _) {});
    if (PlatformUtils.isAndroid) ref.listen(perAppProxyServiceProvider, (_, _) {});

    return WindowWrapper(
      ToastificationWrapper(
        child: ConnectionWrapper(
          MaterialApp(
            navigatorKey: rootNavKey,
            title: Constants.appName,
            debugShowCheckedModeBanner: false,
            theme: gpnDarkTheme,
            darkTheme: gpnDarkTheme,
            themeMode: ThemeMode.dark,
            home: const GpnRoot(),
            builder: (context, child) {
              final theme = Theme.of(context);
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: theme.scaffoldBackgroundColor,
                  systemNavigationBarColor: theme.scaffoldBackgroundColor,
                  systemNavigationBarIconBrightness: Brightness.light,
                ),
                child: child ?? const SizedBox(),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Без intro и rootNavKey диалоги VPN/ошибки connect в Hiddify не показываются.
  void _ensureHiddifyReady(WidgetRef ref) {
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!ref.read(Preferences.introCompleted)) {
          await ref.read(Preferences.introCompleted.notifier).update(true);
        }
      });
      return null;
    }, const []);
  }

  void _setupLifecycle(WidgetRef ref) {
    final appLifecycleState = useAppLifecycleState();
    useEffect(() {
      if (appLifecycleState == AppLifecycleState.paused ||
          appLifecycleState == AppLifecycleState.inactive) {
        if (!PlatformUtils.isDesktop) {
          ref.read(hiddifyCoreServiceProvider).closeFront();
        }
      } else if (appLifecycleState == AppLifecycleState.resumed) {
        ref.read(hiddifyCoreServiceProvider).init();
      }
      return null;
    }, [appLifecycleState]);
  }
}
