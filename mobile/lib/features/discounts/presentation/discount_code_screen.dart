import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/hara_ui.dart';
import '../../../l10n/app_localizations.dart';
import '../data/discount_code.dart';
import '../data/discounts_repository.dart';

/// The customer's discount code: the ticket to show the waiter, with the six hours counting down. It follows the restaurant: once the
/// restaurant confirms the code, the ticket says so.
class DiscountCodeScreen extends ConsumerStatefulWidget {
  const DiscountCodeScreen({required this.code, super.key});

  final DiscountCode code;

  @override
  ConsumerState<DiscountCodeScreen> createState() => _DiscountCodeScreenState();
}

class _DiscountCodeScreenState extends ConsumerState<DiscountCodeScreen> {
  /// How many seconds pass between asking whether the restaurant has confirmed the code, while the screen is open.
  static const _statusEverySeconds = 20;

  Timer? _clock;
  late DiscountCode _code = widget.code;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    setState(() {});

    _seconds++;
    if (_code.isUsable && _seconds % _statusEverySeconds == 0) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    try {
      final fresh = await ref.read(discountsRepositoryProvider).getStatus(_code.code);
      if (mounted) setState(() => _code = fresh);
    } catch (_) {
      // Keep what is shown; the next check tries again.
    }
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// 5:59:41, hours included: the code lasts six hours.
  static String _countdown(Duration left) => '${left.inHours}:${_two(left.inMinutes.remainder(60))}:${_two(left.inSeconds.remainder(60))}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final code = _code;

    final remaining = code.expiresAt.difference(DateTime.now());
    final left = remaining.isNegative ? Duration.zero : remaining;
    final usable = code.isUsable;
    final redeemed = code.isRedeemed;
    final ended = !usable;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.discountCodeTitle), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(code.restaurantName, style: textTheme.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    color: ended ? scheme.surfaceContainerHighest : scheme.surfaceContainerLowest,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          color: ended ? scheme.outlineVariant : scheme.primaryContainer,
                          child: Row(
                            children: [
                              Icon(Icons.local_offer_outlined, color: scheme.onPrimaryContainer),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.yourCode,
                                  style: textTheme.titleMedium?.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (code.discountPercent > 0) DiscountBadge(percent: code.discountPercent),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    code.code,
                                    key: const Key('discountCode'),
                                    style: textTheme.displayMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 8,
                                      decoration: ended ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.copyCode,
                                icon: const Icon(Icons.copy),
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(text: code.code));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.codeCopied)));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: TearLine()),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          child: Center(
                            child: redeemed
                                ? IconBadge(icon: Icons.check_circle_outline, color: Colors.green.shade700, size: 96)
                                : CountdownRing(
                                    remaining: left,
                                    total: const Duration(hours: 6),
                                    size: 128,
                                    color: usable ? null : scheme.error,
                                    child: Text(
                                      _countdown(left),
                                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: usable ? null : scheme.error),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    redeemed
                        ? l10n.discountUsedTitle
                        : usable
                            ? l10n.validFor(_countdown(left))
                            : l10n.discountExpiredTitle,
                    key: const Key('discountStatus'),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: redeemed ? Colors.green.shade700 : (usable ? null : scheme.error),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    redeemed
                        ? l10n.discountUsedText
                        : usable
                            ? l10n.showCodeWithDiscount(code.discountPercent)
                            : l10n.discountExpiredText,
                    style: textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  if (usable) ...[
                    const SizedBox(height: 8),
                    Text(l10n.discountDayNote, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 28),
                  FilledButton(
                    key: const Key('discountDone'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: () => context.pop(),
                    child: Text(l10n.done),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
