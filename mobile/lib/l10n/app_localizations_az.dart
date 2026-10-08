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
  String get addYourRestaurant => 'Restoranınızı əlavə edin';

  @override
  String get submitIntro =>
      'Restoranınız haqqında bizə məlumat verin. Hər sorğu HARA-da görünməzdən əvvəl nəzərdən keçirilir.';

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
  String get sectionAboutYou => 'Sizin haqqınızda';

  @override
  String get yourNameLabel => 'Adınız *';

  @override
  String get yourEmailLabel => 'E-poçtunuz';

  @override
  String get yourPhoneLabel => 'Telefonunuz';

  @override
  String get contactHint =>
      'E-poçt və ya telefon — ən azı biri, sizinlə əlaqə saxlaya bilək.';

  @override
  String get contactRequired =>
      'Sizinlə əlaqə saxlaya bilməyimiz üçün e-poçt və ya telefon nömrəsi əlavə edin.';

  @override
  String get sendRequest => 'Sorğunu göndər';

  @override
  String get thankYou => 'Təşəkkür edirik!';

  @override
  String requestReceived(String name) {
    return '\"$name\" üçün sorğunuzu aldıq. Komandamız onu nəzərdən keçirəcək və verdiyiniz əlaqə məlumatları ilə sizinlə əlaqə saxlayacaq.';
  }

  @override
  String get backToRestaurants => 'Restoranlara qayıt';

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
}
