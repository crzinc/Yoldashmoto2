import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/store.dart';
import 'core/theme.dart';

class YoldashApp extends ConsumerWidget {
  const YoldashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      title: 'YoldashMoto',
      debugShowCheckedModeBanner: false,
      theme: YmTheme.light,
      darkTheme: YmTheme.dark,
      themeMode: settings.themeMode,
      locale: Locale(settings.lang),
      supportedLocales: const [Locale('az'), Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: buildRouter(ref),
    );
  }
}
