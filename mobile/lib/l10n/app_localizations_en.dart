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
  String activeReservationSubtitle(String code, String countdown) {
    return 'Code $code · $countdown left';
  }

  @override
  String get copyCode => 'Copy code';

  @override
  String get codeCopied => 'Code copied';

  @override
  String get reservationExpired => 'This reservation has expired';

  @override
  String get reservationEnded => 'This reservation is no longer active';

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
  String get yourNameLabel => 'Your name *';

  @override
  String get yourPhoneLabel => 'Your phone';

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

  @override
  String get accountTooltip => 'Owner or waiter account';

  @override
  String get welcomeTitle => 'Welcome to HARA';

  @override
  String get welcomeSubtitle => 'Choose how you want to use the app.';

  @override
  String get customerSectionTitle => 'Customer';

  @override
  String get customerSectionText =>
      'Find a place, reserve a table and get a discount. No account needed.';

  @override
  String get continueAsCustomer => 'Continue as a customer';

  @override
  String get ownerSectionTitle => 'Restaurant owner or waiter';

  @override
  String get ownerSectionText =>
      'Confirm customers\' codes and look after your restaurant.';

  @override
  String get signIn => 'Sign in';

  @override
  String get registerAsOwner => 'Register as a restaurant owner';

  @override
  String get registerAsStaff => 'Register as a waiter';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Repeat the password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get wrongCredentials => 'Wrong email or password.';

  @override
  String get noAccountYet => 'No account yet?';

  @override
  String get registerOwnerTitle => 'Register your restaurant';

  @override
  String get registerOwnerIntro =>
      'Create your account and tell us about your restaurant. We review every registration before the restaurant appears in HARA.';

  @override
  String get sectionAccount => 'Your account';

  @override
  String get createAccount => 'Create account';

  @override
  String get passwordRules =>
      'At least 8 characters, with a letter and a digit.';

  @override
  String get passwordsDontMatch => 'The passwords don\'t match.';

  @override
  String get emailTaken => 'This email is already registered.';

  @override
  String get tooManyAttempts => 'Too many attempts. Please try again later.';

  @override
  String get registerStaffTitle => 'Register as a waiter';

  @override
  String get registerStaffIntro =>
      'Pick the restaurant you work at. Its owner has to approve you before you can confirm codes.';

  @override
  String get yourRestaurantSection => 'Your restaurant';

  @override
  String get selectRestaurantRequired => 'Pick your restaurant first.';

  @override
  String get venueTitle => 'Your restaurant';

  @override
  String get pendingOwnerTitle => 'Waiting for approval';

  @override
  String get pendingOwnerText =>
      'We are reviewing your registration. You will be able to confirm customers\' codes as soon as it is approved.';

  @override
  String get pendingStaffText =>
      'The restaurant\'s owner has to approve you. Ask them to open the app and accept your request.';

  @override
  String get rejectedTitle => 'Not approved';

  @override
  String get rejectedText => 'Your request was not approved.';

  @override
  String rejectedReason(String note) {
    return 'Reason: $note';
  }

  @override
  String get noVenueText => 'This account is not linked to a restaurant.';

  @override
  String get checkAgain => 'Check again';

  @override
  String get signOut => 'Sign out';

  @override
  String get browseAsCustomer => 'Browse restaurants';

  @override
  String get tabConfirmCode => 'Confirm code';

  @override
  String get tabReservations => 'Reservations';

  @override
  String get tabTeam => 'Team';

  @override
  String get tabRestaurant => 'Restaurant';

  @override
  String get codeInputLabel => 'Customer\'s code';

  @override
  String get checkCode => 'Check the code';

  @override
  String get codeNotFoundHere => 'This code was not found at your restaurant.';

  @override
  String giveDiscount(int percent) {
    return 'Give $percent% off the bill.';
  }

  @override
  String get noDiscountHere => 'This restaurant has no discount.';

  @override
  String customerPhoneLine(String phone) {
    return 'Customer\'s phone: $phone';
  }

  @override
  String validUntilLine(String time) {
    return 'Valid until $time';
  }

  @override
  String get confirmCode => 'Confirm the code';

  @override
  String get confirmCodeTitle => 'Confirm this code?';

  @override
  String get confirmCodeBody =>
      'The customer is here and gets the discount. A confirmed code cannot be used again.';

  @override
  String get codeConfirmed => 'Code confirmed';

  @override
  String get codeConfirmedDetail =>
      'Apply the discount to the customer\'s bill.';

  @override
  String get reservationStatusActive => 'Valid';

  @override
  String get reservationStatusRedeemed => 'Already used';

  @override
  String get reservationStatusCancelled => 'Cancelled by the customer';

  @override
  String get reservationStatusExpired => 'Expired';

  @override
  String get filterActive => 'Active';

  @override
  String get filterUsed => 'Used';

  @override
  String get filterAll => 'All';

  @override
  String get noReservationsHere => 'No reservations here.';

  @override
  String get waitingForYou => 'Waiting for your approval';

  @override
  String get teamMembers => 'Team';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleStaff => 'Waiter';

  @override
  String get approve => 'Approve';

  @override
  String get decline => 'Decline';

  @override
  String get removeStaff => 'Remove';

  @override
  String removeStaffTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get removeStaffBody => 'They will no longer be able to sign in.';

  @override
  String get declinedLabel => 'Declined';

  @override
  String get noStaffYet =>
      'No waiters yet. They can register in the app and pick your restaurant.';

  @override
  String get cancel => 'Cancel';

  @override
  String discountLine(int percent) {
    return 'Discount: $percent%';
  }

  @override
  String get changeRequestsTitle => 'Your change requests';

  @override
  String get requestAChange => 'Request a change';

  @override
  String get noChangeRequests => 'No requests yet.';

  @override
  String get changeRequestPending => 'Waiting for review';

  @override
  String get changeRequestApproved => 'Approved';

  @override
  String get changeRequestRejected => 'Declined';

  @override
  String adminReply(String note) {
    return 'Reply: $note';
  }

  @override
  String get changeRequestIntro =>
      'You can\'t edit your restaurant directly. Fill in only what you want changed; HARA reviews the request and applies it.';

  @override
  String get nameLabel => 'Name';

  @override
  String get discountLabel => 'Discount (%)';

  @override
  String get descriptionAzLabel => 'Description (Azerbaijani)';

  @override
  String get descriptionRuLabel => 'Description (Russian)';

  @override
  String get descriptionEnLabel => 'Description (English)';

  @override
  String get noteForHara => 'Note for HARA (optional)';

  @override
  String currentValue(String value) {
    return 'Now: $value';
  }

  @override
  String get sendRequest => 'Send request';

  @override
  String get requestSent => 'Request sent. HARA will review it.';

  @override
  String get askForOneChange => 'Fill in at least one field.';

  @override
  String get discountRange => 'Enter a number from 0 to 100.';
}
