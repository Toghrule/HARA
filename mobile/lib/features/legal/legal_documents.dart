import 'privacy_policy.dart';

/// The version of the terms of use and of the restaurant agreement in this build. They must match `LegalVersions` in the
/// backend (`Hara.Domain/Members/TermsAcceptance.cs`): the server refuses a registration for any other version. Raise them,
/// in both places, whenever a text below changes in a way people have to accept again.
const termsVersion = 2;
const venueAgreementVersion = 2;

/// The date shown under the title of the terms of use and of the restaurant agreement. Change it whenever a text changes.
const legalTextsUpdated = '2026-11-16';

/// Which text.
enum LegalText { terms, venueAgreement }

/// The text in the language the app is showing. These are DRAFTS: a lawyer has to read them (and the law of Azerbaijan
/// has the last word) before the app goes to the stores.
List<PolicySection> legalTextFor(LegalText text, String languageCode) => switch ((text, languageCode)) {
      (LegalText.terms, 'ru') => _termsRu,
      (LegalText.terms, 'en') => _termsEn,
      (LegalText.terms, _) => _termsAz,
      (LegalText.venueAgreement, 'ru') => _agreementRu,
      (LegalText.venueAgreement, 'en') => _agreementEn,
      (LegalText.venueAgreement, _) => _agreementAz,
    };

// ---------------------------------------------------------------------------------------------------------------------
// Terms of use (everybody: customers, restaurant owners, waiters)
// ---------------------------------------------------------------------------------------------------------------------

const _termsAz = [
  PolicySection('HARA nədir', [
    'HARA yemək-içki məkanlarını kəşf etməyə və onların verdiyi endirimləri almağa imkan verən pulsuz tətbiqdir.',
    'HARA restoran deyil, yemək üçün ödəniş qəbul etmir və masa ayırmır. Yemək, xidmət və endirim məkanın öz işidir.',
  ]),
  PolicySection('Müştərilər üçün', [
    'Hesab açmaq lazım deyil. Endirim verən məkanda "Endirimi əldə et" düyməsini basırsınız və kod alırsınız. Kod 6 saat etibarlıdır. Bir telefon hər məkandan gündə bir kod ala bilər; kod istifadə olunmadan vaxtı bitsə, yenisi növbəti gün verilir.',
    'Kodu məkanın işçisinə göstərirsiniz. Məkan kodu təsdiqləyir və endirimi verir. Təsdiqlənmiş kod yenidən işləmir.',
    'Telefonları bir-birindən ayırmaq üçün tətbiq sizin telefon üçün anonim nömrə yaradır (bu, adınız və ya telefon nömrəniz deyil). Sistemə zərər vurmaq və ya çoxlu kod almağa çalışmaq qadağandır; belə hallarda kodlarınız məhdudlaşdırıla bilər.',
  ]),
  PolicySection('Restoran sahibləri və ofisiantlar üçün', [
    'Hesabınızın parolunu gizli saxlayın. Hesabdan edilən hərəkətlərə siz cavabdehsiniz.',
    'Kodu yalnız müştəri məkanda olanda və kod etibarlı olanda təsdiqləyin. Restoran sahibi ofisiantlarının hərəkətlərinə görə cavabdehdir və yalnız həqiqətən işləyənləri təsdiqləməlidir.',
    'Restoranın şərtləri ayrıca "Restoran razılaşması"nda yazılıb.',
  ]),
  PolicySection('Qaydalar', [
    'Yanlış məlumat verməyin, başqasının adından çıxış etməyin, başqalarını narahat etməyin, tətbiqi avtomatik vasitələrlə istifadə etməyin və qanunsuz məqsədlər üçün istifadə etməyin.',
  ]),
  PolicySection('Məsuliyyət', [
    'HARA xidməti "olduğu kimi" təqdim edir və fasiləsiz işləyəcəyinə zəmanət vermir. HARA məkanın yeməyinə, xidmətinə və endirimin verilməsinə görə məsuliyyət daşımır: bunlar müştəri ilə məkan arasındakı məsələdir. Qanunun icazə verdiyi qədər HARA-nın məsuliyyəti məhduddur.',
  ]),
  PolicySection('Hesabın silinməsi və dayandırılması', [
    'Restoran sahibləri və ofisiantlar hesablarını tətbiqin içində silə bilər. Qaydaları pozan hesablar və ya restoranlar HARA tərəfindən dayandırıla və ya silinə bilər.',
  ]),
  PolicySection('Dəyişikliklər və əlaqə', [
    'Şərtlər dəyişə bilər. Dəyişiklik olanda restoran sahibləri və ofisiantlar növbəti girişdə yeni versiyanı qəbul etməlidir. Tətbiqdən istifadəyə davam etməklə müştərilər yeni şərtlərlə razılaşmış sayılır.',
    'Bu şərtlərə Azərbaycan Respublikasının qanunları tətbiq olunur. Suallar üçün tətbiqdəki "Bizimlə əlaqə" bölməsinə baxın.',
  ]),
];

