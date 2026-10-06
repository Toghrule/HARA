import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../restaurants/data/restaurant.dart';
import '../data/reservation.dart';
import 'widgets/reserve_sheet.dart';

/// Opens the reserve sheet for [restaurant] and, once a reservation is made,
/// shows its code screen.
Future<void> startReservation(BuildContext context, Restaurant restaurant) async {
  final reservation = await showModalBottomSheet<Reservation>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ReserveSheet(restaurant: restaurant),
  );

  if (reservation != null && context.mounted) {
    await context.push('/reservation', extra: reservation);
  }
}
