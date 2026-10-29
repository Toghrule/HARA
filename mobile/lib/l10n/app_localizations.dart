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

  /// No description provided for @tabConfirmCode.
  ///
  /// In en, this message translates to:
  /// **'Confirm code'**
  String get tabConfirmCode;

  /// No description provided for @tabReservations.
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get tabReservations;

  /// No description provided for @tabStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get tabStats;

  /// No description provided for @tabTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get tabTeam;

  /// No description provided for @tabRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get tabRestaurant;

  /// No description provided for @codeInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer\'s code'**
  String get codeInputLabel;

  /// No description provided for @checkCode.
  ///
  /// In en, this message translates to:
  /// **'Check the code'**
  String get checkCode;

  /// No description provided for @codeNotFoundHere.
  ///
  /// In en, this message translates to:
  /// **'This code was not found at your restaurant.'**
  String get codeNotFoundHere;

  /// No description provided for @giveDiscount.
  ///
  /// In en, this message translates to:
  /// **'Give {percent}% off the bill.'**
  String giveDiscount(int percent);

  /// No description provided for @noDiscountHere.
  ///
  /// In en, this message translates to:
  /// **'This restaurant has no discount.'**
  String get noDiscountHere;

  /// No description provided for @customerPhoneLine.
  ///
  /// In en, this message translates to:
  /// **'Customer\'s phone: {phone}'**
  String customerPhoneLine(String phone);

  /// No description provided for @validUntilLine.
  ///
  /// In en, this message translates to:
  /// **'Valid until {time}'**
  String validUntilLine(String time);

  /// No description provided for @confirmCode.
  ///
  /// In en, this message translates to:
  /// **'Confirm the code'**
  String get confirmCode;

  /// No description provided for @confirmCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm this code?'**
  String get confirmCodeTitle;

  /// No description provided for @confirmCodeBody.
  ///
  /// In en, this message translates to:
  /// **'The customer is here and gets the discount. A confirmed code cannot be used again.'**
  String get confirmCodeBody;

  /// No description provided for @codeConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Code confirmed'**
  String get codeConfirmed;

  /// No description provided for @codeConfirmedDetail.
  ///
  /// In en, this message translates to:
  /// **'Apply the discount to the customer\'s bill.'**
  String get codeConfirmedDetail;

  /// No description provided for @reservationStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get reservationStatusActive;

  /// No description provided for @reservationStatusRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Already used'**
  String get reservationStatusRedeemed;

  /// No description provided for @reservationStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by the customer'**
  String get reservationStatusCancelled;

  /// No description provided for @reservationStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get reservationStatusExpired;

  /// No description provided for @filterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get filterActive;

  /// No description provided for @filterUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get filterUsed;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @noReservationsHere.
  ///
  /// In en, this message translates to:
  /// **'No reservations here.'**
  String get noReservationsHere;

  /// No description provided for @waitingForYou.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your approval'**
  String get waitingForYou;

  /// No description provided for @teamMembers.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get teamMembers;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleStaff.
  ///
  /// In en, this message translates to:
  /// **'Waiter'**
  String get roleStaff;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @removeStaff.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeStaff;

  /// No description provided for @removeStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeStaffTitle(String name);

  /// No description provided for @removeStaffBody.
  ///
  /// In en, this message translates to:
  /// **'They will no longer be able to sign in.'**
  String get removeStaffBody;

  /// No description provided for @declinedLabel.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declinedLabel;

  /// No description provided for @noStaffYet.
  ///
  /// In en, this message translates to:
  /// **'No waiters yet. They can register in the app and pick your restaurant.'**
  String get noStaffYet;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @discountLine.
  ///
  /// In en, this message translates to:
  /// **'Discount: {percent}%'**
  String discountLine(int percent);

  /// No description provided for @changeRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your change requests'**
  String get changeRequestsTitle;

  /// No description provided for @requestAChange.
  ///
  /// In en, this message translates to:
  /// **'Request a change'**
  String get requestAChange;

  /// No description provided for @noChangeRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests yet.'**
  String get noChangeRequests;

  /// No description provided for @changeRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for review'**
  String get changeRequestPending;

  /// No description provided for @changeRequestApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get changeRequestApproved;

  /// No description provided for @changeRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get changeRequestRejected;

  /// No description provided for @adminReply.
  ///
  /// In en, this message translates to:
  /// **'Reply: {note}'**
  String adminReply(String note);

  /// No description provided for @changeRequestIntro.
  ///
  /// In en, this message translates to:
  /// **'You can\'t edit your restaurant directly. Fill in only what you want changed; HARA reviews the request and applies it.'**
  String get changeRequestIntro;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount (%)'**
  String get discountLabel;

  /// No description provided for @descriptionAzLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (Azerbaijani)'**
  String get descriptionAzLabel;

  /// No description provided for @descriptionRuLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (Russian)'**
  String get descriptionRuLabel;

  /// No description provided for @descriptionEnLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (English)'**
  String get descriptionEnLabel;

  /// No description provided for @noteForHara.
  ///
  /// In en, this message translates to:
  /// **'Note for HARA (optional)'**
  String get noteForHara;

  /// No description provided for @currentValue.
  ///
  /// In en, this message translates to:
  /// **'Now: {value}'**
  String currentValue(String value);

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequest;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent. HARA will review it.'**
  String get requestSent;

  /// No description provided for @askForOneChange.
  ///
  /// In en, this message translates to:
  /// **'Fill in at least one field.'**
  String get askForOneChange;

  /// No description provided for @discountRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 0 to 100.'**
  String get discountRange;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @accountMenu.
  ///
  /// In en, this message translates to:
  /// **'Account menu'**
  String get accountMenu;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your name, email and phone number will be removed and you will lose access. If you are a restaurant owner, the restaurant stays listed in HARA. This cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm.'**
  String get deleteAccountPasswordHint;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountConfirm;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password.'**
  String get wrongPassword;

  /// No description provided for @tooManyWrongPasswords.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong attempts. Please try again later.'**
  String get tooManyWrongPasswords;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account was deleted.'**
  String get accountDeleted;

  /// No description provided for @requestNotice.
  ///
  /// In en, this message translates to:
  /// **'The restaurant confirms your request first. After that we hold your table for {duration}.'**
  String requestNotice(String duration);

  /// No description provided for @waitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the restaurant'**
  String get waitingTitle;

  /// No description provided for @waitingText.
  ///
  /// In en, this message translates to:
  /// **'We sent your request to {restaurant}. As soon as they confirm it, your code appears here and the {minutes} minutes start.'**
  String waitingText(String restaurant, int minutes);

  /// No description provided for @waitingCountdown.
  ///
  /// In en, this message translates to:
  /// **'The restaurant has {countdown} to answer'**
  String waitingCountdown(String countdown);

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequest;

  /// No description provided for @cancelRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel your request?'**
  String get cancelRequestTitle;

  /// No description provided for @cancelRequestBody.
  ///
  /// In en, this message translates to:
  /// **'The restaurant will no longer see it and you can send a new one.'**
  String get cancelRequestBody;

  /// No description provided for @requestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get requestCancelled;

  /// No description provided for @confirmedByRestaurant.
  ///
  /// In en, this message translates to:
  /// **'The restaurant confirmed your table'**
  String get confirmedByRestaurant;

  /// No description provided for @declinedTitle.
  ///
  /// In en, this message translates to:
  /// **'The restaurant declined your request'**
  String get declinedTitle;

  /// No description provided for @declinedText.
  ///
  /// In en, this message translates to:
  /// **'You can try another restaurant or try again later.'**
  String get declinedText;

  /// No description provided for @unansweredTitle.
  ///
  /// In en, this message translates to:
  /// **'No answer from the restaurant'**
  String get unansweredTitle;

  /// No description provided for @unansweredText.
  ///
  /// In en, this message translates to:
  /// **'The restaurant did not answer in time. You can send a new request.'**
  String get unansweredText;

  /// No description provided for @bannerWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the restaurant · {countdown}'**
  String bannerWaiting(String countdown);

  /// No description provided for @bannerDeclined.
  ///
  /// In en, this message translates to:
  /// **'{restaurant} declined your request'**
  String bannerDeclined(String restaurant);

  /// No description provided for @bannerUnanswered.
  ///
  /// In en, this message translates to:
  /// **'{restaurant} did not answer'**
  String bannerUnanswered(String restaurant);

  /// No description provided for @closeNotice.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeNotice;

  /// No description provided for @tabRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get tabRequests;

  /// No description provided for @reservationStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your answer'**
  String get reservationStatusPending;

  /// No description provided for @reservationStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get reservationStatusDeclined;

  /// No description provided for @reservationStatusUnanswered.
  ///
  /// In en, this message translates to:
  /// **'Not answered in time'**
  String get reservationStatusUnanswered;

  /// No description provided for @noRequestsWaiting.
  ///
  /// In en, this message translates to:
  /// **'No requests waiting.'**
  String get noRequestsWaiting;

  /// No description provided for @acceptRequest.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptRequest;

  /// No description provided for @sentAt.
  ///
  /// In en, this message translates to:
  /// **'Sent {time}'**
  String sentAt(String time);

  /// No description provided for @answerWithin.
  ///
  /// In en, this message translates to:
  /// **'Answer within {countdown}'**
  String answerWithin(String countdown);

  /// No description provided for @requestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted. The customer\'s {minutes} minutes have started.'**
  String requestAccepted(int minutes);

  /// No description provided for @requestDeclinedDone.
  ///
  /// In en, this message translates to:
  /// **'Declined.'**
  String get requestDeclinedDone;

  /// No description provided for @statsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statsToday;

  /// No description provided for @statsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get statsThisMonth;

  /// No description provided for @statsThisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get statsThisYear;

  /// No description provided for @statsAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statsAccepted;

  /// No description provided for @statsCame.
  ///
  /// In en, this message translates to:
  /// **'Came'**
  String get statsCame;

  /// No description provided for @statsMyToday.
  ///
  /// In en, this message translates to:
  /// **'Codes you confirmed today'**
  String get statsMyToday;

  /// No description provided for @statsHint.
  ///
  /// In en, this message translates to:
  /// **'Accepted: requests your restaurant said yes to. Came: customers whose code was confirmed at the restaurant.'**
  String get statsHint;

  /// No description provided for @availOpenUntil.
  ///
  /// In en, this message translates to:
  /// **'Open until {time}'**
  String availOpenUntil(String time);

  /// No description provided for @availClosingSoon.
  ///
  /// In en, this message translates to:
  /// **'Closing at {time}, not taking requests now'**
  String availClosingSoon(String time);

  /// No description provided for @availClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get availClosed;

  /// No description provided for @availClosedOpensToday.
  ///
  /// In en, this message translates to:
  /// **'Closed, opens today at {time}'**
  String availClosedOpensToday(String time);

  /// No description provided for @availClosedOpensTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Closed, opens tomorrow at {time}'**
  String availClosedOpensTomorrow(String time);

  /// No description provided for @availClosedOpensOn.
  ///
  /// In en, this message translates to:
  /// **'Closed, opens {day} at {time}'**
  String availClosedOpensOn(String day, String time);

  /// No description provided for @weekdayName.
  ///
  /// In en, this message translates to:
  /// **'{day, select, 0{Sunday} 1{Monday} 2{Tuesday} 3{Wednesday} 4{Thursday} 5{Friday} 6{Saturday} other{}}'**
  String weekdayName(String day);

  /// No description provided for @weekdayOn.
  ///
  /// In en, this message translates to:
  /// **'{day, select, 0{on Sunday} 1{on Monday} 2{on Tuesday} 3{on Wednesday} 4{on Thursday} 5{on Friday} 6{on Saturday} other{}}'**
  String weekdayOn(String day);

  /// No description provided for @openingHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Opening hours'**
  String get openingHoursTitle;

  /// No description provided for @hoursClosedDay.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get hoursClosedDay;

  /// No description provided for @hoursAllDay.
  ///
  /// In en, this message translates to:
  /// **'Open 24 hours'**
  String get hoursAllDay;

  /// No description provided for @hoursNotSet.
  ///
  /// In en, this message translates to:
  /// **'No opening hours set: the restaurant counts as always open.'**
  String get hoursNotSet;

  /// No description provided for @editOpeningHours.
  ///
  /// In en, this message translates to:
  /// **'Edit opening hours'**
  String get editOpeningHours;

  /// No description provided for @hoursOpenSwitch.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get hoursOpenSwitch;

  /// No description provided for @hoursOpens.
  ///
  /// In en, this message translates to:
  /// **'Opens'**
  String get hoursOpens;

  /// No description provided for @hoursCloses.
  ///
  /// In en, this message translates to:
  /// **'Closes'**
  String get hoursCloses;

  /// No description provided for @hoursLastRequest.
  ///
  /// In en, this message translates to:
  /// **'Stop taking requests before closing'**
  String get hoursLastRequest;

  /// No description provided for @hoursLeadMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min before closing'**
  String hoursLeadMinutes(int minutes);

  /// No description provided for @hoursLeadAtClose.
  ///
  /// In en, this message translates to:
  /// **'Until closing time'**
  String get hoursLeadAtClose;

  /// No description provided for @hoursSameEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Same hours every day'**
  String get hoursSameEveryDay;

  /// No description provided for @hoursRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove hours (always open)'**
  String get hoursRemove;

  /// No description provided for @hoursSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get hoursSave;

  /// No description provided for @hoursSaved.
  ///
  /// In en, this message translates to:
  /// **'Opening hours saved.'**
  String get hoursSaved;

  /// No description provided for @hoursHint.
  ///
  /// In en, this message translates to:
  /// **'Times are Azerbaijan time. If you close after midnight (18:00 to 02:00), just set the later closing time. The same opening and closing time means open all day.'**
  String get hoursHint;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Owner forgot the password?'**
  String get forgotPasswordLink;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset the password'**
  String get resetTitle;

  /// No description provided for @resetIntro.
  ///
  /// In en, this message translates to:
  /// **'For restaurant owners. Enter the email you signed up with. HARA will contact you to make sure it is you, and then you can choose a new password here.'**
  String get resetIntro;

  /// No description provided for @resetSend.
  ///
  /// In en, this message translates to:
  /// **'Send the request'**
  String get resetSend;

  /// No description provided for @resetWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for HARA'**
  String get resetWaitingTitle;

  /// No description provided for @resetWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'Your request for {email} was sent. HARA will contact you to confirm it is you. You can leave this screen: when you come back it will ask for the new password as soon as the request is approved.'**
  String resetWaitingBody(String email);

  /// No description provided for @resetCheckNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get resetCheckNow;

  /// No description provided for @resetCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel the request'**
  String get resetCancel;

  /// No description provided for @resetApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get resetApprovedTitle;

  /// No description provided for @resetApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'HARA confirmed it is you. Choose a new password; this stays open for one hour.'**
  String get resetApprovedBody;

  /// No description provided for @resetNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get resetNewPasswordLabel;

  /// No description provided for @resetSave.
  ///
  /// In en, this message translates to:
  /// **'Save the new password'**
  String get resetSave;

  /// No description provided for @resetDone.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Sign in with the new password.'**
  String get resetDone;

  /// No description provided for @resetRejected.
  ///
  /// In en, this message translates to:
  /// **'HARA did not approve this request. If it is really you, contact HARA and ask again.'**
  String get resetRejected;

  /// No description provided for @resetAskAgain.
  ///
  /// In en, this message translates to:
  /// **'Ask again'**
  String get resetAskAgain;

  /// No description provided for @resetNoLongerValid.
  ///
  /// In en, this message translates to:
  /// **'This request is no longer valid. Please send a new one.'**
  String get resetNoLongerValid;

  /// No description provided for @filterOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get filterOpenNow;

  /// No description provided for @filterNearest.
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get filterNearest;

  /// No description provided for @filterFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get filterFavorites;

  /// No description provided for @cuisineName.
  ///
  /// In en, this message translates to:
  /// **'{code, select, azerbaijani{Azerbaijani} kebab{Kebab and grill} european{European} italian{Italian} turkish{Turkish} georgian{Georgian} asian{Asian} seafood{Seafood} fastfood{Fast food} pizza{Pizza} cafe{Cafe} dessert{Desserts} other{}}'**
  String cuisineName(String code);

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String distanceKm(String km);

  /// No description provided for @distanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String distanceMeters(String meters);

  /// No description provided for @locationExplainTitle.
  ///
  /// In en, this message translates to:
  /// **'Find restaurants near you'**
  String get locationExplainTitle;

  /// No description provided for @locationExplainBody.
  ///
  /// In en, this message translates to:
  /// **'HARA can sort restaurants by distance. For that it uses your approximate location, only for sorting and distances. HARA does not save it. You can say no and still see every restaurant.'**
  String get locationExplainBody;

  /// No description provided for @locationAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get locationAllow;

  /// No description provided for @locationNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get locationNotNow;

  /// No description provided for @locationDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location is off for HARA. Turn it on in the phone\'s settings to sort by distance.'**
  String get locationDeniedForever;

  /// No description provided for @locationOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get locationOpenSettings;

  /// No description provided for @locationServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off on your phone. Turn it on to sort by distance.'**
  String get locationServiceOff;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find your location. Try again in a moment.'**
  String get locationUnavailable;

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet. Tap the heart on a restaurant to keep it here.'**
  String get noFavoritesYet;

  /// No description provided for @noRestaurantsFilters.
  ///
  /// In en, this message translates to:
  /// **'No restaurants match these filters.'**
  String get noRestaurantsFilters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFavorite;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get termsOfUse;

  /// No description provided for @venueAgreementTitle.
  ///
  /// In en, this message translates to:
  /// **'Restaurant agreement'**
  String get venueAgreementTitle;

  /// No description provided for @acceptTermsLabel.
  ///
  /// In en, this message translates to:
  /// **'I accept the terms of use and the privacy policy'**
  String get acceptTermsLabel;

  /// No description provided for @acceptAgreementLabel.
  ///
  /// In en, this message translates to:
  /// **'I accept the restaurant agreement'**
  String get acceptAgreementLabel;

  /// No description provided for @mustAccept.
  ///
  /// In en, this message translates to:
  /// **'Please tick the box to continue.'**
  String get mustAccept;

  /// No description provided for @termsGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms'**
  String get termsGateTitle;

  /// No description provided for @termsGateBody.
  ///
  /// In en, this message translates to:
  /// **'These texts are new or have changed. To keep using HARA for your restaurant, please read and accept them.'**
  String get termsGateBody;

  /// No description provided for @termsAcceptButton.
  ///
  /// In en, this message translates to:
  /// **'Accept and continue'**
  String get termsAcceptButton;
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
