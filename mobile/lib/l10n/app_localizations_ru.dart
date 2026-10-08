// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get language => 'Язык';

  @override
  String get retry => 'Повторить';

  @override
  String get done => 'Готово';

  @override
  String get errorCantReachServer =>
      'Не удаётся подключиться к серверу. Проверьте интернет и попробуйте снова.';

  @override
  String get errorSomethingWrong => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get couldntOpenLink => 'Не удалось открыть эту ссылку.';

  @override
  String get aboutTooltip => 'О нас, контакты и частые вопросы';

  @override
  String get searchHint => 'Поиск по названию или адресу';

  @override
  String get clearSearch => 'Очистить поиск';

  @override
  String couldntLoadRestaurants(String error) {
    return 'Не удалось загрузить рестораны.\n$error';
  }

  @override
  String couldntLoadMoreRestaurants(String error) {
    return 'Не удалось загрузить ещё рестораны.\n$error';
  }

  @override
  String get noRestaurantsYet => 'Ресторанов пока нет.';

  @override
  String noRestaurantsMatch(String search) {
    return 'По запросу «$search» ресторанов не найдено.';
  }

  @override
  String get ownRestaurantAddIt => 'Есть ресторан? Добавьте его в HARA';

  @override
  String get ownRestaurant => 'Есть ресторан?';

  @override
  String get addItToHara => 'Добавьте его в HARA';

  @override
  String discountWithCode(int percent) {
    return 'Скидка $percent% по коду брони';
  }

  @override
  String get openInGoogleMaps => 'Открыть в Google Картах';

  @override
  String get reserve => 'Забронировать';

  @override
  String get restaurantFallbackTitle => 'Ресторан';

  @override
  String get restaurantNoLongerAvailable => 'Этот ресторан больше недоступен.';

  @override
  String get reserveTable => 'Забронировать столик';

  @override
  String reserveSheetFreeWithDiscount(int percent) {
    return 'Бесплатно. Покажите код в заведении, чтобы получить скидку $percent% на счёт.';
  }

  @override
  String get reserveSheetFree =>
      'Бесплатно. Покажите код в заведении по приходе.';

  @override
  String get phoneNumber => 'Номер телефона';

  @override
  String get holdTableFor => 'Держать столик';

  @override
  String minutesShort(int count) {
    return '$count мин';
  }

  @override
  String get invalidPhone =>
      'Введите корректный номер телефона, например +994 50 123 45 67.';

  @override
  String get yourReservation => 'Ваша бронь';

  @override
  String get yourCode => 'Ваш код';

  @override
  String activeReservationSubtitle(String code, String countdown) {
    return 'Код $code · осталось $countdown';
  }

  @override
  String get copyCode => 'Скопировать код';

  @override
  String get codeCopied => 'Код скопирован';

  @override
  String get reservationExpired => 'Срок брони истёк';

  @override
  String get reservationEnded => 'Эта бронь больше не активна';

  @override
  String validFor(String countdown) {
    return 'Осталось: $countdown';
  }

  @override
  String tableHeldUntil(String time, int minutes) {
    return 'Столик удерживается до $time ($minutes мин)';
  }

  @override
  String showCodeWithDiscount(int percent) {
    return 'Покажите этот код в заведении по приходе и получите скидку $percent% на счёт.';
  }

  @override
  String get showCode => 'Покажите этот код в заведении по приходе.';

  @override
  String get cancelReservationTitle => 'Отменить бронь?';

  @override
  String get cancelReservationBody =>
      'Код перестанет действовать, а столик освободится. Потом можно будет сделать новую бронь.';

  @override
  String get keepIt => 'Оставить';

  @override
  String get cancelReservation => 'Отменить бронь';

  @override
  String get reservationCancelled => 'Бронь отменена';

  @override
  String get reservationNotFound => 'Мы не нашли эту бронь.';

  @override
  String get sectionRestaurant => 'Ресторан';

  @override
  String get restaurantNameLabel => 'Название ресторана *';

  @override
  String get addressLabel => 'Адрес';

  @override
  String get restaurantPhoneLabel => 'Телефон ресторана';

  @override
  String get descriptionLabel => 'Описание';

  @override
  String get yourNameLabel => 'Ваше имя *';

  @override
  String get yourPhoneLabel => 'Ваш телефон';

  @override
  String get fieldRequired => 'Это поле обязательно';

  @override
  String tooLong(int max) {
    return 'Слишком длинно (максимум $max символов)';
  }

  @override
  String get invalidEmail => 'Введите корректный e-mail';

  @override
  String get aboutUs => 'О нас';

  @override
  String get contactUs => 'Связаться с нами';

  @override
  String get faqTitle => 'Частые вопросы';

  @override
  String get moreAboutUsSoon => 'Скоро здесь будет больше информации о нас.';

  @override
  String get followUs => 'Мы в соцсетях';

  @override
  String get noContactDetails => 'Контактов пока нет.';

  @override
  String get noQuestionsYet => 'Вопросов пока нет.';

  @override
  String get contactPhone => 'Телефон';

  @override
  String get contactEmail => 'E-mail';

  @override
  String get contactOther => 'Контакт';

  @override
  String get socialWebsite => 'Сайт';

  @override
  String get socialOther => 'Ссылка';

  @override
  String get accountTooltip => 'Аккаунт владельца или официанта';

  @override
  String get welcomeTitle => 'Добро пожаловать в HARA';

  @override
  String get welcomeSubtitle =>
      'Выберите, как вы хотите пользоваться приложением.';

  @override
  String get customerSectionTitle => 'Клиент';

  @override
  String get customerSectionText =>
      'Найдите место, забронируйте столик и получите скидку. Аккаунт не нужен.';

  @override
  String get continueAsCustomer => 'Продолжить как клиент';

  @override
  String get ownerSectionTitle => 'Владелец ресторана или официант';

  @override
  String get ownerSectionText =>
      'Подтверждайте коды клиентов и следите за своим рестораном.';

  @override
  String get signIn => 'Войти';

  @override
  String get registerAsOwner => 'Регистрация владельца ресторана';

  @override
  String get registerAsStaff => 'Регистрация официанта';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get confirmPasswordLabel => 'Повторите пароль';

  @override
  String get showPassword => 'Показать пароль';

  @override
  String get hidePassword => 'Скрыть пароль';

  @override
  String get wrongCredentials => 'Неверный e-mail или пароль.';

  @override
  String get noAccountYet => 'Нет аккаунта?';

  @override
  String get registerOwnerTitle => 'Регистрация ресторана';

  @override
  String get registerOwnerIntro =>
      'Создайте аккаунт и расскажите о своём ресторане. Мы проверяем каждую регистрацию, прежде чем ресторан появится в HARA.';

  @override
  String get sectionAccount => 'Ваш аккаунт';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get passwordRules => 'Не менее 8 символов, с буквой и цифрой.';

  @override
  String get passwordsDontMatch => 'Пароли не совпадают.';

  @override
  String get emailTaken => 'Этот e-mail уже зарегистрирован.';

  @override
  String get tooManyAttempts => 'Слишком много попыток. Попробуйте позже.';

  @override
  String get registerStaffTitle => 'Регистрация официанта';

  @override
  String get registerStaffIntro =>
      'Выберите ресторан, в котором вы работаете. Его владелец должен подтвердить вас, прежде чем вы сможете подтверждать коды.';

  @override
  String get yourRestaurantSection => 'Ваш ресторан';

  @override
  String get selectRestaurantRequired => 'Сначала выберите ресторан.';

  @override
  String get venueTitle => 'Ваш ресторан';

  @override
  String get pendingOwnerTitle => 'Ожидает подтверждения';

  @override
  String get pendingOwnerText =>
      'Мы проверяем вашу регистрацию. Как только её подтвердят, вы сможете подтверждать коды клиентов.';

  @override
  String get pendingStaffText =>
      'Владелец ресторана должен вас подтвердить. Попросите его открыть приложение и принять вашу заявку.';

  @override
  String get rejectedTitle => 'Не подтверждено';

  @override
  String get rejectedText => 'Вашу заявку не подтвердили.';

  @override
  String rejectedReason(String note) {
    return 'Причина: $note';
  }

  @override
  String get noVenueText => 'Этот аккаунт не привязан к ресторану.';

  @override
  String get checkAgain => 'Проверить снова';

  @override
  String get signOut => 'Выйти';

  @override
  String get browseAsCustomer => 'Смотреть рестораны';
}
