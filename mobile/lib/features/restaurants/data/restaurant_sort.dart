enum RestaurantSort {
  nameAsc('name_asc', 'A-Z'),
  nameDesc('name_desc', 'Z-A'),

  /// Closest first; only used while the phone's position is known.
  nearest('nearest', 'Nearest');

  const RestaurantSort(this.queryValue, this.label);

  final String queryValue;
  final String label;
}
