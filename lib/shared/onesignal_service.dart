import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// The app's public OneSignal App ID (not a secret — safe to hardcode).
const oneSignalAppId = '7a4d0fac-fb3e-4fa1-b8ab-0a2e97b9b26f';

/// Centralized wrapper around the OneSignal SDK. All OneSignal calls in the
/// app should go through this class rather than calling `OneSignal.*`
/// directly, so the SDK surface stays swappable/testable in one place.
class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  bool _isInitialized = false;

  // OneSignal only ships native plugin code for Android and iOS — on other
  // platforms (e.g. Windows desktop, web) every call throws
  // MissingPluginException. Checked via defaultTargetPlatform/kIsWeb rather
  // than dart:io's Platform, which throws UnsupportedError on web.
  static bool get _isSupported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  void initialize(String appId) {
    if (_isInitialized || !_isSupported) return;

    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(appId);
    _isInitialized = true;
  }

  void login(String externalId) {
    if (_isSupported) OneSignal.login(externalId);
  }

  void logout() {
    if (_isSupported) OneSignal.logout();
  }

  void setEmail(String email) {
    if (_isSupported) OneSignal.User.addEmail(email);
  }

  void setSmsNumber(String number) {
    if (_isSupported) OneSignal.User.addSms(number);
  }

  void setTag(String key, String value) {
    if (_isSupported) OneSignal.User.addTagWithKey(key, value);
  }

  Future<bool> requestPermission() =>
      _isSupported ? OneSignal.Notifications.requestPermission(true) : Future.value(false);

  void setLogLevel(OSLogLevel level) {
    if (_isSupported) OneSignal.Debug.setLogLevel(level);
  }

  String? get pushSubscriptionId => _isSupported ? OneSignal.User.pushSubscription.id : null;

  void addPushSubscriptionObserver(void Function(OSPushSubscriptionChangedState state) handler) {
    if (_isSupported) OneSignal.User.pushSubscription.addObserver(handler);
  }
}
