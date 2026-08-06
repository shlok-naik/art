import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../shared/revenue_cat_service.dart';

/// Live customer info — updates whenever RevenueCat's SDK detects a change
/// (purchase, restore, renewal, expiration) via its own listener, not just
/// when this app triggers one.
final customerInfoProvider = StreamProvider<CustomerInfo>((ref) {
  final controller = StreamController<CustomerInfo>();

  void listener(CustomerInfo info) => controller.add(info);
  RevenueCatService().addCustomerInfoUpdateListener(listener);
  RevenueCatService().getCustomerInfo().then(controller.add).catchError(controller.addError);

  ref.onDispose(() {
    RevenueCatService().removeCustomerInfoUpdateListener(listener);
    controller.close();
  });

  return controller.stream;
});

/// Whether the "Unfinished Pro" entitlement is currently active. Defaults to
/// false while customer info is loading or if it fails to load.
final isProProvider = Provider<bool>((ref) {
  final customerInfo = ref.watch(customerInfoProvider).value;
  if (customerInfo == null) return false;
  return RevenueCatService().isProActive(customerInfo);
});

final offeringsProvider = FutureProvider<Offerings>((ref) => RevenueCatService().getOfferings());

/// The offering to present for upgrades — the dashboard's current offering.
final currentOfferingProvider = Provider<AsyncValue<Offering?>>((ref) {
  return ref.watch(offeringsProvider).whenData((offerings) => offerings.current);
});
