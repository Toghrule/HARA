import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'discount_code.dart';

/// A place where this phone took a discount code, with when and how much.
class TakenDiscount {
  const TakenDiscount({required this.restaurantId, required this.restaurantName, required this.percent, required this.at});

  factory TakenDiscount.fromJson(Map<String, dynamic> json) => TakenDiscount(
        restaurantId: json['id'] as String,
        restaurantName: json['name'] as String,
        percent: (json['percent'] as num?)?.toInt() ?? 0,
        at: DateTime.parse(json['at'] as String),
      );

  final String restaurantId;
  final String restaurantName;
  final int percent;
  final DateTime at;

  Map<String, dynamic> toJson() => {'id': restaurantId, 'name': restaurantName, 'percent': percent, 'at': at.toIso8601String()};
}

/// The places where this customer took a discount, newest first, kept on the phone (codes belong to the phone, not to an account).
class DiscountHistoryNotifier extends Notifier<List<TakenDiscount>> {
  static const _key = 'discount_history';
  static const _max = 50;

  @override
  List<TakenDiscount> build() {
    _load();

    return const [];
  }

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return;

      final saved = [for (final item in jsonDecode(raw) as List<dynamic>) TakenDiscount.fromJson(item as Map<String, dynamic>)];
      // Something taken while this was loading is kept.
      state = _merge(state, saved);
    } catch (_) {
      // Starts empty.
    }
  }

  /// Notes that [code] was taken. A place appears once, with its latest time.
  Future<void> add(DiscountCode code) async {
    final entry = TakenDiscount(restaurantId: code.restaurantId, restaurantName: code.restaurantName, percent: code.discountPercent, at: code.createdAt);
    state = _merge([entry], state);

    try {
      await (await SharedPreferences.getInstance()).setString(_key, jsonEncode([for (final item in state) item.toJson()]));
    } catch (_) {
      // Kept for this run only.
    }
  }

  static List<TakenDiscount> _merge(List<TakenDiscount> first, List<TakenDiscount> second) {
    final latest = <String, TakenDiscount>{};
    for (final item in [...first, ...second]) {
      final known = latest[item.restaurantId];
      if (known == null || item.at.isAfter(known.at)) latest[item.restaurantId] = item;
    }

    return (latest.values.toList()..sort((a, b) => b.at.compareTo(a.at))).take(_max).toList();
  }
}

final discountHistoryProvider = NotifierProvider<DiscountHistoryNotifier, List<TakenDiscount>>(DiscountHistoryNotifier.new);
