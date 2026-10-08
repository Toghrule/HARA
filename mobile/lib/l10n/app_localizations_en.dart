// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'Language';

  @override
  String get retry => 'Retry';

  @override
  String get done => 'Done';

  @override
  String get errorCantReachServer =>
      'Can\'t reach the server. Check your connection and try again.';

  @override
  String get errorSomethingWrong => 'Something went wrong. Please try again.';

  @override
  String get couldntOpenLink => 'Couldn\'t open this link.';

  @override
  String get aboutTooltip => 'About us, contact and FAQ';

  @override
  String get searchHint => 'Search by name or address';

  @override
  String get clearSearch => 'Clear search';

  @override
  String couldntLoadRestaurants(String error) {
    return 'Couldn\'t load restaurants.\n$error';
  }

  @override
  String couldntLoadMoreRestaurants(String error) {
    return 'Couldn\'t load more restaurants.\n$error';
  }

  @override
  String get noRestaurantsYet => 'No restaurants yet.';

  @override
  String noRestaurantsMatch(String search) {
    return 'No restaurants match \"$search\".';
  }

  @override
  String get ownRestaurantAddIt => 'Own a restaurant? Add it to HARA';

  @override
  String get ownRestaurant => 'Own a restaurant?';

  @override
  String get addItToHara => 'Add it to HARA';

  @override
  String discountWithCode(int percent) {
    return '$percent% off with a reservation code';
  }

  @override
  String get openInGoogleMaps => 'Open in Google Maps';

  @override
  String get reserve => 'Reserve';

  @override
  String get restaurantFallbackTitle => 'Restaurant';

  @override
  String get restaurantNoLongerAvailable =>
      'This restaurant is no longer available.';

  @override
  String get reserveTable => 'Reserve a table';

  @override
  String reserveSheetFreeWithDiscount(int percent) {
    return 'Free. Show your code at the venue to get $percent% off your bill.';
  }

  @override
  String get reserveSheetFree =>
      'Free. Show your code at the venue when you arrive.';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get holdTableFor => 'Hold the table for';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get invalidPhone =>
      'Enter a valid phone number, e.g. +994 50 123 45 67.';

  @override
  String get yourReservation => 'Your reservation';

  @override
  String get yourCode => 'Your code';

  @override
  String get copyCode => 'Copy code';

  @override
  String get codeCopied => 'Code copied';

  @override
  String get reservationExpired => 'This reservation has expired';

  @override
  String validFor(String countdown) {
    return 'Valid for $countdown';
  }

  @override
  String tableHeldUntil(String time, int minutes) {
    return 'Table held until $time ($minutes min)';
  }

  @override
  String showCodeWithDiscount(int percent) {
    return 'Show this code at the venue when you arrive to get $percent% off your bill.';
  }

  @override
  String get showCode => 'Show this code at the venue when you arrive.';

  @override
  String get cancelReservationTitle => 'Cancel reservation?';

  @override
  String get cancelReservationBody =>
      'Your code will stop working and the table will be released. You can make a new reservation afterwards.';

  @override
  String get keepIt => 'Keep it';

  @override
  String get cancelReservation => 'Cancel reservation';

  @override
  String get reservationCancelled => 'Reservation cancelled';

  @override
  String get reservationNotFound => 'We couldn\'t find this reservation.';

  @override
  String get addYourRestaurant => 'Add your restaurant';

  @override
  String get submitIntro =>
      'Tell us about your restaurant. We review every request before it appears in HARA.';

  @override
  String get sectionRestaurant => 'Restaurant';

  @override
  String get restaurantNameLabel => 'Restaurant name *';

  @override
  String get addressLabel => 'Address';

  @override
  String get restaurantPhoneLabel => 'Restaurant phone';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get sectionAboutYou => 'About you';

  @override
  String get yourNameLabel => 'Your name *';

  @override
  String get yourEmailLabel => 'Your email';

  @override
  String get yourPhoneLabel => 'Your phone';

  @override
  String get contactHint =>
      'Email or phone — at least one, so we can follow up.';

  @override
  String get contactRequired =>
      'Add an email or a phone number so we can reach you.';

  @override
  String get sendRequest => 'Send request';

  @override
  String get thankYou => 'Thank you!';

  @override
  String requestReceived(String name) {
    return 'We received your request for \"$name\". Our team will review it and get in touch using the contact details you gave us.';
  }

  @override
  String get backToRestaurants => 'Back to restaurants';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String tooLong(int max) {
    return 'Too long (max $max characters)';
  }

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get aboutUs => 'About us';

  @override
  String get contactUs => 'Contact us';

  @override
  String get faqTitle => 'Frequently asked questions';

  @override
  String get moreAboutUsSoon => 'More about us is coming soon.';

  @override
  String get followUs => 'Follow us';

  @override
  String get noContactDetails => 'No contact details yet.';

  @override
  String get noQuestionsYet => 'No questions yet.';

  @override
  String get contactPhone => 'Phone';

  @override
  String get contactEmail => 'Email';

  @override
  String get contactOther => 'Contact';

  @override
  String get socialWebsite => 'Website';

  @override
  String get socialOther => 'Link';
}
