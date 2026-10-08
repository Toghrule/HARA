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
  String get addYourRestaurant => 'Добавьте свой ресторан';

  @override
  String get submitIntro =>
      'Расскажите о своём ресторане. Мы проверяем каждую заявку, прежде чем она появится в HARA.';

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
  String get sectionAboutYou => 'О вас';

  @override
  String get yourNameLabel => 'Ваше имя *';

  @override
  String get yourEmailLabel => 'Ваш e-mail';

  @override
  String get yourPhoneLabel => 'Ваш телефон';

  @override
  String get contactHint =>
      'E-mail или телефон — хотя бы одно, чтобы мы могли связаться.';

  @override
  String get contactRequired =>
      'Добавьте e-mail или номер телефона, чтобы мы могли с вами связаться.';

  @override
  String get sendRequest => 'Отправить заявку';

  @override
  String get thankYou => 'Спасибо!';

  @override
  String requestReceived(String name) {
    return 'Мы получили вашу заявку на «$name». Наша команда рассмотрит её и свяжется с вами по указанным контактам.';
  }

  @override
  String get backToRestaurants => 'Назад к ресторанам';

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
}
