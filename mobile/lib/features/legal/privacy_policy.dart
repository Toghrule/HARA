/// One heading of the privacy policy with its paragraphs.
class PolicySection {
  const PolicySection(this.title, this.paragraphs);

  final String title;
  final List<String> paragraphs;
}

/// The date shown under the title. Change it whenever the text changes.
const privacyPolicyUpdated = '2026-11-17';

/// The privacy policy in each of the app's languages. It describes what the app does today; when a
/// behaviour changes (what is collected, who sees it, how long it is kept), this text must change too.
List<PolicySection> privacyPolicyFor(String languageCode) => switch (languageCode) {
      'ru' => _ru,
      'en' => _en,
      _ => _az,
    };

const _az = [
  PolicySection('Nələri toplayırıq', [
    'Endirim kodu alanda: tətbiqin telefonunuz üçün yaratdığı anonim nömrə, məkan və vaxt. Bunun üçün hesab, ad və ya telefon nömrəsi lazım deyil.',
    'Məkanın səhifəsini və ya ora yolu açanda: məkan və anonim nömrə sayılır ki, məkana neçə nəfərin baxdığını göstərək.',
    'Restoran sahibi və ya ofisiant qeydiyyatdan keçəndə: adı, e-poçtu, telefon nömrəsini (məcburi deyil), parolu (yalnız çevrilmiş, oxunmaz şəkildə) və sahibkar üçün restoranın məlumatlarını.',
    'Telefonunuzda: dil və tema seçiminizi, sevimli məkanlarınızı, anonim nömrənizi və hesaba daxil olubsunuzsa girişinizi. Bunlar yalnız sizin cihazınızda qalır.',
    'İcazə versəniz, telefonunuzun təxmini məkanını: yalnız məkanları yaxınlığa görə sıralamaq üçün. Məkan serverdə saxlanılmır. İcazə vermək məcburi deyil: imtina etsəniz, bütün məkanları yenə görürsünüz.',
    'Ödəniş məlumatınızı və əlaqələrinizi toplamırıq, reklam izləyiciləri istifadə etmirik.',
    'Müştəri Google ilə daxil olanda (məcburi deyil, yalnız rəy yazmaq üçün): Google hesabının adı, e-poçtu və profil şəkli. Parolunuzu görmürük.',
  ]),
  PolicySection('Nə üçün istifadə edirik', [
    'Endirim kodunun işləməsi üçün: məkan kodu görüb təsdiqləyir və endirimi verir.',
    'HARA ilə neçə müştəri gəldiyini və məkanlara nə qədər baxıldığını saymaq üçün; məkan və HARA bu saylara baxır.',
    'Sahibkar və ofisiant hesablarını idarə etmək üçün.',
    'Sui-istifadənin qarşısını almaq üçün (bir telefon hər məkandan gündə bir kod ala bilər, sorğuların sayını məhdudlaşdırırıq).',
  ]),
  PolicySection('Kim görür', [
    'Məkan yalnız kodu və onun təsdiqləndiyini görür. Müştərinin adını və ya telefon nömrəsini görmür.',
    'HARA komandası anonim sayları görür.',
    'Məlumatlarınızı satmırıq və reklamçılarla bölüşmürük.',
    'Rəy yazsanız, rəyiniz, ulduzlarınız, adınızın qısaldılmış forması (məsələn, "Anna K.") və profil şəkliniz tətbiqdə hamıya görünür. E-poçtunuzu yalnız HARA komandası görür, başqa müştərilər və məkanlar görmür.',
  ]),
  PolicySection('Nə qədər saxlayırıq', [
    'Kodlar və saylar xidmətin işləməsi və mübahisələrin həlli üçün lazım olduğu müddətdə saxlanılır. Anonim nömrə sizinlə əlaqələndirilə bilməz; tətbiqi yenidən qursanız, yeni nömrə yaranır.',
    'Rəylər siz silənə və ya hesabı silənə qədər saxlanılır.',
  ]),
  PolicySection('Seçimləriniz', [
    'Restoran sahibləri və ofisiantlar hesablarını tətbiqin içində silə bilər: adları, e-poçtları və telefon nömrələri silinir, restoran isə HARA-da qalır.',
    'Tətbiqin məlumatlarını telefonunuzda istənilən vaxt silə bilərsiniz; yeni anonim nömrə yaranacaq.',
    'Google ilə daxil olmuş müştəri hesabını tətbiqin içində silə bilər: hesab və yazdığı bütün rəylər silinir. HARA komandası da qaydaları pozan rəyi silə bilər.',
  ]),
  PolicySection('Dəyişikliklər və əlaqə', [
    'Siyasət dəyişərsə, onu burada yeniləyəcəyik. Suallar üçün tətbiqdəki "Bizimlə əlaqə" bölməsindən istifadə edin.',
  ]),
];

