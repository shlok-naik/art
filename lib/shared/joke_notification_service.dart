import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const _jokes = [
  "Why don't artists ever get lost? They always know how to draw a map.",
  "What do you call a painting made by a cat? A paw-trait.",
  "Why did the sculptor go broke? He kept making ends meet.",
  "What's an artist's favorite kind of tree? A palm — always ready to sketch.",
  "Why was the easel sad? It kept getting framed for things it didn't do.",
  "What do you call a sketch of a chicken? An eggs-hibit.",
  "Why did the colored pencil break up with the crayon? It felt taken for granite... wait, wrong medium.",
  "How does a painter greet people? \"Watercolor is your day going?\"",
  "Why don't sketches ever win arguments? They're too easily erased.",
  "What did one canvas say to the other? \"I've got you covered.\"",
];

/// Shows a free, on-device notification with the app mascot and a random
/// joke — no OneSignal send involved, so it never touches the paid quota.
/// Uses the same OS notification permission OneSignal's verification dialog
/// requests, so it deliberately does not request permission itself.
class JokeNotificationService {
  static final JokeNotificationService _instance = JokeNotificationService._internal();
  factory JokeNotificationService() => _instance;
  JokeNotificationService._internal();

  static const _mascotAssetPath = 'assets/branding/mascot.png';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _isInitialized = true;
  }

  Future<void> showRandomJoke() async {
    await _ensureInitialized();

    final joke = (_jokes.toList()..shuffle()).first;
    final mascotBytes = await _mascotBytes();

    final androidDetails = AndroidNotificationDetails(
      'mascot_jokes',
      'Mascot Jokes',
      channelDescription: 'A random joke from the Unfinished mascot',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      largeIcon: ByteArrayAndroidBitmap(mascotBytes),
      styleInformation: BigPictureStyleInformation(
        ByteArrayAndroidBitmap(mascotBytes),
        largeIcon: ByteArrayAndroidBitmap(mascotBytes),
        contentTitle: 'Your mascot says...',
        summaryText: joke,
      ),
    );

    final iosDetails = DarwinNotificationDetails(
      attachments: [DarwinNotificationAttachment(await _mascotTempFilePath())],
    );

    await _plugin.show(
      id: 0,
      title: 'Your mascot says...',
      body: joke,
      notificationDetails: NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<Uint8List> _mascotBytes() async {
    final data = await rootBundle.load(_mascotAssetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  /// iOS notification attachments require a real file on disk (a bundle
  /// asset path isn't enough), so the mascot image is copied to a temp file.
  Future<String> _mascotTempFilePath() async {
    final bytes = await _mascotBytes();
    final dir = await Directory.systemTemp.createTemp('mascot_joke');
    final file = File('${dir.path}/mascot.png');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
