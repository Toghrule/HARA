import '../../../l10n/app_localizations.dart';

/// Form checks shared by the sign-in and registration screens, with messages in the app's language.
/// They only catch typos early; the server makes the real decision.
class FormValidators {
  const FormValidators(this.l10n);

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final AppLocalizations l10n;

  String? required(String? value, {required int max}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return l10n.fieldRequired;

    return text.length > max ? l10n.tooLong(max) : null;
  }

  String? optional(String? value, {required int max}) =>
      (value?.trim().length ?? 0) > max ? l10n.tooLong(max) : null;

  String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return l10n.fieldRequired;

    return text.length > 320 || !_email.hasMatch(text) ? l10n.invalidEmail : null;
  }

  /// At least 8 characters with a letter and a digit — the same rule the server enforces.
  String? newPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return l10n.fieldRequired;

    final valid = text.length >= 8 && text.length <= 100 && RegExp(r'\p{L}', unicode: true).hasMatch(text) && RegExp(r'\d').hasMatch(text);

    return valid ? null : l10n.passwordRules;
  }

  String? Function(String?) sameAs(String Function() other) => (value) {
        if ((value ?? '').isEmpty) return l10n.fieldRequired;

        return value == other() ? null : l10n.passwordsDontMatch;
      };

  /// For signing in only: whatever the person typed is sent to the server, which decides.
  String? existingPassword(String? value) => (value ?? '').isEmpty ? l10n.fieldRequired : null;
}
