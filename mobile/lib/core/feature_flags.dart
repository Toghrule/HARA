/// Switches for parts of the app that are built but not shown. Nothing is deleted: turning a switch back on brings the part back.
class FeatureFlags {
  FeatureFlags._();

  /// Table reservations: the customer asks for a table, the restaurant accepts, a code with a hold timer. Postponed: for now the
  /// app is about discovering places and getting a discount code (see the discount code feature). Set to `true` to bring the whole
  /// reservation flow back (the reserve buttons and sheet, the reservation cards and screen, the restaurant's "Requests" and
  /// "Reservations" tabs).
  ///
  /// A plain variable, not a constant, only so the tests of the reservation flow can switch it on.
  static bool reservationsEnabled = false;
}
