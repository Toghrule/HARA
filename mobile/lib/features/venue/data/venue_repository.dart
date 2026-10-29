import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../reservations/data/reservation_state.dart';
import '../../restaurants/data/opening_hours.dart';
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

  /// Accepts the current legal texts that are still pending. A version of `0` is for a text that is not pending.
  Future<void> acceptTerms({required int termsVersion, required int venueAgreementVersion}) async {
    await _apiClient.dio.post<void>('/api/venue/terms/accept', data: {'termsVersion': termsVersion, 'venueAgreementVersion': venueAgreementVersion});
  }

  /// The numbers for the statistics tab.
  Future<VenueStats> getStats() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/api/venue/stats');

    return VenueStats.fromJson(response.data!);
  }

  /// Owner only: sets the restaurant's opening hours (all seven days, or an empty list to remove them), and how many
  /// minutes before closing it stops taking requests. Applies at once.
  Future<void> updateOpeningHours({required List<DayHours> days, required int lastRequestMinutesBeforeClose}) async {
    await _apiClient.dio.put<void>('/api/venue/opening-hours', data: {
      'days': [for (final day in days) day.toJson()],
      'lastRequestMinutesBeforeClose': lastRequestMinutesBeforeClose,
    });
  }

  /// Looks up a code a customer shows. Only codes of this restaurant are found.
  Future<VenueReservation> lookup(String code) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/api/venue/reservations/${Uri.encodeComponent(code)}');

    return VenueReservation.fromJson(response.data!);
  }

  /// Accepts a customer's request: the hold timer starts now and the customer gets their code.
  Future<VenueReservation> accept(String code) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>('/api/venue/reservations/${Uri.encodeComponent(code)}/accept');

    return VenueReservation.fromJson(response.data!);
  }

  /// Declines a customer's request.
  Future<VenueReservation> decline(String code) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>('/api/venue/reservations/${Uri.encodeComponent(code)}/decline');

    return VenueReservation.fromJson(response.data!);
  }

  /// Confirms a code: the customer is here and gets the discount. A code can only be confirmed once.
  Future<VenueReservation> redeem(String code) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>('/api/venue/reservations/${Uri.encodeComponent(code)}/redeem');

    return VenueReservation.fromJson(response.data!);
  }

  /// This phone should be notified about new requests while the signed-in person is on it.
  Future<void> registerDevice(String token, String language) async {
    await _apiClient.dio.post<void>('/api/venue/devices', data: {'token': token, 'language': language});
  }

  /// This phone should no longer get the signed-in person's notifications (they are signing out).
  Future<void> unregisterDevice(String token) async {
    await _apiClient.dio.post<void>('/api/venue/devices/unregister', data: {'token': token});
  }

  /// Deletes the signed-in person's own account. The password is asked for again.
  Future<void> deleteAccount(String password) async {
    await _apiClient.dio.post<void>('/api/auth/delete-account', data: {'password': password});
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
