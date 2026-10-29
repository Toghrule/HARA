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

  @override
  String get tabConfirmCode => 'Kodu təsdiqlə';

  @override
  String get tabReservations => 'Rezervlər';

  @override
  String get tabStats => 'Statistika';

  @override
  String get tabTeam => 'Komanda';

  @override
  String get tabRestaurant => 'Restoran';

  @override
  String get codeInputLabel => 'Müştərinin kodu';

  @override
  String get checkCode => 'Kodu yoxla';

  @override
  String get codeNotFoundHere => 'Bu kod sizin restoranda tapılmadı.';

  @override
  String giveDiscount(int percent) {
    return 'Hesabdan $percent% endirim edin.';
  }

  @override
  String get noDiscountHere => 'Bu restoranda endirim yoxdur.';

  @override
  String customerPhoneLine(String phone) {
    return 'Müştərinin telefonu: $phone';
  }

  @override
  String validUntilLine(String time) {
    return 'Saat $time-dək keçərlidir';
  }

  @override
  String get confirmCode => 'Kodu təsdiqlə';

  @override
  String get confirmCodeTitle => 'Bu kod təsdiqlənsin?';

  @override
  String get confirmCodeBody =>
      'Müştəri gəlib və endirim alır. Təsdiqlənmiş koddan yenidən istifadə etmək olmaz.';

  @override
  String get codeConfirmed => 'Kod təsdiqləndi';

  @override
  String get codeConfirmedDetail => 'Endirimi müştərinin hesabına tətbiq edin.';

  @override
  String get reservationStatusActive => 'Keçərlidir';

  @override
  String get reservationStatusRedeemed => 'Artıq istifadə olunub';

  @override
  String get reservationStatusCancelled => 'Müştəri ləğv edib';

  @override
  String get reservationStatusExpired => 'Vaxtı bitib';

  @override
  String get filterActive => 'Aktiv';

  @override
  String get filterUsed => 'İstifadə olunub';

  @override
  String get filterAll => 'Hamısı';

  @override
  String get noReservationsHere => 'Burada rezerv yoxdur.';

  @override
  String get waitingForYou => 'Sizin təsdiqinizi gözləyir';

  @override
  String get teamMembers => 'Komanda';

  @override
  String get roleOwner => 'Sahibkar';

  @override
  String get roleStaff => 'Ofisiant';

  @override
  String get approve => 'Təsdiq et';

  @override
  String get decline => 'Rədd et';

  @override
  String get removeStaff => 'Sil';

  @override
  String removeStaffTitle(String name) {
    return '$name silinsin?';
  }

  @override
  String get removeStaffBody => 'O artıq hesabına daxil ola bilməyəcək.';

  @override
  String get declinedLabel => 'Rədd edilib';

  @override
  String get noStaffYet =>
      'Hələ ofisiant yoxdur. Onlar tətbiqdə qeydiyyatdan keçib sizin restoranı seçə bilər.';

  @override
  String get cancel => 'Ləğv et';

  @override
  String discountLine(int percent) {
    return 'Endirim: $percent%';
  }

  @override
  String get changeRequestsTitle => 'Dəyişiklik sorğularınız';

  @override
  String get requestAChange => 'Dəyişiklik sorğusu göndər';

  @override
  String get noChangeRequests => 'Hələ sorğu yoxdur.';

  @override
  String get changeRequestPending => 'Baxılmağı gözləyir';

  @override
  String get changeRequestApproved => 'Təsdiqlənib';

  @override
  String get changeRequestRejected => 'Rədd edilib';

  @override
  String adminReply(String note) {
    return 'Cavab: $note';
  }

  @override
  String get changeRequestIntro =>
      'Restoranınızı birbaşa dəyişə bilməzsiniz. Yalnız dəyişmək istədiyiniz xanaları doldurun; HARA sorğuya baxıb tətbiq edəcək.';

  @override
  String get nameLabel => 'Ad';

  @override
  String get discountLabel => 'Endirim (%)';

  @override
  String get descriptionAzLabel => 'Təsvir (Azərbaycanca)';

  @override
  String get descriptionRuLabel => 'Təsvir (rusca)';

  @override
  String get descriptionEnLabel => 'Təsvir (ingiliscə)';

  @override
  String get noteForHara => 'HARA üçün qeyd (məcburi deyil)';

  @override
  String currentValue(String value) {
    return 'İndi: $value';
  }

  @override
  String get sendRequest => 'Sorğunu göndər';

  @override
  String get requestSent => 'Sorğu göndərildi. HARA ona baxacaq.';

  @override
  String get askForOneChange => 'Ən azı bir xananı doldurun.';

  @override
  String get discountRange => '0-dan 100-ə qədər rəqəm yazın.';

  @override
  String get privacyPolicy => 'Məxfilik siyasəti';

  @override
  String get accountMenu => 'Hesab menyusu';

  @override
  String get deleteAccount => 'Hesabımı sil';

  @override
  String get deleteAccountTitle => 'Hesabınız silinsin?';

  @override
  String get deleteAccountBody =>
      'Adınız, e-poçtunuz və telefon nömrəniz silinəcək və girişiniz bağlanacaq. Restoran sahibisinizsə, restoran HARA-da qalır. Bunu geri qaytarmaq olmaz.';

  @override
  String get deleteAccountPasswordHint => 'Təsdiq üçün parolunuzu yazın.';

  @override
  String get deleteAccountConfirm => 'Hesabı sil';

  @override
  String get wrongPassword => 'Parol yanlışdır.';

  @override
  String get tooManyWrongPasswords =>
      'Çox yanlış cəhd edildi. Bir az sonra yenidən yoxlayın.';

  @override
  String get accountDeleted => 'Hesabınız silindi.';

  @override
  String requestNotice(String duration) {
    return 'Restoran əvvəlcə sorğunuzu təsdiqləyir. Bundan sonra masanız $duration saxlanılır.';
  }

  @override
  String get waitingTitle => 'Restoranın cavabı gözlənilir';

  @override
  String waitingText(String restaurant, int minutes) {
    return 'Sorğunuz $restaurant restoranına göndərildi. O təsdiq edən kimi kodunuz burada görünəcək və $minutes dəqiqə başlayacaq.';
  }

  @override
  String waitingCountdown(String countdown) {
    return 'Restoranın cavab verməsinə $countdown qalıb';
  }

  @override
  String get cancelRequest => 'Sorğunu ləğv et';

  @override
  String get cancelRequestTitle => 'Sorğu ləğv edilsin?';

  @override
  String get cancelRequestBody =>
      'Restoran onu artıq görməyəcək, siz yenisini göndərə bilərsiniz.';

  @override
  String get requestCancelled => 'Sorğu ləğv edildi';

  @override
  String get confirmedByRestaurant => 'Restoran masanızı təsdiq etdi';

  @override
  String get declinedTitle => 'Restoran sorğunuzu qəbul etmədi';

  @override
  String get declinedText =>
      'Başqa restorana müraciət edə və ya bir az sonra yenidən cəhd edə bilərsiniz.';

  @override
  String get unansweredTitle => 'Restoran cavab vermədi';

  @override
  String get unansweredText =>
      'Restoran vaxtında cavab vermədi. Yeni sorğu göndərə bilərsiniz.';

  @override
  String bannerWaiting(String countdown) {
    return 'Restoranın cavabı gözlənilir · $countdown';
  }

  @override
  String bannerDeclined(String restaurant) {
    return '$restaurant sorğunuzu qəbul etmədi';
  }

  @override
  String bannerUnanswered(String restaurant) {
    return '$restaurant cavab vermədi';
  }

  @override
  String get closeNotice => 'Bağla';

  @override
  String get tabRequests => 'Sorğular';

  @override
  String get reservationStatusPending => 'Cavabınızı gözləyir';

  @override
  String get reservationStatusDeclined => 'Rədd edilib';

  @override
  String get reservationStatusUnanswered => 'Vaxtında cavab verilməyib';

  @override
  String get noRequestsWaiting => 'Gözləyən sorğu yoxdur.';

  @override
  String get acceptRequest => 'Qəbul et';

  @override
  String sentAt(String time) {
    return 'Göndərilib: $time';
  }

  @override
  String answerWithin(String countdown) {
    return 'Cavab üçün qalıb: $countdown';
  }

  @override
  String requestAccepted(int minutes) {
    return 'Qəbul edildi. Müştərinin $minutes dəqiqəsi başladı.';
  }

  @override
  String get requestDeclinedDone => 'Rədd edildi.';

  @override
  String get statsToday => 'Bu gün';

  @override
  String get statsThisMonth => 'Bu ay';

  @override
  String get statsThisYear => 'Bu il';

  @override
  String get statsAccepted => 'Qəbul edilən';

  @override
  String get statsCame => 'Gələn';

  @override
  String get statsMyToday => 'Bu gün təsdiqlədiyiniz kodlar';

  @override
  String get statsHint =>
      'Qəbul edilən: restoranın bəli dediyi sorğular. Gələn: kodu restoranda təsdiqlənən müştərilər.';

  @override
  String availOpenUntil(String time) {
    return '$time-dək açıqdır';
  }

  @override
  String availClosingSoon(String time) {
    return '$time-da bağlanır, artıq sorğu qəbul etmir';
  }

  @override
  String get availClosed => 'Bağlıdır';

  @override
  String availClosedOpensToday(String time) {
    return 'Bağlıdır, bu gün saat $time-da açılır';
  }

  @override
  String availClosedOpensTomorrow(String time) {
    return 'Bağlıdır, sabah saat $time-da açılır';
  }

  @override
  String availClosedOpensOn(String day, String time) {
    return 'Bağlıdır, $day saat $time-da açılır';
  }

  @override
  String weekdayName(String day) {
    String _temp0 = intl.Intl.selectLogic(
      day,
      {
        '0': 'Bazar',
        '1': 'Bazar ertəsi',
        '2': 'Çərşənbə axşamı',
        '3': 'Çərşənbə',
        '4': 'Cümə axşamı',
        '5': 'Cümə',
        '6': 'Şənbə',
        'other': '',
      },
    );
    return '$_temp0';
  }

  @override
  String weekdayOn(String day) {
    String _temp0 = intl.Intl.selectLogic(
      day,
      {
        '0': 'Bazar günü',
        '1': 'Bazar ertəsi günü',
        '2': 'Çərşənbə axşamı günü',
        '3': 'Çərşənbə günü',
        '4': 'Cümə axşamı günü',
        '5': 'Cümə günü',
        '6': 'Şənbə günü',
        'other': '',
      },
    );
    return '$_temp0';
  }

  @override
  String get openingHoursTitle => 'İş saatları';

  @override
  String get hoursClosedDay => 'Bağlıdır';

  @override
  String get hoursAllDay => '24 saat açıqdır';

  @override
  String get hoursNotSet =>
      'İş saatı qoyulmayıb: restoran həmişə açıq sayılır.';

  @override
  String get editOpeningHours => 'İş saatlarını dəyiş';

  @override
  String get hoursOpenSwitch => 'Açıqdır';

  @override
  String get hoursOpens => 'Açılır';

  @override
  String get hoursCloses => 'Bağlanır';

  @override
  String get hoursLastRequest =>
      'Bağlanmadan nə qədər əvvəl sorğu qəbulunu dayandır';

  @override
  String hoursLeadMinutes(int minutes) {
    return 'bağlanmadan $minutes dəq əvvəl';
  }

  @override
  String get hoursLeadAtClose => 'bağlanma saatına qədər';

  @override
  String get hoursSameEveryDay => 'Hər gün eyni saat';

  @override
  String get hoursRemove => 'Saatları sil (həmişə açıq)';

  @override
  String get hoursSave => 'Yadda saxla';

  @override
  String get hoursSaved => 'İş saatları yadda saxlanıldı.';

  @override
  String get hoursHint =>
      'Vaxt Azərbaycan vaxtı ilədir. Gecə yarısından sonra bağlanırsınızsa (18:00-dan 02:00-dək), sadəcə sonrakı bağlanma saatını yazın. Açılış və bağlanış saatı eynidirsə, gün boyu açıq sayılır.';

  @override
  String get forgotPasswordLink => 'Owner parolu unutdu?';

  @override
  String get resetTitle => 'Parolu bərpa et';

  @override
  String get resetIntro =>
      'Restoran sahibləri üçündür. Qeydiyyatdan keçdiyiniz emaili yazın. HARA sizin olduğunuzu təsdiqləmək üçün sizinlə əlaqə saxlayacaq, sonra burada yeni parol seçə biləcəksiniz.';

  @override
  String get resetSend => 'Sorğunu göndər';

  @override
  String get resetWaitingTitle => 'HARA-nın cavabı gözlənilir';

  @override
  String resetWaitingBody(String email) {
    return '$email üçün sorğunuz göndərildi. HARA sizin olduğunuzu təsdiqləmək üçün sizinlə əlaqə saxlayacaq. Bu ekrandan çıxa bilərsiniz: qayıdanda sorğu təsdiqlənibsə, dərhal yeni parol soruşacaq.';
  }

  @override
  String get resetCheckNow => 'İndi yoxla';

  @override
  String get resetCancel => 'Sorğunu ləğv et';

  @override
  String get resetApprovedTitle => 'Yeni parol seçin';

  @override
  String get resetApprovedBody =>
      'HARA sizin olduğunuzu təsdiqlədi. Yeni parol seçin; bu imkan bir saat açıq qalır.';

  @override
  String get resetNewPasswordLabel => 'Yeni parol';

  @override
  String get resetSave => 'Yeni parolu yadda saxla';

  @override
  String get resetDone => 'Parol dəyişdirildi. Yeni parolla daxil olun.';

  @override
  String get resetRejected =>
      'HARA bu sorğunu təsdiqləmədi. Həqiqətən siz olsanız, HARA ilə əlaqə saxlayıb yenidən xahiş edin.';

  @override
  String get resetAskAgain => 'Yenidən xahiş et';

  @override
  String get resetNoLongerValid =>
      'Bu sorğunun vaxtı keçib və ya artıq etibarsızdır. Zəhmət olmasa yenisini göndərin.';

  @override
  String get filterOpenNow => 'İndi açıq';

  @override
  String get filterNearest => 'Ən yaxın';

  @override
  String get filterFavorites => 'Sevimlilər';

  @override
  String cuisineName(String code) {
    String _temp0 = intl.Intl.selectLogic(
      code,
      {
        'azerbaijani': 'Azərbaycan',
        'kebab': 'Kabab və manqal',
        'european': 'Avropa',
        'italian': 'İtalyan',
        'turkish': 'Türk',
        'georgian': 'Gürcü',
        'asian': 'Asiya',
        'seafood': 'Dəniz məhsulları',
        'fastfood': 'Fast food',
        'pizza': 'Pizza',
        'cafe': 'Kafe',
        'dessert': 'Desertlər',
        'other': '',
      },
    );
    return '$_temp0';
  }

  @override
  String distanceKm(String km) {
    return '$km km';
  }

  @override
  String distanceMeters(String meters) {
    return '$meters m';
  }

  @override
  String get locationExplainTitle => 'Yaxınlığınızdakı restoranları tapın';

  @override
  String get locationExplainBody =>
      'HARA restoranları məsafəyə görə sıralaya bilər. Bunun üçün təxmini yerinizdən istifadə edir, yalnız sıralama və məsafə üçün. HARA onu saxlamır. İmtina etsəniz də bütün restoranları görə bilərsiniz.';

  @override
  String get locationAllow => 'İcazə ver';

  @override
  String get locationNotNow => 'İndi yox';

  @override
  String get locationDeniedForever =>
      'HARA üçün məkan söndürülüb. Məsafəyə görə sıralamaq üçün telefonun ayarlarından yandırın.';

  @override
  String get locationOpenSettings => 'Ayarlar';

  @override
  String get locationServiceOff =>
      'Telefonunuzda məkan xidməti söndürülüb. Məsafəyə görə sıralamaq üçün yandırın.';

  @override
  String get locationUnavailable =>
      'Yeriniz tapılmadı. Bir azdan yenidən cəhd edin.';

  @override
  String get noFavoritesYet =>
      'Hələ sevimli yoxdur. Restoranı burada saxlamaq üçün ürək işarəsinə toxunun.';

  @override
  String get noRestaurantsFilters => 'Bu süzgəclərə uyğun restoran yoxdur.';

  @override
  String get clearFilters => 'Süzgəcləri təmizlə';

  @override
  String get addFavorite => 'Sevimlilərə əlavə et';

  @override
  String get removeFavorite => 'Sevimlilərdən çıxar';

  @override
  String get termsOfUse => 'İstifadə şərtləri';

  @override
  String get venueAgreementTitle => 'Restoran razılaşması';

  @override
  String get acceptTermsLabel =>
      'İstifadə şərtləri və məxfilik siyasəti ilə razıyam';

  @override
  String get acceptAgreementLabel => 'Restoran razılaşması ilə razıyam';

  @override
  String get mustAccept => 'Davam etmək üçün qutunu işarələyin.';

  @override
  String get termsGateTitle => 'Zəhmət olmasa şərtləri qəbul edin';

  @override
  String get termsGateBody =>
      'Bu mətnlər yenidir və ya dəyişib. Restoranınız üçün HARA-dan istifadəyə davam etmək üçün onları oxuyub qəbul edin.';

  @override
  String get termsAcceptButton => 'Qəbul et və davam et';
}
