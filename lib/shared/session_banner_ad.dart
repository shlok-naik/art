import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../features/pro/providers.dart';
import 'ads_service.dart';

/// A banner ad shown under the session timer while a session is running.
/// Hidden entirely for "Unfinished Pro" subscribers (see [isProProvider]) —
/// ads are a free-tier-only monetization lever, not a Pro one.
class SessionBannerAd extends ConsumerStatefulWidget {
  const SessionBannerAd({super.key});

  @override
  ConsumerState<SessionBannerAd> createState() => _SessionBannerAdState();
}

class _SessionBannerAdState extends ConsumerState<SessionBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (AdsService.isSupported) _loadAd();
  }

  void _loadAd() {
    final ad = AdsService().createSessionBannerAd(
      onLoaded: (_) {
        if (mounted) setState(() => _isLoaded = true);
      },
      onFailedToLoad: (_) {
        if (mounted) setState(() => _isLoaded = false);
      },
    );
    _bannerAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider);
    final ad = _bannerAd;
    if (isPro || !AdsService.isSupported || ad == null || !_isLoaded) {
      return const SizedBox.shrink();
    }
    return Container(
      alignment: Alignment.center,
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
