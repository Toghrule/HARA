import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_az.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('az'),
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @errorCantReachServer.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server. Check your connection and try again.'**
  String get errorCantReachServer;

  /// No description provided for @errorSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorSomethingWrong;

  /// No description provided for @couldntOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this link.'**
  String get couldntOpenLink;

  /// No description provided for @aboutTooltip.
  ///
  /// In en, this message translates to:
  /// **'About us, contact and FAQ'**
  String get aboutTooltip;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or address'**
  String get searchHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @couldntLoadRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load restaurants.\n{error}'**
  String couldntLoadRestaurants(String error);

  /// No description provided for @couldntLoadMoreRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load more restaurants.\n{error}'**
  String couldntLoadMoreRestaurants(String error);

  /// No description provided for @noRestaurantsYet.
  ///
  /// In en, this message translates to:
  /// **'No restaurants yet.'**
  String get noRestaurantsYet;

  /// No description provided for @noRestaurantsMatch.
  ///
  /// In en, this message translates to:
  /// **'No restaurants match \"{search}\".'**
  String noRestaurantsMatch(String search);

  /// No description provided for @ownRestaurantAddIt.
  ///
  /// In en, this message translates to:
  /// **'Own a restaurant? Add it to HARA'**
  String get ownRestaurantAddIt;

  /// No description provided for @ownRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Own a restaurant?'**
  String get ownRestaurant;

  /// No description provided for @addItToHara.
  ///
  /// In en, this message translates to:
  /// **'Add it to HARA'**
  String get addItToHara;

  /// No description provided for @discountWithCode.
  ///
  /// In en, this message translates to:
  /// **'{percent}% off with a reservation code'**
  String discountWithCode(int percent);

  /// No description provided for @openInGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get openInGoogleMaps;

  /// No description provided for @reserve.
  ///
  /// In en, this message translates to:
  /// **'Reserve'**
  String get reserve;

  /// No description provided for @restaurantFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get restaurantFallbackTitle;

  /// No description provided for @restaurantNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This restaurant is no longer available.'**
  String get restaurantNoLongerAvailable;

  /// No description provided for @reserveTable.
  ///
  /// In en, this message translates to:
  /// **'Reserve a table'**
  String get reserveTable;

  /// No description provided for @reserveSheetFreeWithDiscount.
  ///
  /// In en, this message translates to:
  /// **'Free. Show your code at the venue to get {percent}% off your bill.'**
  String reserveSheetFreeWithDiscount(int percent);

  /// No description provided for @reserveSheetFree.
  ///
  /// In en, this message translates to:
  /// **'Free. Show your code at the venue when you arrive.'**
  String get reserveSheetFree;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @holdTableFor.
  ///
  /// In en, this message translates to:
  /// **'Hold the table for'**
  String get holdTableFor;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesShort(int count);

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number, e.g. +994 50 123 45 67.'**
  String get invalidPhone;

  /// No description provided for @yourReservation.
  ///
  /// In en, this message translates to:
  /// **'Your reservation'**
  String get yourReservation;

  /// No description provided for @yourCode.
  ///
  /// In en, this message translates to:
  /// **'Your code'**
  String get yourCode;

  /// No description provided for @activeReservationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Code {code} · {countdown} left'**
  String activeReservationSubtitle(String code, String countdown);

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// No description provided for @reservationExpired.
  ///
  /// In en, this message translates to:
  /// **'This reservation has expired'**
  String get reservationExpired;

  /// No description provided for @reservationEnded.
  ///
  /// In en, this message translates to:
  /// **'This reservation is no longer active'**
  String get reservationEnded;

  /// No description provided for @validFor.
  ///
  /// In en, this message translates to:
  /// **'Valid for {countdown}'**
  String validFor(String countdown);

  /// No description provided for @tableHeldUntil.
  ///
  /// In en, this message translates to:
  /// **'Table held until {time} ({minutes} min)'**
  String tableHeldUntil(String time, int minutes);

  /// No description provided for @showCodeWithDiscount.
  ///
  /// In en, this message translates to:
  /// **'Show this code at the venue when you arrive to get {percent}% off your bill.'**
  String showCodeWithDiscount(int percent);

  /// No description provided for @showCode.
  ///
  /// In en, this message translates to:
  /// **'Show this code at the venue when you arrive.'**
  String get showCode;

  /// No description provided for @cancelReservationTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel reservation?'**
  String get cancelReservationTitle;

  /// No description provided for @cancelReservationBody.
  ///
  /// In en, this message translates to:
  /// **'Your code will stop working and the table will be released. You can make a new reservation afterwards.'**
  String get cancelReservationBody;

  /// No description provided for @keepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get keepIt;

  /// No description provided for @cancelReservation.
  ///
  /// In en, this message translates to:
  /// **'Cancel reservation'**
  String get cancelReservation;

  /// No description provided for @reservationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Reservation cancelled'**
  String get reservationCancelled;

  /// No description provided for @reservationNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find this reservation.'**
  String get reservationNotFound;

  /// No description provided for @addYourRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Add your restaurant'**
  String get addYourRestaurant;

  /// No description provided for @submitIntro.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your restaurant. We review every request before it appears in HARA.'**
  String get submitIntro;

  /// No description provided for @sectionRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get sectionRestaurant;

  /// No description provided for @restaurantNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Restaurant name *'**
  String get restaurantNameLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @restaurantPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Restaurant phone'**
  String get restaurantPhoneLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @sectionAboutYou.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get sectionAboutYou;

  /// No description provided for @yourNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name *'**
  String get yourNameLabel;

  /// No description provided for @yourEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Your email'**
  String get yourEmailLabel;

  /// No description provided for @yourPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Your phone'**
  String get yourPhoneLabel;

  /// No description provided for @contactHint.
  ///
  /// In en, this message translates to:
  /// **'Email or phone — at least one, so we can follow up.'**
  String get contactHint;

  /// No description provided for @contactRequired.
  ///
  /// In en, this message translates to:
  /// **'Add an email or a phone number so we can reach you.'**
  String get contactRequired;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequest;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get thankYou;

  /// No description provided for @requestReceived.
  ///
  /// In en, this message translates to:
  /// **'We received your request for \"{name}\". Our team will review it and get in touch using the contact details you gave us.'**
  String requestReceived(String name);

  /// No description provided for @backToRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Back to restaurants'**
  String get backToRestaurants;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @tooLong.
  ///
  /// In en, this message translates to:
  /// **'Too long (max {max} characters)'**
  String tooLong(int max);

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About us'**
  String get aboutUs;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get faqTitle;

  /// No description provided for @moreAboutUsSoon.
  ///
  /// In en, this message translates to:
  /// **'More about us is coming soon.'**
  String get moreAboutUsSoon;

  /// No description provided for @followUs.
  ///
  /// In en, this message translates to:
  /// **'Follow us'**
  String get followUs;

  /// No description provided for @noContactDetails.
  ///
  /// In en, this message translates to:
  /// **'No contact details yet.'**
  String get noContactDetails;

  /// No description provided for @noQuestionsYet.
  ///
  /// In en, this message translates to:
  /// **'No questions yet.'**
  String get noQuestionsYet;

  /// No description provided for @contactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get contactPhone;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contactEmail;

  /// No description provided for @contactOther.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactOther;

  /// No description provided for @socialWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get socialWebsite;

  /// No description provided for @socialOther.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get socialOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['az', 'en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'az':
      return AppLocalizationsAz();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
