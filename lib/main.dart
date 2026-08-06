import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'shared/onesignal_service.dart';
import 'shared/revenue_cat_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Push permission isn't requested here — the verification dialog in App
  // requests it once the device has actually registered with OneSignal.
  OneSignalService().initialize(oneSignalAppId);

  await RevenueCatService().initialize();

  runApp(const ProviderScope(child: App()));
}
