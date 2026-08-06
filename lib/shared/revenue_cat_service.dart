import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat's test API key for this app (not a secret — safe to hardcode,
/// same as the OneSignal App ID).
const revenueCatApiKey = 'test_pWxUNOtXZeAheSzzyvPhCeNJeON';

/// Entitlement identifier configured in the RevenueCat dashboard, unlocked
/// by the lifetime/yearly/monthly products.
const proEntitlementId = 'Unfinished Pro';

/// Outcome of a purchase/restore attempt, distinguishing a user-initiated
/// cancel (not an error) from an actual failure.
sealed class PurchaseOutcome {}

class PurchaseSuccess extends PurchaseOutcome {
  PurchaseSuccess(this.customerInfo);
  final CustomerInfo customerInfo;
}

class PurchaseCancelled extends PurchaseOutcome {}

class PurchaseFailed extends PurchaseOutcome {
  PurchaseFailed(this.message);
  final String message;
}

/// Centralized wrapper around the RevenueCat SDK. All RevenueCat calls in
/// the app should go through this class rather than calling `Purchases.*`
/// directly, so the SDK surface stays swappable/testable in one place.
class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
    await Purchases.configure(PurchasesConfiguration(revenueCatApiKey));
    _isInitialized = true;
  }

  /// Syncs the RevenueCat identity with the app's authenticated user, so
  /// entitlements follow the account rather than a per-device anonymous ID.
  Future<void> login(String appUserId) async {
    await Purchases.logIn(appUserId);
  }

  /// Reverts to a new anonymous RevenueCat ID on sign-out.
  Future<void> logout() async {
    await Purchases.logOut();
  }

  Future<CustomerInfo> getCustomerInfo() => Purchases.getCustomerInfo();

  bool isProActive(CustomerInfo customerInfo) => customerInfo.entitlements.active.containsKey(proEntitlementId);

  void addCustomerInfoUpdateListener(CustomerInfoUpdateListener listener) {
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  void removeCustomerInfoUpdateListener(CustomerInfoUpdateListener listener) {
    Purchases.removeCustomerInfoUpdateListener(listener);
  }

  Future<Offerings> getOfferings() => Purchases.getOfferings();

  Future<PurchaseOutcome> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return PurchaseSuccess(result.customerInfo);
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseCancelled();
      }
      return PurchaseFailed(e.message ?? 'Purchase failed');
    }
  }

  Future<PurchaseOutcome> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return PurchaseSuccess(customerInfo);
    } on PlatformException catch (e) {
      return PurchaseFailed(e.message ?? 'Restore failed');
    }
  }
}
