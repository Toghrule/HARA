// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Azerbaijani (`az`).
class AppLocalizationsAz extends AppLocalizations {
  AppLocalizationsAz([String locale = 'az']) : super(locale);

  @override
  String get language => 'Dil';

  @override
  String get retry => 'Yenidən cəhd et';

  @override
  String get done => 'Hazır';

  @override
  String get errorCantReachServer =>
      'Serverlə əlaqə qurulmadı. İnternet bağlantınızı yoxlayıb yenidən cəhd edin.';

  @override
  String get errorSomethingWrong =>
      'Xəta baş verdi. Zəhmət olmasa, yenidən cəhd edin.';

  @override
  String get couldntOpenLink => 'Bu keçidi açmaq mümkün olmadı.';

  @override
  String get aboutTooltip => 'Haqqımızda, əlaqə və tez-tez verilən suallar';

  @override
  String get searchHint => 'Ad və ya ünvana görə axtar';

  @override
  String get clearSearch => 'Axtarışı təmizlə';

  @override
  String couldntLoadRestaurants(String error) {
    return 'Restoranlar yüklənmədi.\n$error';
  }

  @override
  String couldntLoadMoreRestaurants(String error) {
    return 'Daha çox restoran yüklənmədi.\n$error';
  }

  @override
  String get noRestaurantsYet => 'Hələ restoran yoxdur.';

  @override
  String noRestaurantsMatch(String search) {
    return '\"$search\" üzrə restoran tapılmadı.';
  }

  @override
  String get ownRestaurantAddIt => 'Restoranınız var? HARA-ya əlavə edin';

  @override
  String get ownRestaurant => 'Restoranınız var?';

  @override
  String get addItToHara => 'HARA-ya əlavə edin';

  @override
  String discountWithCode(int percent) {
    return 'Rezerv kodu ilə $percent% endirim';
  }

  @override
  String get openInGoogleMaps => 'Google Xəritədə aç';

  @override
  String get reserve => 'Rezerv et';

  @override
  String get restaurantFallbackTitle => 'Restoran';

  @override
  String get restaurantNoLongerAvailable => 'Bu restoran artıq mövcud deyil.';

  @override
  String get reserveTable => 'Masa rezerv et';

  @override
  String reserveSheetFreeWithDiscount(int percent) {
    return 'Pulsuzdur. Hesabdan $percent% endirim almaq üçün məkanda kodunuzu göstərin.';
  }

  @override
  String get reserveSheetFree => 'Pulsuzdur. Məkana çatanda kodunuzu göstərin.';

  @override
  String get phoneNumber => 'Telefon nömrəsi';

  @override
  String get holdTableFor => 'Masanı saxla';

  @override
  String minutesShort(int count) {
    return '$count dəq';
  }

  @override
  String get invalidPhone =>
      'Düzgün telefon nömrəsi daxil edin, məsələn +994 50 123 45 67.';

  @override
  String get yourReservation => 'Rezerviniz';

  @override
  String get yourCode => 'Kodunuz';

  @override
  String activeReservationSubtitle(String code, String countdown) {
    return 'Kod $code · $countdown qalıb';
  }

  @override
  String get copyCode => 'Kodu kopyala';

  @override
  String get codeCopied => 'Kod kopyalandı';

  @override
  String get reservationExpired => 'Bu rezervin vaxtı bitib';

  @override
  String get reservationEnded => 'Bu rezerv artıq aktiv deyil';

  @override
  String validFor(String countdown) {
    return 'Qalan vaxt: $countdown';
  }

  @override
  String tableHeldUntil(String time, int minutes) {
    return 'Masa saat $time-dək saxlanılır ($minutes dəq)';
  }

  @override
  String showCodeWithDiscount(int percent) {
    return 'Məkana çatanda bu kodu göstərin və hesabdan $percent% endirim alın.';
  }

  @override
  String get showCode => 'Məkana çatanda bu kodu göstərin.';

  @override
  String get cancelReservationTitle => 'Rezerv ləğv edilsin?';

  @override
  String get cancelReservationBody =>
      'Kodunuz işləməyəcək və masa azad olunacaq. Sonra yeni rezerv edə bilərsiniz.';

  @override
  String get keepIt => 'Saxla';

  @override
  String get cancelReservation => 'Rezervi ləğv et';

  @override
  String get reservationCancelled => 'Rezerv ləğv edildi';

  @override
  String get reservationNotFound => 'Bu rezerv tapılmadı.';

  @override
  String get sectionRestaurant => 'Restoran';

  @override
  String get restaurantNameLabel => 'Restoranın adı *';

  @override
  String get addressLabel => 'Ünvan';

  @override
  String get restaurantPhoneLabel => 'Restoranın telefonu';

  @override
  String get descriptionLabel => 'Təsvir';

  @override
  String get yourNameLabel => 'Adınız *';

  @override
  String get yourPhoneLabel => 'Telefonunuz';

  @override
  String get fieldRequired => 'Bu xana məcburidir';

