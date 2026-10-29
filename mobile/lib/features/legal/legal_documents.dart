import 'privacy_policy.dart';

/// The version of the terms of use and of the restaurant agreement in this build. They must match `LegalVersions` in the
/// backend (`Hara.Domain/Members/TermsAcceptance.cs`): the server refuses a registration for any other version. Raise them,
/// in both places, whenever a text below changes in a way people have to accept again.
const termsVersion = 1;
const venueAgreementVersion = 1;

/// The date shown under the title of the terms of use and of the restaurant agreement. Change it whenever a text changes.
const legalTextsUpdated = '2026-10-29';

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
    'HARA restoranda masa istəməyə və restoranın verdiyi endirim kodunu almağa imkan verən pulsuz tətbiqdir.',
    'HARA restoran deyil, yemək üçün ödəniş qəbul etmir və masanın hazır olacağına zəmanət vermir. Yemək, xidmət və endirim restoranın öz işidir.',
  ]),
  PolicySection('Müştərilər üçün', [
    'Masa istəmək üçün hesab açmaq lazım deyil, telefon nömrənizi yazmaq kifayətdir. Nömrənin sizə məxsus olduğunu təsdiqləmirik; başqasının nömrəsini yazmayın.',
    'Restoran sorğunuza 15 dəqiqə ərzində cavab verməlidir. Qəbul etsə, masa 30 dəqiqə sizin üçün saxlanılır və kodunuz görünür. Cavab verməzsə, sorğu bitir.',
    'Restoranda kodu göstərirsiniz, endirim restoran tərəfindən verilir. Vaxt keçdikdən sonra kod işləmir.',
    'Eyni nömrə ilə eyni vaxtda yalnız bir sorğu göndərmək olar. Sistemə zərər vurmaq, saxta və ya çoxlu sorğu göndərmək qadağandır; belə hallarda sorğularınız məhdudlaşdırıla bilər.',
  ]),
  PolicySection('Restoran sahibləri və ofisiantlar üçün', [
    'Hesabınızın parolunu gizli saxlayın. Hesabdan edilən hərəkətlərə siz cavabdehsiniz.',
    'Kodu yalnız müştəri restoranda olanda və kod etibarlı olanda təsdiqləyin. Restoran sahibi ofisiantlarının hərəkətlərinə görə cavabdehdir və yalnız həqiqətən işləyənləri təsdiqləməlidir.',
    'Restoranın şərtləri ayrıca "Restoran razılaşması"nda yazılıb.',
  ]),
  PolicySection('Qaydalar', [
    'Yanlış məlumat verməyin, başqasının adından çıxış etməyin, başqalarını narahat etməyin, tətbiqi avtomatik vasitələrlə istifadə etməyin və qanunsuz məqsədlər üçün istifadə etməyin.',
  ]),
  PolicySection('Məsuliyyət', [
    'HARA xidməti "olduğu kimi" təqdim edir və fasiləsiz işləyəcəyinə zəmanət vermir. HARA restoranın yeməyinə, xidmətinə, gözləmə müddətinə və endirimin verilməsinə görə məsuliyyət daşımır; bunlar müştəri ilə restoran arasındakı məsələdir. Qanunun icazə verdiyi həddə HARA-nın məsuliyyəti məhduddur.',
  ]),
  PolicySection('Hesabın silinməsi və dayandırılması', [
    'Restoran sahibləri və ofisiantlar hesablarını tətbiqin içində silə bilər. Qaydaları pozan hesablar və ya restoranlar HARA tərəfindən dayandırıla və ya silinə bilər.',
  ]),
  PolicySection('Dəyişikliklər və əlaqə', [
    'Şərtlər dəyişə bilər. Dəyişiklik olanda restoran sahibləri və ofisiantlar növbəti girişdə yeni versiyanı qəbul etməlidir. Tətbiqdən istifadəyə davam etməklə müştərilər də yeni şərtlərlə razılaşmış sayılır.',
    'Bu şərtlərə Azərbaycan Respublikasının qanunları tətbiq olunur. Suallar üçün tətbiqdəki "Bizimlə əlaqə" bölməsinə baxın.',
  ]),
];