const _termsRu = [
  PolicySection('Что такое HARA', [
    'HARA — бесплатное приложение, в котором можно находить места, где поесть и выпить, и получать скидки, которые они предлагают.',
    'HARA не ресторан, не принимает оплату за еду и не бронирует столы. Еда, обслуживание и скидка — дело самого заведения.',
  ]),
  PolicySection('Для клиентов', [
    'Аккаунт не нужен. В заведении со скидкой нажмите «Получить скидку» и получите код. Код действует 6 часов. Один телефон может получить один код на заведение в день; если код истёк неиспользованным, новый выдают на следующий день.',
    'Покажите код сотруднику заведения. Заведение подтверждает код и даёт скидку. Подтверждённый код повторно не работает.',
    'Чтобы различать телефоны, приложение создаёт для вашего телефона анонимный номер (это не ваше имя и не номер телефона). Нельзя вредить системе или пытаться получить много кодов; в таких случаях ваши коды могут быть ограничены.',
  ]),
  PolicySection('Для владельцев ресторанов и официантов', [
    'Держите пароль в тайне. Вы отвечаете за действия, совершённые из вашего аккаунта.',
    'Подтверждайте код только когда клиент в заведении и код действителен. Владелец отвечает за действия своих официантов и должен одобрять только тех, кто действительно там работает.',
    'Условия ресторана изложены отдельно, в «Соглашении с рестораном».',
  ]),
  PolicySection('Правила', [
    'Не сообщайте ложных сведений, не выдавайте себя за другого, не беспокойте других, не используйте приложение автоматизированно и в незаконных целях.',
  ]),
  PolicySection('Ответственность', [
    'HARA предоставляет сервис «как есть» и не обещает, что он будет всегда доступен. HARA не отвечает за еду, обслуживание заведения и за то, будет ли дана скидка: это вопросы между клиентом и заведением. В пределах, допускаемых законом, ответственность HARA ограничена.',
  ]),
  PolicySection('Удаление и приостановка аккаунтов', [
    'Владельцы ресторанов и официанты могут удалить аккаунт в приложении. Аккаунты и рестораны, нарушающие правила, могут быть приостановлены или удалены HARA.',
  ]),
  PolicySection('Изменения и контакты', [
    'Условия могут меняться. При изменении владельцы ресторанов и официанты должны принять новую версию при следующем входе. Продолжая пользоваться приложением, клиенты считаются согласившимися с новыми условиями.',
    'К этим условиям применяется закон Азербайджанской Республики. По вопросам смотрите «Связаться с нами» в приложении.',
  ]),
];

const _termsEn = [
  PolicySection('What HARA is', [
    'HARA is a free app for discovering places to eat and drink and getting the discounts they give.',
    'HARA is not a restaurant, does not take payment for meals and does not reserve tables. The food, the service and the discount are the place\'s own business.',
  ]),
  PolicySection('For customers', [
    'You do not need an account. At a place that gives a discount, tap "Get the discount" to get a code. The code is valid for 6 hours. A phone can get one code per place per day; if it runs out unused, a new one comes the next day.',
    'You show the code to the place\'s staff. The place confirms it and gives the discount. A confirmed code cannot be used again.',
    'To tell phones apart, the app makes an anonymous number for your phone (it is not your name or your phone number). Harming the system or trying to get many codes is not allowed; in such cases your codes may be limited.',
  ]),
  PolicySection('For restaurant owners and waiters', [
    'Keep your password secret. You are responsible for what is done from your account.',
    'Confirm a code only when the customer is at the place and the code is valid. An owner is responsible for their waiters\' actions and should approve only people who really work there.',
    'What a restaurant promises is set out separately, in the "Restaurant agreement".',
  ]),
  PolicySection('Rules', [
    'Do not give false information, pretend to be someone else, bother other people, use the app through automated means or use it for anything unlawful.',
  ]),
  PolicySection('Responsibility', [
    'HARA provides the service "as is" and does not promise it will always be available. HARA is not responsible for a place\'s food or service, or for whether the discount is given: those are matters between the customer and the place. To the extent the law allows, HARA\'s liability is limited.',
  ]),
  PolicySection('Deleting and suspending accounts', [
    'Restaurant owners and waiters can delete their account inside the app. Accounts and restaurants that break the rules can be suspended or removed by HARA.',
  ]),
  PolicySection('Changes and contact', [
    'The terms may change. When they do, restaurant owners and waiters have to accept the new version the next time they sign in. By continuing to use the app, customers are taken to agree to the new terms.',
    'The law of the Republic of Azerbaijan applies to these terms. For questions, see "Contact us" in the app.',
  ]),
];

