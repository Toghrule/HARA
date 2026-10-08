import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../reservations/data/reservation_state.dart';
import 'venue_me.dart';
import 'venue_models.dart';

/// The restaurant-side API. Every call needs a signed-in owner or waiter; the client adds their token.
class VenueRepository {
  VenueRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<VenueMe> getMe() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/api/venue/me');

    return VenueMe.fromJson(response.data!);
  }

  /// The restaurant's reservations, newest first; only those in [status] when given.
  Future<List<VenueReservation>> getReservations({ReservationState? status}) async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/venue/reservations',
      queryParameters: {if (status != null) 'status': status.index},
    );

    return (response.data ?? []).map((json) => VenueReservation.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Looks up a code a customer shows. Only codes of this restaurant are found.
  Future<VenueReservation> lookup(String code) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/api/venue/reservations/${Uri.encodeComponent(code)}');

    return VenueReservation.fromJson(response.data!);
  }

  /// Confirms a code: the customer is here and gets the discount. A code can only be confirmed once.
  Future<VenueReservation> redeem(String code) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>('/api/venue/reservations/${Uri.encodeComponent(code)}/redeem');

    return VenueReservation.fromJson(response.data!);
  }

  // Owner only.

  Future<List<StaffMember>> getStaff() async {
    final response = await _apiClient.dio.get<List<dynamic>>('/api/venue/staff');

    return (response.data ?? []).map((json) => StaffMember.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> approveStaff(String id) async {
    await _apiClient.dio.post<void>('/api/venue/staff/$id/approve');
  }

  Future<void> rejectStaff(String id) async {
    await _apiClient.dio.post<void>('/api/venue/staff/$id/reject');
  }

  /// Removes a waiter (or clears a declined request); their account is deleted too.
  Future<void> removeStaff(String id) async {
    await _apiClient.dio.delete<void>('/api/venue/staff/$id');
  }

  Future<List<ChangeRequest>> getChangeRequests() async {
    final response = await _apiClient.dio.get<List<dynamic>>('/api/venue/change-requests');

    return (response.data ?? []).map((json) => ChangeRequest.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Asks HARA to change the restaurant. Fields left `null` stay as they are.
  Future<void> createChangeRequest({
    String? name,
    String? address,
    String? phoneNumber,
    String? description,
    String? descriptionRu,
    String? descriptionEn,
    int? discountPercent,
    String? ownerNote,
  }) async {
    await _apiClient.dio.post<void>('/api/venue/change-requests', data: {
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (description != null) 'description': description,
      if (descriptionRu != null) 'descriptionRu': descriptionRu,
      if (descriptionEn != null) 'descriptionEn': descriptionEn,
      if (discountPercent != null) 'discountPercent': discountPercent,
      if (ownerNote != null) 'ownerNote': ownerNote,
    });
  }
}

final venueRepositoryProvider = Provider<VenueRepository>((ref) => VenueRepository(ref.watch(apiClientProvider)));