const _termsRu = [
  PolicySection('Что такое HARA', [
    'HARA: бесплатное приложение, в котором можно запросить столик в ресторане и получить код на скидку, которую даёт ресторан.',
    'HARA не ресторан, не принимает оплату за еду и не гарантирует, что столик будет готов. Еда, обслуживание и скидка: дело самого ресторана.',
  ]),
  PolicySection('Для клиентов', [
    'Чтобы запросить столик, аккаунт не нужен, достаточно указать номер телефона. Мы не проверяем, что номер ваш; не указывайте чужой номер.',
    'Ресторан должен ответить на запрос в течение 15 минут. Если он принял запрос, столик удерживается за вами 30 минут и вы видите свой код. Если ответа нет, запрос закрывается.',
    'В ресторане вы показываете код, скидку даёт ресторан. После окончания времени код не действует.',
    'С одного номера одновременно можно отправить только один запрос. Запрещено вредить системе, отправлять ложные или множественные запросы; в таких случаях ваши запросы могут быть ограничены.',
  ]),
  PolicySection('Для владельцев ресторанов и официантов', [
    'Храните пароль в секрете. Вы отвечаете за действия, совершённые из вашего аккаунта.',
    'Подтверждайте код только когда клиент в ресторане и код действителен. Владелец отвечает за действия своих официантов и должен одобрять только тех, кто действительно работает.',
    'Условия для ресторана изложены отдельно, в «Соглашении с рестораном».',
  ]),
  PolicySection('Правила', [
    'Не сообщайте ложных сведений, не выдавайте себя за другого, не беспокойте других, не используйте приложение с помощью автоматических средств и в незаконных целях.',
  ]),
  PolicySection('Ответственность', [
    'HARA предоставляет сервис «как есть» и не гарантирует его бесперебойную работу. HARA не отвечает за еду, обслуживание и время ожидания в ресторане и за предоставление скидки: это вопросы между клиентом и рестораном. В пределах, допускаемых законом, ответственность HARA ограничена.',
  ]),
  PolicySection('Удаление и приостановка аккаунта', [
    'Владельцы ресторанов и официанты могут удалить свой аккаунт в приложении. Аккаунты и рестораны, нарушающие правила, могут быть приостановлены или удалены HARA.',
  ]),
  PolicySection('Изменения и связь', [
    'Условия могут меняться. При изменении владельцы ресторанов и официанты должны принять новую версию при следующем входе. Продолжая пользоваться приложением, клиенты считаются согласными с новыми условиями.',
    'К этим условиям применяется законодательство Азербайджанской Республики. По вопросам смотрите раздел «Связаться с нами» в приложении.',
  ]),
];