// ---------------------------------------------------------------------------------------------------------------------
// Restaurant agreement (owners; waiters work under the owner's)
// ---------------------------------------------------------------------------------------------------------------------

const _agreementAz = [
  PolicySection('Bu nədir', [
    'Bu razılaşma restoranın HARA-da iştirak şərtlərini bildirir. Onu restoranı təmsil edən sahibkar qəbul edir.',
    'HARA hələlik restoranlar üçün pulsuzdur. Haqq tətbiq olunarsa, bu barədə əvvəlcədən xəbər veriləcək və restoran HARA-dan çıxa biləcək.',
  ]),
  PolicySection('Restoranın vədləri', [
    'Etibarlı kodu olan müştəriyə tətbiqdə göstərilən endirimi hesabdan vermək. Endirim restoranın öz endirimidir, HARA onu ödəmir.',
    'Kodu yalnız müştəri restoranda olanda təsdiqləmək. Təsdiqlənmiş kod yenidən istifadə oluna bilməz. Kod 6 saat etibarlıdır.',
    'Təsdiqlənmiş hər kod "HARA-nın gətirdiyi müştəri" kimi sayılır; bu say sizə və HARA-ya göstərilir.',
  ]),
  PolicySection('Dəqiq məlumat', [
    'Restoranın adını, ünvanını, telefonunu, endirimini və iş saatlarını düzgün saxlayın. İş saatlarını özünüz tətbiqdə dərhal dəyişirsiniz; adı, ünvanı və endirimi dəyişmək üçün HARA-dan xahiş edirsiniz. Artıq verilmiş kodlar verildiyi andakı endirimi saxlayır.',
    'Bağlanmaq üzrə olanda iş saatlarını yeniləyin.',
  ]),
  PolicySection('HARA sizə nəyi göstərir', [
    'HARA hər restoran üçün saylar göstərir: neçə kod alınıb, neçəsi təsdiqlənib, restoranın səhifəsi neçə dəfə açılıb və ora yol neçə dəfə açılıb. HARA bu nəticələri sizə aylıq göndərə bilər. Saylar anonimdir.',
  ]),
  PolicySection('Müştərilər anonimdir', [
    'Müştərinin adını və ya telefon nömrəsini görmürsünüz, yalnız kodu görürsünüz. Müştərilərin kim olduğunu öyrənməyə çalışmayın və onlardan endirim üçün şəxsi məlumat tələb etməyin.',
    'Şəxsi məlumatlara dair Azərbaycan qanununa əməl edin.',
  ]),
  PolicySection('Ofisiantlar', [
    'Ofisiant kimi yalnız restoranda həqiqətən işləyənləri təsdiqləyin, artıq işləməyənləri çıxarın. Onların hərəkətlərinə siz cavabdehsiniz.',
  ]),
  PolicySection('Dayandırma və çıxış', [
    'Restoran endirimi verməkdən imtina edərsə, çoxlu şikayət alarsa və ya qaydaları pozarsa, HARA onu gizlədə və ya silə bilər. Restoran istənilən vaxt HARA-dan çıxa bilər: hesabı silin və ya HARA ilə əlaqə saxlayın.',
  ]),
  PolicySection('Mübahisələr və qanun', [
    'HARA vasitəçidir və restoranla müştəri arasındakı mübahisələrin tərəfi deyil. Onları aranızda həll etməyə çalışın, kömək üçün HARA ilə əlaqə saxlayın.',
    'Bu razılaşmaya Azərbaycan Respublikasının qanunları tətbiq olunur.',
  ]),
];

