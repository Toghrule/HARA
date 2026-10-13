/// Where a reservation stands, as the server reports it. The order matches the server's numbers
/// (0 active … 6 unanswered), so an index is also what the API expects in a status filter.
enum ReservationState {
  /// Accepted by the restaurant: the code is usable and the hold timer is running.
  active,
  redeemed,
  cancelled,

  /// Accepted, but the hold time ran out.
  expired,

  /// Sent and waiting for the restaurant to answer; the hold timer has not started.
  pending,

  /// The restaurant declined the request.
  declined,

  /// Nobody at the restaurant answered in time.
  unanswered;

  static ReservationState fromApi(int value) => switch (value) {
        0 => active,
        1 => redeemed,
        2 => cancelled,
        3 => expired,
        4 => pending,
        5 => declined,
        _ => unanswered,
      };

  /// Still going: waiting for an answer, or accepted and not over.
  bool get isInProgress => this == pending || this == active;
}
