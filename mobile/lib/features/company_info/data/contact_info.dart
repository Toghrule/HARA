import '../../../l10n/app_localizations.dart';

enum ContactType {
  phone,
  email,
  other;

  static ContactType fromApi(int value) => switch (value) {
        0 => phone,
        1 => email,
        _ => other,
      };
}

class ContactInfo {
  const ContactInfo({required this.type, required this.value, this.label});

  factory ContactInfo.fromJson(Map<String, dynamic> json) => ContactInfo(
        type: ContactType.fromApi((json['type'] as num).toInt()),
        value: json['value'] as String,
        label: json['label'] as String?,
      );

  final ContactType type;
  final String value;
  final String? label;

  /// The admin-typed label, or the contact type in the app's language when there is none.
  String title(AppLocalizations l10n) {
    final text = label?.trim();
    if (text != null && text.isNotEmpty) return text;

    return switch (type) {
      ContactType.phone => l10n.contactPhone,
      ContactType.email => l10n.contactEmail,
      ContactType.other => l10n.contactOther,
    };
  }

  /// What tapping this contact should open (dialer or mail app), or `null` if the value isn't usable.
  Uri? get uri {
    final text = value.trim();

    switch (type) {
      case ContactType.phone:
        final number = text.replaceAll(RegExp(r'[^\d+]'), '');
        return number.isEmpty ? null : Uri(scheme: 'tel', path: number);
      case ContactType.email:
        return text.contains('@') ? Uri(scheme: 'mailto', path: text) : null;
      case ContactType.other:
        return null;
    }
  }
}
