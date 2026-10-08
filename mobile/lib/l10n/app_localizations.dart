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

  /// No description provided for @yourNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name *'**
  String get yourNameLabel;

  /// No description provided for @yourPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Your phone'**
  String get yourPhoneLabel;

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

  /// No description provided for @accountTooltip.
  ///
  /// In en, this message translates to:
  /// **'Owner or waiter account'**
  String get accountTooltip;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to HARA'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to use the app.'**
  String get welcomeSubtitle;

  /// No description provided for @customerSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerSectionTitle;

  /// No description provided for @customerSectionText.
  ///
  /// In en, this message translates to:
  /// **'Find a place, reserve a table and get a discount. No account needed.'**
  String get customerSectionText;

  /// No description provided for @continueAsCustomer.
  ///
  /// In en, this message translates to:
  /// **'Continue as a customer'**
  String get continueAsCustomer;

  /// No description provided for @ownerSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Restaurant owner or waiter'**
  String get ownerSectionTitle;

  /// No description provided for @ownerSectionText.
  ///
  /// In en, this message translates to:
  /// **'Confirm customers\' codes and look after your restaurant.'**
  String get ownerSectionText;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @registerAsOwner.
  ///
  /// In en, this message translates to:
  /// **'Register as a restaurant owner'**
  String get registerAsOwner;

  /// No description provided for @registerAsStaff.
  ///
  /// In en, this message translates to:
  /// **'Register as a waiter'**
  String get registerAsStaff;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat the password'**
  String get confirmPasswordLabel;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @wrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get wrongCredentials;

  /// No description provided for @noAccountYet.
  ///
  /// In en, this message translates to:
  /// **'No account yet?'**
  String get noAccountYet;

  /// No description provided for @registerOwnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register your restaurant'**
  String get registerOwnerTitle;

  /// No description provided for @registerOwnerIntro.
  ///
  /// In en, this message translates to:
  /// **'Create your account and tell us about your restaurant. We review every registration before the restaurant appears in HARA.'**
  String get registerOwnerIntro;

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get sectionAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @passwordRules.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, with a letter and a digit.'**
  String get passwordRules;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords don\'t match.'**
  String get passwordsDontMatch;

  /// No description provided for @emailTaken.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get emailTaken;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get tooManyAttempts;

  /// No description provided for @registerStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'Register as a waiter'**
  String get registerStaffTitle;

  /// No description provided for @registerStaffIntro.
  ///
  /// In en, this message translates to:
  /// **'Pick the restaurant you work at. Its owner has to approve you before you can confirm codes.'**
  String get registerStaffIntro;

  /// No description provided for @yourRestaurantSection.
  ///
  /// In en, this message translates to:
  /// **'Your restaurant'**
  String get yourRestaurantSection;

  /// No description provided for @selectRestaurantRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick your restaurant first.'**
  String get selectRestaurantRequired;

  /// No description provided for @venueTitle.
  ///
  /// In en, this message translates to:
  /// **'Your restaurant'**
  String get venueTitle;

  /// No description provided for @pendingOwnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get pendingOwnerTitle;

  /// No description provided for @pendingOwnerText.
  ///
  /// In en, this message translates to:
  /// **'We are reviewing your registration. You will be able to confirm customers\' codes as soon as it is approved.'**
  String get pendingOwnerText;

  /// No description provided for @pendingStaffText.
  ///
  /// In en, this message translates to:
  /// **'The restaurant\'s owner has to approve you. Ask them to open the app and accept your request.'**
  String get pendingStaffText;

  /// No description provided for @rejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get rejectedTitle;

  /// No description provided for @rejectedText.
  ///
  /// In en, this message translates to:
  /// **'Your request was not approved.'**
  String get rejectedText;

  /// No description provided for @rejectedReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {note}'**
  String rejectedReason(String note);

  /// No description provided for @noVenueText.
  ///
  /// In en, this message translates to:
  /// **'This account is not linked to a restaurant.'**
  String get noVenueText;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @browseAsCustomer.
  ///
  /// In en, this message translates to:
  /// **'Browse restaurants'**
  String get browseAsCustomer;
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
