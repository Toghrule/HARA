import '../../../l10n/app_localizations.dart';

enum SocialPlatform {
  facebook(0, 'Facebook'),
  instagram(1, 'Instagram'),
  x(2, 'X'),
  tikTok(3, 'TikTok'),
  youTube(4, 'YouTube'),
  linkedIn(5, 'LinkedIn'),
  website(6, 'Website'),
  other(99, 'Link');

  const SocialPlatform(this.apiValue, this.label);

  final int apiValue;
  final String label;

  /// Brand names stay as they are; only the generic "Website" and "Link" are translated.
  String displayName(AppLocalizations l10n) => switch (this) {
        website => l10n.socialWebsite,
        other => l10n.socialOther,
        _ => label,
      };

  static SocialPlatform fromApi(int value) =>
      values.firstWhere((platform) => platform.apiValue == value, orElse: () => other);
}

class SocialLink {
  const SocialLink({required this.platform, required this.url});

  factory SocialLink.fromJson(Map<String, dynamic> json) => SocialLink(
        platform: SocialPlatform.fromApi((json['platform'] as num).toInt()),
        url: json['url'] as String,
      );

  final SocialPlatform platform;
  final String url;

  /// A web address to open. Admin-typed text without a scheme ("instagram.com/hara") gets `https://`;
  /// anything that isn't http(s) is refused rather than handed to the phone to open.
  Uri? get uri {
    final text = url.trim();
    final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*:').hasMatch(text);
    final parsed = Uri.tryParse(hasScheme ? text : 'https://$text');

    if (parsed == null || parsed.host.isEmpty) return null;
    return parsed.scheme == 'http' || parsed.scheme == 'https' ? parsed : null;
  }
}
