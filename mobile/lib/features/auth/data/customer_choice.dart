import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _preferenceKey = 'continued_as_customer';

/// Whether this person already chose "Continue as a customer" on the welcome screen, so the app opens
/// straight to the restaurants from then on instead of asking again. Storage trouble means asking again.
Future<bool> loadContinuedAsCustomer() async {
  try {
    return (await SharedPreferences.getInstance()).getBool(_preferenceKey) ?? false;
  } catch (_) {
    return false;
  }
}

class CustomerChoice extends StateNotifier<bool> {
  CustomerChoice(super.initial);

  Future<void> choose() async {
    if (state) return;

    state = true;
    try {
      await (await SharedPreferences.getInstance()).setBool(_preferenceKey, true);
    } catch (_) {
      // The choice still holds for this run.
    }
  }
}

final customerChoiceProvider = StateNotifierProvider<CustomerChoice, bool>((ref) => CustomerChoice(false));
