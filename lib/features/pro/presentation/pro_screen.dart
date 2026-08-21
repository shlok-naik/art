import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/revenue_cat_service.dart';
import '../../shell/main_shell.dart';
import '../providers.dart';
import 'art_wrapped_screen.dart';
import 'pro_unlocked_screen.dart';

class ProScreen extends ConsumerWidget {
  const ProScreen({super.key});

  Future<void> _presentPaywall(BuildContext context, WidgetRef ref) async {
    final result = await RevenueCatUI.presentPaywallIfNeeded(proEntitlementId);
    if (!context.mounted) return;

    switch (result) {
      case PaywallResult.purchased:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProUnlockedScreen()),
        );
      case PaywallResult.restored:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored — Pro is active.')),
        );
      case PaywallResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Something went wrong. Please try again.")),
        );
      case PaywallResult.cancelled:
      case PaywallResult.notPresented:
        break;
    }
    // customerInfoProvider updates itself via RevenueCat's own listener, so
    // no manual refresh is needed here.
  }

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    final outcome = await RevenueCatService().restorePurchases();
    if (!context.mounted) return;

    switch (outcome) {
      case PurchaseSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored.')),
        );
      case PurchaseFailed(:final message):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      case PurchaseCancelled():
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider);
    final offeringAsync = ref.watch(currentOfferingProvider);

    return Scaffold(
      appBar: appThemedAppBar(context, 'Go Pro'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      isPro ? "YOU'RE" : 'UPGRADE TO',
                      style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF888888)),
                    ),
                    Text('PRO', style: appHeadlineStyle(fontSize: 52)),
                    const SizedBox(height: 4),
                    Text(
                      isPro ? "You've got the full studio unlocked." : 'Unlock the full studio.',
                      style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _FeatureCard(
                emoji: '👥',
                title: 'Multiple leagues',
                description: 'Join and compete in as many leagues at once as you want.',
              ),
              const SizedBox(height: 12),
              const _FeatureCard(
                emoji: '📊',
                title: 'Deeper analytics',
                description: "Time spent per stage, and how you're improving over time.",
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ArtWrappedScreen()),
                ),
                child: const _ArtWrappedCard(),
              ),
              const SizedBox(height: 16),
              if (isPro) ...[
                _ManageSubscriptionButton(
                  onPressed: () => RevenueCatUI.presentCustomerCenter(),
                ),
              ] else ...[
                _PriceCard(offeringAsync: offeringAsync),
                const SizedBox(height: 16),
                _UpgradeButton(onPressed: () => _presentPaywall(context, ref)),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => _restorePurchases(context, ref),
                    child: Text(
                      'Restore purchases',
                      style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF888888)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: -1,
        onTap: (i) => goToMainTab(context, ref, i),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.emoji, required this.title, required this.description});

  final String emoji;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: appHardCardDecoration(radius: 16, shadowOffset: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: GoogleFonts.chewy(fontSize: 17, color: kInkColor)),
                const SizedBox(height: 2),
                Text(description, style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF555555))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtWrappedCard extends StatelessWidget {
  const _ArtWrappedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: appHardCardDecoration(radius: 16, shadowOffset: 3),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Art Wrapped', style: GoogleFonts.chewy(fontSize: 19, color: kInkColor)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Placeholder for the hero illustration — swap for a generated
              // asset (see the image-gen prompt shared alongside this screen).
              Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Your Year in Art',
                  style: GoogleFonts.chewy(fontSize: 16, color: kMutedColor),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Hours logged, favorite tools, trophies won — rendered as a shareable slideshow.',
                style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF555555)),
              ),
            ],
          ),
          Positioned(
            top: -14,
            right: -14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: const BoxDecoration(
                color: kAccentColor,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Text(
                'NEW',
                style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows live pricing for the monthly/yearly/lifetime packages from the
/// RevenueCat dashboard's current offering, falling back to a plain label
/// while offerings are still loading (or if fetching them failed).
class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.offeringAsync});

  final AsyncValue<Offering?> offeringAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: appHardCardDecoration(radius: 16, shadowOffset: 3),
      child: offeringAsync.when(
        data: (offering) {
          if (offering == null) {
            return Text(
              'Pricing unavailable',
              style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF888888)),
            );
          }
          return Column(
            children: [
              if (offering.monthly case final monthly?) _PriceRow('Monthly', monthly),
              if (offering.annual case final annual?) _PriceRow('Yearly', annual),
              if (offering.lifetime case final lifetime?) _PriceRow('Lifetime', lifetime),
            ],
          );
        },
        loading: () => const SizedBox(height: 28, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        error: (_, _) => Text(
          'Pricing unavailable',
          style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF888888)),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.package);

  final String label;
  final Package package;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF666666))),
          Text(
            package.storeProduct.priceString,
            style: appBodyStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kInkColor),
          ),
        ],
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  const _UpgradeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: kAccentColor,
          border: Border.all(color: kBorderColor, width: kBorderWidth),
          borderRadius: BorderRadius.circular(24),
          boxShadow: hardShadow(offset: 4),
        ),
        alignment: Alignment.center,
        child: Text('Upgrade to Pro', style: GoogleFonts.chewy(fontSize: 18, color: Colors.white)),
      ),
    );
  }
}

/// Entry point for subscribed users to view/cancel their plan or request a
/// refund via RevenueCat's Customer Center — makes sense here since it's
/// only shown once the user is already Pro.
class _ManageSubscriptionButton extends StatelessWidget {
  const _ManageSubscriptionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          border: Border.all(color: kBorderColor, width: kBorderWidth),
          borderRadius: BorderRadius.circular(24),
          boxShadow: hardShadow(offset: 4),
        ),
        alignment: Alignment.center,
        child: Text('Manage subscription', style: GoogleFonts.chewy(fontSize: 18, color: kInkColor)),
      ),
    );
  }
}
