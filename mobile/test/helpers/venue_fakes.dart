import 'package:dio/dio.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/venue/data/venue_me.dart';
import 'package:hara/features/venue/data/venue_repository.dart';

VenueMe approvedOwner() => const VenueMe(
      isOwner: true,
      status: VenueStatus.approved,
      fullName: 'Anar Aliyev',
      restaurant: VenueRestaurant(id: 'rest-1', name: 'Cafe One', address: 'Baku, Nizami 1', discountPercent: 10),
    );

VenueMe approvedStaff() => const VenueMe(
      isOwner: false,
      status: VenueStatus.approved,
      fullName: 'Waiter Wali',
      restaurant: VenueRestaurant(id: 'rest-1', name: 'Cafe One', address: 'Baku, Nizami 1', discountPercent: 10),
    );

VenueMe pendingOwner() => const VenueMe(isOwner: true, status: VenueStatus.pending, fullName: 'Anar Aliyev');

VenueMe pendingStaff() => const VenueMe(isOwner: false, status: VenueStatus.pending, fullName: 'Waiter Wali');

VenueMe rejectedOwner({String? note}) =>
    VenueMe(isOwner: true, status: VenueStatus.rejected, fullName: 'Anar Aliyev', note: note);

VenueMe noVenue() => const VenueMe(isOwner: false, status: VenueStatus.none);

/// A fake restaurant-side API that answers `GET /api/venue/me` from a script.
class FakeVenueRepository extends VenueRepository {
  FakeVenueRepository({required this.me}) : super(ApiClient());

  VenueMe me;
  int meCalls = 0;
  Object? meError;

  @override
  Future<VenueMe> getMe() async {
    meCalls++;
    if (meError != null) throw meError!;

    return me;
  }
}

extension DioExceptionWithoutResponse on DioException {
  /// The same error as if the server had not answered at all.
  DioException copyWithoutResponse() => DioException(requestOptions: requestOptions);
}