const _termsEn = [
  PolicySection('What HARA is', [
    'HARA is a free app where you can ask a restaurant for a table and get a discount code for the discount the restaurant gives.',
    'HARA is not a restaurant, does not take payment for meals and does not guarantee that a table will be ready. The food, the service and the discount are the restaurant\'s own business.',
  ]),
  PolicySection('For customers', [
    'You do not need an account to ask for a table, just a phone number. We do not check that the number is yours; do not enter somebody else\'s.',
    'The restaurant has to answer your request within 15 minutes. If it accepts, the table is held for you for 30 minutes and you see your code. If nobody answers, the request ends.',
    'You show the code at the restaurant, and the restaurant gives the discount. After the time is up, the code no longer works.',
    'Only one request can be in progress for a phone number at a time. Harming the system or sending false or many requests is not allowed; in such cases your requests may be limited.',
  ]),
  PolicySection('For restaurant owners and waiters', [
    'Keep your password secret. You are responsible for what is done from your account.',
    'Confirm a code only when the customer is at the restaurant and the code is valid. An owner is responsible for their waiters\' actions and should approve only people who really work there.',
    'What a restaurant promises is set out separately, in the "Restaurant agreement".',
  ]),
  PolicySection('Rules', [
    'Do not give false information, pretend to be someone else, bother other people, use the app through automated means or use it for anything unlawful.',
  ]),
  PolicySection('Responsibility', [
    'HARA provides the service "as is" and does not promise it will always be available. HARA is not responsible for a restaurant\'s food, service or waiting time, or for whether the discount is given: those are matters between the customer and the restaurant. To the extent the law allows, HARA\'s liability is limited.',
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
  PolicySection('Nə haqqında', [
    'Bu razılaşma restoranın HARA-da yer alması şərtlərini müəyyən edir. Onu restoranı təmsil edən sahib qəbul edir.',
    'Hazırda HARA restoranlar üçün pulsuzdur. Gələcəkdə haqq tətbiq edilərsə, bu barədə əvvəlcədən xəbər veriləcək və restoran istəsə, HARA-dan çıxa biləcək.',
  ]),
  PolicySection('Restoranın öhdəlikləri', [
    'Etibarlı kodu olan müştəriyə tətbiqdə göstərilən endirimi hesabdan verin. Endirim restoranın öz işidir və HARA bunu ödəmir.',
    'Qəbul etdiyiniz sorğuya görə masanı 30 dəqiqə müştəri üçün saxlayın.',
    'Sorğulara 15 dəqiqə ərzində cavab verin (qəbul və ya rədd). Cavabsız sorğular müştəri üçün pis təcrübədir və restoranın nüfuzuna təsir edə bilər.',
    'Kodu yalnız müştəri restoranda olanda təsdiqləyin. Təsdiqlənmiş kod bir daha istifadə olunmur.',
  ]),
  PolicySection('Məlumatların düzgünlüyü', [
    'Restoranın adını, ünvanını, telefonunu, endirimini və iş saatlarını düzgün saxlayın. İş saatlarını tətbiqdə özünüz dərhal dəyişə bilərsiniz; ad, ünvan və endirimin dəyişdirilməsini HARA-dan istəyirsiniz.',
    'Bağlanmağa az qalmış və ya dolu olduğunuz vaxtlarda iş saatlarını və "sorğu qəbulunu dayandırma" müddətini yeniləyin.',
  ]),
  PolicySection('Müştərilərin telefon nömrələri', [
    'Müştərinin nömrəsini yalnız həmin rezervlə bağlı onunla əlaqə saxlamaq üçün istifadə edin. Onu satmayın, üçüncü tərəflərə verməyin, reklam və ya başqa məqsədlər üçün saxlamayın.',
    'Şəxsi məlumatlarla bağlı Azərbaycan qanunvericiliyinə əməl edin.',
  ]),
  PolicySection('Ofisiantlar', [
    'Ofisiantları yalnız restoranda həqiqətən işləyən insanlar üçün təsdiqləyin və artıq işləməyənləri çıxarın. Onların hərəkətlərinə görə siz cavabdehsiniz.',
  ]),
  PolicySection('Dayandırma və çıxış', [
    'Endirimi verməkdən imtina, çoxlu şikayət və ya qaydaların pozulması halında HARA restoranı müvəqqəti gizlədə və ya silə bilər. Restoran istənilən vaxt HARA-dan çıxa bilər: hesabı silin və ya HARA ilə əlaqə saxlayın.',
  ]),
  PolicySection('Mübahisələr və qanun', [
    'HARA vasitəçi xidmətdir və restoranla müştəri arasındakı mübahisələrin tərəfi deyil. Mübahisələri öz aranızda həll etməyə çalışın, kömək üçün HARA ilə əlaqə saxlayın.',
    'Bu razılaşmaya Azərbaycan Respublikasının qanunları tətbiq olunur.',
  ]),
];

const _agreementRu = [
  PolicySection('О чём это соглашение', [
    'Это соглашение определяет условия участия ресторана в HARA. Его принимает владелец, представляющий ресторан.',
    'Сейчас HARA для ресторанов бесплатна. Если появится плата, об этом сообщат заранее, и ресторан сможет выйти из HARA.',
  ]),
  PolicySection('Что обещает ресторан', [
    'Давать клиенту с действительным кодом скидку, указанную в приложении, на счёт. Скидка за счёт ресторана, HARA её не оплачивает.',
    'Удерживать столик за клиентом 30 минут по принятому вами запросу.',
    'Отвечать на запросы в течение 15 минут (принять или отклонить). Запросы без ответа портят впечатление клиента и могут повлиять на репутацию ресторана.',
    'Подтверждать код только когда клиент в ресторане. Подтверждённый код повторно использовать нельзя.',
  ]),
  PolicySection('Достоверность данных', [
    'Поддерживайте в актуальном состоянии название, адрес, телефон, скидку и часы работы ресторана. Часы работы вы меняете в приложении сами и сразу; изменить название, адрес и скидку вы просите у HARA.',
    'Когда вы скоро закрываетесь или заполнены, обновляйте часы работы и время, за которое прекращается приём запросов.',
  ]),
  PolicySection('Номера телефонов клиентов', [
    'Используйте номер клиента только чтобы связаться с ним по этой брони. Не продавайте его, не передавайте третьим лицам, не храните для рекламы и других целей.',
    'Соблюдайте законодательство Азербайджана о персональных данных.',
  ]),
  PolicySection('Официанты', [
    'Одобряйте только тех официантов, которые действительно работают в ресторане, и удаляйте тех, кто больше не работает. За их действия отвечаете вы.',
  ]),
  PolicySection('Приостановка и выход', [
    'При отказе предоставить скидку, множестве жалоб или нарушении правил HARA может временно скрыть или удалить ресторан. Ресторан может выйти из HARA в любое время: удалите аккаунт или свяжитесь с HARA.',
  ]),
  PolicySection('Споры и закон', [
    'HARA является посредником и не является стороной споров между рестораном и клиентом. Старайтесь решать споры между собой, за помощью обращайтесь в HARA.',
    'К этому соглашению применяется законодательство Азербайджанской Республики.',
  ]),
];

const _agreementEn = [
  PolicySection('What this is', [
    'This agreement sets out the terms on which a restaurant takes part in HARA. It is accepted by the owner who represents the restaurant.',
    'HARA is free for restaurants for now. If a fee is introduced, you will be told in advance and the restaurant can leave HARA.',
  ]),
  PolicySection('What the restaurant promises', [
    'To give a customer with a valid code the discount shown in the app off the bill. The discount is the restaurant\'s own; HARA does not pay it.',
    'To hold the table for the customer for 30 minutes for a request you accepted.',
    'To answer requests within 15 minutes (accept or decline). Requests left unanswered are a bad experience for customers and can hurt the restaurant\'s standing.',
    'To confirm a code only when the customer is at the restaurant. A confirmed code cannot be used again.',
  ]),
  PolicySection('Accurate information', [
    'Keep the restaurant\'s name, address, phone number, discount and opening hours correct. You change the opening hours yourself in the app, at once; you ask HARA to change the name, address and discount.',
    'When you are about to close or are full, update the opening hours and how long before closing you stop taking requests.',
  ]),
  PolicySection('Customers\' phone numbers', [
    'Use a customer\'s number only to get in touch with them about that reservation. Do not sell it, give it to third parties, or keep it for advertising or other purposes.',
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
