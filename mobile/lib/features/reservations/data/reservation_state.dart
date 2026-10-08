/// Where a reservation stands, as the server reports it.
enum ReservationState {
  active,
  redeemed,
  cancelled,
  expired;

  static ReservationState fromApi(int value) => switch (value) {
        0 => active,
        1 => redeemed,
        2 => cancelled,
        _ => expired,
      };
}
