enum RestaurantSort {
  nameAsc('name_asc', 'A-Z'),
  nameDesc('name_desc', 'Z-A');

  const RestaurantSort(this.queryValue, this.label);

  final String queryValue;
  final String label;
}