  @override
  String tooLong(int max) {
    return 'Çox uzundur (ən çox $max simvol)';
  }

  @override
  String get invalidEmail => 'Düzgün e-poçt ünvanı daxil edin';

  @override
  String get aboutUs => 'Haqqımızda';

  @override
  String get contactUs => 'Bizimlə əlaqə';

  @override
  String get faqTitle => 'Tez-tez verilən suallar';

  @override
  String get moreAboutUsSoon =>
      'Haqqımızda daha çox məlumat tezliklə əlavə olunacaq.';

  @override
  String get followUs => 'Bizi izləyin';

  @override
  String get noContactDetails => 'Hələ əlaqə məlumatı yoxdur.';

  @override
  String get noQuestionsYet => 'Hələ sual yoxdur.';

  @override
  String get contactPhone => 'Telefon';

  @override
  String get contactEmail => 'E-poçt';

  @override
  String get contactOther => 'Əlaqə';

  @override
  String get socialWebsite => 'Vebsayt';

  @override
  String get socialOther => 'Keçid';

  @override
  String get accountTooltip => 'Sahibkar və ya ofisiant hesabı';

  @override
  String get welcomeTitle => 'HARA-ya xoş gəlmisiniz';

  @override
  String get welcomeSubtitle => 'Tətbiqdən necə istifadə edəcəyinizi seçin.';

  @override
  String get customerSectionTitle => 'Müştəri';

  @override
  String get customerSectionText =>
      'Məkan tapın, masa rezerv edin və endirim qazanın. Hesab lazım deyil.';

  @override
  String get continueAsCustomer => 'Müştəri kimi davam et';

  @override
  String get ownerSectionTitle => 'Restoran sahibi və ya ofisiant';

  @override
  String get ownerSectionText =>
      'Müştərilərin kodlarını təsdiqləyin və restoranınıza baxın.';

  @override
  String get signIn => 'Daxil ol';

  @override
  String get registerAsOwner => 'Restoran sahibi kimi qeydiyyat';

  @override
  String get registerAsStaff => 'Ofisiant kimi qeydiyyat';

  @override
  String get emailLabel => 'E-poçt';

  @override
  String get passwordLabel => 'Parol';

  @override
  String get confirmPasswordLabel => 'Parolu təkrar yazın';

  @override
  String get showPassword => 'Parolu göstər';

  @override
  String get hidePassword => 'Parolu gizlət';

  @override
  String get wrongCredentials => 'E-poçt və ya parol yanlışdır.';

  @override
  String get noAccountYet => 'Hesabınız yoxdur?';

  @override
  String get registerOwnerTitle => 'Restoranınızı qeydiyyatdan keçirin';

  @override
  String get registerOwnerIntro =>
      'Hesab yaradın və restoranınız haqqında məlumat verin. Hər qeydiyyat restoran HARA-da görünməzdən əvvəl nəzərdən keçirilir.';

  @override
  String get sectionAccount => 'Hesabınız';

  @override
  String get createAccount => 'Hesab yarat';

  @override
  String get passwordRules => 'Ən azı 8 simvol, hərf və rəqəm olmalıdır.';

  @override
  String get passwordsDontMatch => 'Parollar eyni deyil.';

  @override
  String get emailTaken => 'Bu e-poçt artıq qeydiyyatdan keçib.';

  @override
  String get tooManyAttempts =>
      'Çox cəhd edildi. Bir az sonra yenidən yoxlayın.';

  @override
  String get registerStaffTitle => 'Ofisiant kimi qeydiyyat';

  @override
  String get registerStaffIntro =>
      'İşlədiyiniz restoranı seçin. Kodları təsdiqləyə bilməniz üçün restoranın sahibi sizi təsdiq etməlidir.';

  @override
  String get yourRestaurantSection => 'Restoranınız';

  @override
  String get selectRestaurantRequired => 'Əvvəl restoranınızı seçin.';

  @override
  String get venueTitle => 'Restoranınız';

  @override
  String get pendingOwnerTitle => 'Təsdiq gözlənilir';

  @override
  String get pendingOwnerText =>
      'Qeydiyyatınızı nəzərdən keçiririk. Təsdiqlənən kimi müştərilərin kodlarını təsdiqləyə biləcəksiniz.';

  @override
  String get pendingStaffText =>
      'Restoranın sahibi sizi təsdiq etməlidir. Ondan tətbiqi açıb sorğunuzu qəbul etməsini xahiş edin.';

  @override
  String get rejectedTitle => 'Təsdiqlənmədi';

  @override
  String get rejectedText => 'Sorğunuz təsdiqlənmədi.';

  @override
  String rejectedReason(String note) {
    return 'Səbəb: $note';
  }

  @override
  String get noVenueText => 'Bu hesab heç bir restorana bağlı deyil.';

  @override
  String get checkAgain => 'Yenidən yoxla';

  @override
  String get signOut => 'Çıxış';

  @override
  String get browseAsCustomer => 'Restoranlara bax';
}
