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

  String get title {
    final text = label?.trim();
    if (text != null && text.isNotEmpty) return text;

    return switch (type) {
      ContactType.phone => 'Phone',
      ContactType.email => 'Email',
      ContactType.other => 'Contact',
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