const _agreementRu = [
  PolicySection('Что это', [
    'Это соглашение определяет условия участия ресторана в HARA. Его принимает владелец, представляющий ресторан.',
    'Пока HARA бесплатна для ресторанов. Если появится плата, вас предупредят заранее, и ресторан сможет выйти из HARA.',
  ]),
  PolicySection('Что обещает ресторан', [
    'Давать клиенту с действительным кодом скидку на счёт, указанную в приложении. Скидка — собственная скидка ресторана, HARA её не оплачивает.',
    'Подтверждать код только когда клиент в ресторане. Подтверждённый код повторно использовать нельзя. Код действует 6 часов.',
    'Каждый подтверждённый код считается «клиентом, которого привела HARA»; это число показывается вам и HARA.',
  ]),
  PolicySection('Точные сведения', [
    'Поддерживайте в актуальном виде название, адрес, телефон, скидку и часы работы ресторана. Часы работы вы меняете сами в приложении, сразу; название, адрес и скидку меняет HARA по вашей просьбе. Уже выданные коды сохраняют скидку, действовавшую в момент выдачи.',
    'Когда собираетесь закрываться, обновите часы работы.',
  ]),
  PolicySection('Что HARA показывает вам', [
    'HARA показывает по каждому ресторану числа: сколько кодов получено, сколько подтверждено, сколько раз открыли страницу ресторана и сколько раз открыли путь к нему. HARA может присылать вам эти итоги ежемесячно. Числа анонимны.',
  ]),
  PolicySection('Клиенты анонимны', [
    'Вы не видите ни имени, ни номера телефона клиента, только код. Не пытайтесь выяснить, кто клиенты, и не требуйте у них личных данных ради скидки.',
    'Соблюдайте закон Азербайджана о персональных данных.',
  ]),
  PolicySection('Официанты', [
    'Одобряйте в качестве официантов только тех, кто действительно работает в ресторане, и удаляйте тех, кто больше не работает. Вы отвечаете за их действия.',
  ]),
  PolicySection('Приостановка и выход', [
    'Если ресторан отказывается давать скидку, получает много жалоб или нарушает правила, HARA может скрыть или удалить его. Ресторан может выйти из HARA в любой момент: удалите аккаунт или свяжитесь с HARA.',
  ]),
  PolicySection('Споры и закон', [
    'HARA — посредник и не является стороной споров между рестораном и клиентом. Старайтесь решать их между собой, за помощью обращайтесь в HARA.',
    'К этому соглашению применяется закон Азербайджанской Республики.',
  ]),
];

const _agreementEn = [
  PolicySection('What this is', [
    'This agreement sets out the terms on which a restaurant takes part in HARA. It is accepted by the owner who represents the restaurant.',
    'HARA is free for restaurants for now. If a fee is introduced, you will be told in advance and the restaurant can leave HARA.',
  ]),
  PolicySection('What the restaurant promises', [
    'To give a customer with a valid code the discount shown in the app off the bill. The discount is the restaurant\'s own; HARA does not pay it.',
    'To confirm a code only when the customer is at the restaurant. A confirmed code cannot be used again. A code is valid for 6 hours.',
    'Every confirmed code counts as a customer HARA brought; that count is shown to you and to HARA.',
  ]),
  PolicySection('Accurate information', [
    'Keep the restaurant\'s name, address, phone number, discount and opening hours correct. You change the opening hours yourself in the app, at once; you ask HARA to change the name, address and discount. Codes already given keep the discount they were given with.',
    'When you are about to close, update the opening hours.',
  ]),
  PolicySection('What HARA shows you', [
    'HARA shows, for each restaurant, how many codes were taken, how many were confirmed, how often the restaurant\'s page was opened and how often the way to it was opened. HARA may send you these results every month. The numbers are anonymous.',
  ]),
  PolicySection('Customers are anonymous', [
    'You do not see a customer\'s name or phone number, only the code. Do not try to find out who customers are, and do not ask them for personal data for the discount.',
    'Follow the law of Azerbaijan on personal data.',
  ]),
  PolicySection('Waiters', [
    'Approve only people who really work at the restaurant as waiters, and remove those who no longer do. You are responsible for what they do.',
  ]),
  PolicySection('Suspension and leaving', [
    'If a restaurant refuses to give the discount, gets many complaints or breaks the rules, HARA can hide or remove it. A restaurant can leave HARA at any time: delete the account or contact HARA.',
  ]),
  PolicySection('Disputes and law', [
    'HARA is an intermediary and is not a party to disputes between a restaurant and a customer. Try to settle them between you, and contact HARA for help.',
    'The law of the Republic of Azerbaijan applies to this agreement.',
  ]),
];
