import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../data/advertisement.dart';

/// The admin's banners, one at a time in a row you can swipe (they also turn by themselves). A tap opens the banner's address, if it has one.
/// Marked "Ad" so nobody takes it for a restaurant.
class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({required this.ads, super.key});

  final List<Advertisement> ads;

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  static const _turnEvery = Duration(seconds: 6);

  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.ads.length > 1) {
      _timer = Timer.periodic(_turnEvery, (_) {
        if (!mounted || !_controller.hasClients) return;
        final next = (_page + 1) % widget.ads.length;
        _controller.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ads = widget.ads;

    return Padding(
      key: const Key('adBanner'),
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PageView.builder(
                controller: _controller,
                itemCount: ads.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) {
                  final ad = ads[index];
                  final uri = ad.uri;
                  final placeholder = ColoredBox(color: scheme.surfaceContainerHigh, child: Icon(Icons.campaign_outlined, color: scheme.onSurfaceVariant));

                  return GestureDetector(
                    key: Key('ad-${ad.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: uri == null ? null : () => ref.read(adLinkOpenerProvider)(context, uri),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          ad.imageUri.toString(),
                          fit: BoxFit.cover,
                          semanticLabel: ad.title,
                          errorBuilder: (context, error, stackTrace) => placeholder,
                          loadingBuilder: (context, child, progress) => progress == null ? child : placeholder,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                            child: Text(l10n.adLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (ads.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < ads.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(color: i == _page ? scheme.primary : scheme.outlineVariant, borderRadius: BorderRadius.circular(3)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
