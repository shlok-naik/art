import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'shared/ads_service.dart';
import 'shared/revenue_cat_service.dart';
import 'shared/theme_providers.dart';
import 'shared/theme_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await RevenueCatService().initialize();
  await AdsService().initialize();

  final isDarkMode = await ThemeStore().getIsDarkMode();

  runApp(
    ProviderScope(
      overrides: [initialDarkModeProvider.overrideWithValue(isDarkMode)],
      child: const App(),
    ),
  );
}