const _ru = [
  PolicySection('Что мы собираем', [
    'Когда вы получаете код скидки: анонимный номер, который приложение создало для вашего телефона, заведение и время. Для этого не нужны аккаунт, имя или номер телефона.',
    'Когда вы открываете страницу заведения или путь к нему: заведение и анонимный номер учитываются, чтобы показать заведению, сколько людей на него смотрят.',
    'Когда регистрируется владелец или официант: имя, email, необязательный номер телефона, пароль (хранится только в зашифрованном виде, который нельзя прочитать) и, для владельцев, данные ресторана.',
    'На вашем телефоне: выбор языка и темы, избранные заведения, ваш анонимный номер и, если вы вошли, ваш вход. Это остаётся на вашем устройстве.',
    'Если вы разрешите, примерное местоположение телефона: только чтобы сортировать заведения по близости. На сервере оно не хранится. Разрешение необязательно: если откажетесь, вы всё равно видите все заведения.',
    'Мы не собираем ваши платёжные данные и контакты и не используем рекламные трекеры.',
    'Когда клиент входит через Google (необязательно, только чтобы писать отзывы): имя, email и фото профиля аккаунта Google. Вашего пароля мы не видим.',
  ]),
  PolicySection('Зачем мы это используем', [
    'Чтобы работали коды скидок: заведение видит код, подтверждает его и даёт скидку.',
    'Чтобы считать, сколько клиентов пришло благодаря HARA и сколько раз смотрели заведения; заведение и HARA видят эти числа.',
    'Чтобы вести аккаунты владельцев и официантов.',
    'Чтобы предотвращать злоупотребления (один телефон может получить один код на заведение в день, мы ограничиваем число запросов).',
  ]),
  PolicySection('Кто это видит', [
    'Заведение видит только код и то, что он подтверждён. Оно не видит имени или номера телефона клиента.',
    'Команда HARA видит анонимные числа.',
    'Мы не продаём ваши данные и не делимся ими с рекламодателями.',
    'Если вы напишете отзыв, ваш отзыв, оценка, сокращённое имя (например, «Анна К.») и фото профиля видны всем в приложении. Ваш email видит только команда HARA, другие клиенты и заведения его не видят.',
  ]),
  PolicySection('Как долго мы храним', [
    'Коды и числа хранятся столько, сколько нужно для работы сервиса и разрешения споров. Анонимный номер нельзя связать с вами; если переустановить приложение, создаётся новый.',
    'Отзывы хранятся, пока вы не удалите их или аккаунт.',
  ]),
  PolicySection('Ваш выбор', [
    'Владельцы ресторанов и официанты могут удалить аккаунт в приложении: их имя, email и телефон удаляются, а ресторан остаётся в HARA.',
    'Вы можете в любой момент очистить данные приложения на телефоне; будет создан новый анонимный номер.',
    'Клиент, вошедший через Google, может удалить аккаунт в приложении: аккаунт и все его отзывы удаляются. Команда HARA также может удалить отзыв, нарушающий правила.',
  ]),
  PolicySection('Изменения и контакты', [
    'Если политика изменится, мы обновим её здесь. По вопросам используйте «Связаться с нами» в приложении.',
  ]),
];

const _en = [
  PolicySection('What we collect', [
    'When you get a discount code: an anonymous number the app made for your phone, the place and the time. You do not need an account, a name or a phone number for this.',
    'When you open a place\'s page or the way to it: the place and the anonymous number are counted, so we can show the place how many people look at it.',
    'When a restaurant owner or waiter registers: name, email, an optional phone number, a password (stored only in scrambled form that cannot be read back) and, for owners, the restaurant\'s details.',
    'On your phone: your language and theme choice, your favorite places, your anonymous number and, if you are signed in, your sign-in. These stay on your device.',
    'If you allow it, your phone\'s approximate location: only to sort places by how close they are. It is not stored on the server. Allowing it is optional: if you say no you still see every place.',
    'We do not collect your payment details or contacts, and we do not use advertising trackers.',
    'When a customer signs in with Google (optional, only to write reviews): the name, email and profile picture of the Google account. We never see your password.',
  ]),
  PolicySection('Why we use it', [
    'To make discount codes work: the place sees the code, confirms it and gives the discount.',
    'To count how many customers HARA brings and how often places are looked at; the place and HARA see these numbers.',
    'To run owner and waiter accounts.',
    'To prevent abuse (a phone can get one code per place per day, and we limit how many requests one device can send).',
  ]),
  PolicySection('Who can see it', [
    'The place sees only the code and that it was confirmed. It does not see a customer\'s name or phone number.',
    'The HARA team sees the anonymous counts.',
    'We do not sell your data and we do not share it with advertisers.',
    'If you write a review, the review, your stars, a shortened form of your name (for example "Anna K.") and your profile picture are visible to everyone in the app. Your email is seen only by the HARA team, not by other customers or places.',
  ]),
  PolicySection('How long we keep it', [
    'Codes and counts are kept as long as they are needed to run the service and settle disputes. The anonymous number cannot be linked to you; if you reinstall the app, a new one is made.',
    'Reviews are kept until you remove them or delete your account.',
  ]),
  PolicySection('Your choices', [
    'Restaurant owners and waiters can delete their account inside the app: their name, email and phone number are removed, and the restaurant stays listed in HARA.',
    'You can clear the app\'s data on your phone at any time; a new anonymous number will be made.',
    'A customer signed in with Google can delete their account inside the app: the account and every review they wrote are removed. The HARA team can also remove a review that breaks the rules.',
  ]),
  PolicySection('Changes and contact', [
    'If this policy changes, we will update it here. For questions, use Contact us in the app.',
  ]),
];
