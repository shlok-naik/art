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

  void initialize(String appId) {
    if (_isInitialized) return;

    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(appId);
    _isInitialized = true;
  }

  void login(String externalId) => OneSignal.login(externalId);

  void logout() => OneSignal.logout();

  void setEmail(String email) => OneSignal.User.addEmail(email);

  void setSmsNumber(String number) => OneSignal.User.addSms(number);

  void setTag(String key, String value) => OneSignal.User.addTagWithKey(key, value);

  Future<bool> requestPermission() => OneSignal.Notifications.requestPermission(true);

  void setLogLevel(OSLogLevel level) => OneSignal.Debug.setLogLevel(level);

  String? get pushSubscriptionId => OneSignal.User.pushSubscription.id;

  void addPushSubscriptionObserver(void Function(OSPushSubscriptionChangedState state) handler) {
    OneSignal.User.pushSubscription.addObserver(handler);
  }
}
