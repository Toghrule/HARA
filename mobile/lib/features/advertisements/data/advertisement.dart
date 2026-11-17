import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/open_link.dart';

/// A banner the admin put in the admin panel: a picture and, if wanted, the address it opens.
class Advertisement {
  const Advertisement({required this.id, required this.imageUrl, this.title, this.linkUrl});

  factory Advertisement.fromJson(Map<String, dynamic> json) => Advertisement(
        id: json['id'] as String,
        imageUrl: json['imageUrl'] as String,
        title: json['title'] as String?,
        linkUrl: json['linkUrl'] as String?,
      );

  final String id;
  final String imageUrl;
  final String? title;
  final String? linkUrl;

  /// Full address of the picture (uploads are kept on the server and given as a path).
  Uri get imageUri => AppConstants.resolveApiUrl(imageUrl);

  /// Where a tap goes. Typed text without a scheme ("instagram.com/hara") gets `https://`; anything that is not a web address is refused
  /// rather than handed to the phone to open.
  Uri? get uri {
    final text = linkUrl?.trim() ?? '';
    if (text.isEmpty) return null;

    final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*:').hasMatch(text);
    final parsed = Uri.tryParse(hasScheme ? text : 'https://$text');
    if (parsed == null || parsed.host.isEmpty) return null;

    return parsed.scheme == 'http' || parsed.scheme == 'https' ? parsed : null;
  }
}

class AdvertisementsRepository {
  AdvertisementsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// The active banners, in the order the admin put them.
  Future<List<Advertisement>> getAdvertisements() async {
    final response = await _apiClient.dio.get<List<dynamic>>('/api/advertisements');

    return (response.data ?? []).map((json) => Advertisement.fromJson(json as Map<String, dynamic>)).toList();
  }
}

final advertisementsRepositoryProvider = Provider<AdvertisementsRepository>((ref) => AdvertisementsRepository(ref.watch(apiClientProvider)));

/// The banners for the home screen. If they cannot be loaded, there are simply none: a banner is never worth an error.
final advertisementsProvider = FutureProvider.autoDispose<List<Advertisement>>((ref) async {
  try {
    return await ref.watch(advertisementsRepositoryProvider).getAdvertisements();
  } catch (_) {
    return const [];
  }
});

/// Opens a banner's address. A provider only so tests can see what was opened without leaving the app.
final adLinkOpenerProvider = Provider<Future<void> Function(BuildContext, Uri)>((ref) => openLink);
