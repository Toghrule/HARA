/// One heading of the privacy policy with its paragraphs.
class PolicySection {
  const PolicySection(this.title, this.paragraphs);

  final String title;
  final List<String> paragraphs;
}

/// The date shown under the title. Change it whenever the text changes.
const privacyPolicyUpdated = '2026-10-13';

/// The privacy policy in each of the app's languages. It describes what the app does today; when a
/// behaviour changes (what is collected, who sees it, how long it is kept), this text must change too.
List<PolicySection> privacyPolicyFor(String languageCode) => switch (languageCode) {
      'ru' => _ru,
      'en' => _en,
      _ => _az,
    };

const _az = [
  PolicySection('Nələri toplayırıq', [
    'Masa rezerv edəndə: telefon nömrənizi, seçdiyiniz restoranı, rezervin vaxtını (masa 30 dəqiqə saxlanılır). Bunun üçün hesab açmaq lazım deyil.',
    'Restoran sahibi və ya ofisiant qeydiyyatdan keçəndə: adı, e-poçtu, telefon nömrəsini (məcburi deyil), parolu (yalnız çevrilmiş, oxunmaz şəkildə saxlanılır) və sahibkar üçün restoranın məlumatlarını.',
    'Telefonunuzda: dil seçiminizi, aktiv rezerv kodunuzu və hesaba daxil olubsunuzsa girişinizi. Bunlar yalnız sizin cihazınızda qalır.',
    'Məkanınızı, ödəniş məlumatınızı və əlaqələrinizi toplamırıq, reklam izləyiciləri istifadə etmirik.',
  ]),
  PolicySection('Nə üçün istifadə edirik', [
    'Rezervin işləməsi üçün: rezerv etdiyiniz restoran telefon nömrənizi və kodunuzu görür ki, endirimi təsdiqləsin və ya sizinlə əlaqə saxlasın.',
    'Sahibkar və ofisiant hesablarını idarə etmək üçün.',
    'Sui-istifadənin qarşısını almaq üçün (eyni cihazdan göndərilən sorğuların sayını məhdudlaşdırırıq).',
  ]),
  PolicySection('Kim görür', [
    'Rezerv etdiyiniz restoran (telefon nömrəniz və kodunuz) və xidməti idarə edən HARA komandası.',
    'Məlumatlarınızı satmırıq və reklamçılarla bölüşmürük.',
  ]),
  PolicySection('Nə qədər saxlayırıq', [
    'Rezerv qeydləri xidmətin işləməsi və mübahisələrin həlli üçün lazım olduğu müddətdə saxlanılır. Rezervlərinizlə bağlı telefon nömrənizin silinməsini istəyə bilərsiniz: tətbiqdəki "Bizimlə əlaqə" bölməsinə baxın.',
  ]),
  PolicySection('Seçimləriniz', [
    'Restoran sahibləri və ofisiantlar hesablarını tətbiqin içində silə bilər: adı, e-poçtu və telefon nömrəsi silinir, restoran isə HARA-da qalır.',
    'Müştərilər keçmiş rezervlərdən telefon nömrəsinin silinməsini "Bizimlə əlaqə" vasitəsilə istəyə bilər.',
    'İstənilən vaxt telefonunuzdakı tətbiq məlumatlarını təmizləyə bilərsiniz.',
  ]),
  PolicySection('Dəyişikliklər və əlaqə', [
    'Bu siyasət dəyişsə, burada yenilənəcək. Suallarınız üçün tətbiqdəki "Bizimlə əlaqə" bölməsinə müraciət edin.',
  ]),
];

const _ru = [
  PolicySection('Что мы собираем', [
    'При бронировании столика: ваш номер телефона, выбранный ресторан, время брони (столик удерживается 30 минут). Для этого не нужен аккаунт.',
    'При регистрации владельца ресторана или официанта: имя, e-mail, номер телефона (по желанию), пароль (хранится только в виде необратимого шифра) и, для владельца, данные ресторана.',
    'На вашем телефоне: выбранный язык, код активной брони и, если вы вошли в аккаунт, ваш вход. Это остаётся только на вашем устройстве.',
    'Мы не собираем ваше местоположение, платёжные данные и контакты и не используем рекламные трекеры.',
  ]),
  PolicySection('Зачем мы это используем', [
    'Чтобы работала бронь: ресторан, в котором вы забронировали, видит ваш номер телефона и код, чтобы подтвердить скидку или связаться с вами.',
    'Чтобы работали аккаунты владельцев и официантов.',
    'Чтобы предотвращать злоупотребления (мы ограничиваем число запросов с одного устройства).',
  ]),
  PolicySection('Кто это видит', [
    'Ресторан, в котором вы забронировали (ваш номер телефона и код), и команда HARA, которая управляет сервисом.',
    'Мы не продаём ваши данные и не передаём их рекламодателям.',
  ]),
  PolicySection('Как долго мы это храним', [
    'Записи о бронях хранятся столько, сколько нужно для работы сервиса и решения споров. Вы можете попросить удалить номер телефона, связанный с вашими бронями: см. раздел «Связаться с нами» в приложении.',
  ]),
  PolicySection('Ваши возможности', [
    'Владельцы ресторанов и официанты могут удалить аккаунт прямо в приложении: имя, e-mail и номер телефона удаляются, а ресторан остаётся в HARA.',
    'Клиенты могут попросить удалить номер телефона из прошлых броней через «Связаться с нами».',
    'Вы можете в любой момент очистить данные приложения на телефоне.',
  ]),
  PolicySection('Изменения и связь', [
    'Если эта политика изменится, мы обновим её здесь. По вопросам обращайтесь через раздел «Связаться с нами» в приложении.',
  ]),
];

const _en = [
  PolicySection('What we collect', [
    'When you reserve a table: your phone number, the restaurant, the time of the reservation (a table is held for 30 minutes). You do not need an account for this.',
    'When a restaurant owner or waiter registers: name, email, an optional phone number, a password (stored only in scrambled form that cannot be read back) and, for owners, the restaurant\'s details.',
    'On your phone: your language choice, your active reservation code and, if you are signed in, your sign-in. These stay on your device.',
    'We do not collect your location, payment details or contacts, and we do not use advertising trackers.',
  ]),
  PolicySection('Why we use it', [
    'To make reservations work: the restaurant you reserved at sees your phone number and code so it can confirm the discount or reach you.',
    'To run owner and waiter accounts.',
    'To prevent abuse (we limit how many requests one device can send).',
  ]),
  PolicySection('Who can see it', [
    'The restaurant you reserved at (your phone number and code) and the HARA team who run the service.',
    'We do not sell your data and we do not share it with advertisers.',
  ]),
  PolicySection('How long we keep it', [
    'Reservation records are kept as long as they are needed to run the service and settle disputes. You can ask us to delete the phone number linked to your reservations: see Contact us in the app.',
  ]),
  PolicySection('Your choices', [
    'Restaurant owners and waiters can delete their account inside the app: their name, email and phone number are removed, and the restaurant stays listed in HARA.',
    'Customers can ask us, through Contact us, to remove their phone number from past reservations.',
    'You can clear the app\'s data on your phone at any time.',
  ]),
  PolicySection('Changes and contact', [
    'If this policy changes, we will update it here. For questions, use Contact us in the app.',
  ]),
];
