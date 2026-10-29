# HARA — Handoff (yeni söhbət üçün)

Bu fayl yeni söhbətin (insan və ya Claude) layihə haqqında heç nə bilmədən işə başlaması üçündür.
Vəziyyət **2026-10-08**-ə görədir. Hər şeydən əvvəl `git log --oneline -10` və `git status` ilə faylın hələ də aktual olduğunu yoxlayın.

---

## İstifadə şərtləri və restoran razılaşması (2026-10-29, boşluq #21)
- **İki mətn (QARALAMA, hüquqi baxış LAZIMDIR):** "İstifadə şərtləri" (hamı üçün: müştəri, owner, ofisiant) və "Restoran razılaşması" (owner: endirimi vermək, 15 dəq cavab, 30 dəq masa, telefon nömrələrindən yalnız rezerv üçün istifadə, məlumatların düzgünlüyü, ofisiantlara cavabdehlik, dayandırma/çıxış, mübahisə, Azərbaycan qanunu). 3 dildə: `mobile/lib/features/legal/legal_documents.dart`. Hazırda restoranlar üçün HARA PULSUZDUR (razılaşmada belə yazılıb; haqq gələndə əvvəlcədən xəbər veriləcək). Tarix: `legalTextsUpdated`.
- **Kim nəyi qəbul edir (istifadəçinin seçimi):** owner qeydiyyatda İKİ qutu (şərtlər + məxfilik siyasəti, restoran razılaşması), ofisiant BİR qutu (şərtlər + məxfilik); müştəri yalnız oxuyur (xoş gəldin və giriş ekranında "İstifadə şərtləri" linki, "Haqqında" ekranında hər iki mətn). Mətnlərin yolları `/terms` və `/restaurant-agreement` (`/venue-...` YOX: `/venue` ilə başlayan yollar giriş tələb edir).
- **Qeyd:** `TermsAcceptances` cədvəli (kim, hansı mətn, hansı versiya, nə vaxt; yalnız əlavə olunur, hesabla silinir). Qeydiyyatda mobil qəbul etdiyi versiyanı göndərir, server cari versiyadan fərqlisini rədd edir.
- **Versiya dəyişəndə:** `Hara.Domain/Members/TermsAcceptance.cs` içindəki `LegalVersions` və `legal_documents.dart` içindəki `termsVersion`/`venueAgreementVersion` EYNİ ANDA artırılır. Onda owner/ofisiant növbəti girişdə qəbul ekranı görür (`GET /api/venue/me` → `pendingTerms`), `POST /api/venue/terms/accept` ilə qəbul edir; qəbul edənə qədər restoran tərəfinin BÜTÜN əməliyyatları serverdə 403 verir (`VenueAccess`). Bu funksiyadan əvvəl yaradılmış hesabların qeydi yoxdur, onlardan da soruşulur (məsələn dev bazasındakı test owner).
- **Yoxlama:** API 46 yoxlama (izolə bazada, repoda YOXDUR; məcburi bloku söndürəndə 7-si düşdü), mobil +21 test (cəmi 295). Testlər 1 real səhv tapdı (`/venue-agreement` marşrutu giriş etməyənləri /welcome-a atırdı).
- **Edilmədi:** admin paneldə "kim nəyi nə vaxt qəbul edib" görünüşü (məlumat bazadadır); ofisiant üçün ayrıca razılaşma yoxdur (owner razılaşmasına tabedir); müştəri üçün qəbul qutusu yoxdur (yalnız oxuyur); mətnlər ictimai ünvanda yerləşdirilməyib (mağaza üçün domen lazımdır).

## Kəşf (2026-10-29, boşluq #16)
- **Süzgəclər (mobil, axtarışın altında çip sırası):** "İndi açıq" (iş saatlarına görə, server tərəfdə), "Ən yaxın", "Sevimlilər" və 12 mətbəx növü (bir seçim, yenidən basanda silinir). Süzgəclər bir-biri ilə, axtarışla və səhifələmə ilə birlikdə işləyir. Boş nəticədə "Süzgəcləri təmizlə".
- **Mətbəx növləri:** `Hara.Domain/Restaurants/Cuisines.cs` (sabit 12 kod, restoran başına ən çox 3), admin restoran formunda seçir (owner seçmir). Mobil adlar 3 dildə (`cuisineName`).
- **Şəkil qalereyası:** `Restaurant.GalleryUrls` (ən çox 10), admin formda çoxlu yükləmə, silmə, sıralama; mobil detal ekranında üfüqi sürüşdürmə, nöqtələr, toxunanda tam ekran. Örtük şəkil birinci, təkrarsız. **Şəkillər HƏLƏ YÜKLƏNMƏYİB** (istifadəçi sonra yükləyəcək); owner şəkil yükləməsi park edilib.
- **Məkan:** `geolocator` paketi, YALNIZ təxmini məkan (`ACCESS_COARSE_LOCATION`, `LocationAccuracy.low`). **İstifadəçi tətbiq ilk açılanda soruşulmasını seçdi:** siyahı ekranı ilk dəfə açılanda qısa izah pəncərəsi ("İcazə ver" / "İndi yox"), sonra sistem icazəsi; bir dəfə soruşulur (`location_asked`). İmtina edilsə A-Z qalır, "Ən yaxın" çipi sonradan yenə soruşur (həmişəlik rədd olunubsa ayarlara yönləndirir). Məsafə siyahıda və detalda cihazda hesablanır ("350 m", "1.2 km"). Server yalnız "Ən yaxın" sıralamasında `lat/lng` alır və saxlamır. Test və məkansız build-də (`NoLocationService`) heç nə soruşulmur və "Ən yaxın" çipi görünmür.
- **Sevimlilər:** ürək işarəsi siyahıda və detalda, yalnız telefonda (`shared_preferences`, hesab yoxdur); "Sevimlilər" çipi serverdən `GET /api/restaurants?ids=a,b` ilə gətirir (ən çox 100).
- **Server:** `GET /api/restaurants` indi `openNow`, `cuisine`, `ids` qəbul edir; cavabda `cuisines`, `galleryUrls`. Admin update-də bu sahələr göndərilməsə dəyişmir, boş siyahı təmizləyir. Migration `AddCuisinesAndGallery` (boş default ilə).
- **Məxfilik siyasəti qaralaması yeniləndi** (3 dil, 2026-10-29): məkan və sevimlilər əlavə olundu, köhnə "məkanı toplamırıq" cümləsi silindi. **Hüquqi baxış hələ lazımdır.**
- **Yoxlama:** API 37 yoxlama (izolə bazada, repoda YOXDUR), admin forma brauzerdə (limit 3, 2 fayl yükləndi, sıra saxlandı), mobil +32 test (cəmi 274), mutasiya yoxlaması (sevimlilərin `ids`-i silinəndə test düşdü).
- **⚠ Yoxlanmayıb:** `geolocator`-un Android Gradle quraşdırması və real telefonda icazə pəncərəsi/məkan (bu maşında Android SDK yoxdur, build GitHub Actions-dadır); iOS qurulmayıb (`NSLocationWhenInUseUsageDescription` əlavə olunub, amma iOS build edilməyib). Əgər plugin `ACCESS_FINE_LOCATION`-u manifestə özü əlavə edərsə, sistem dəqiq məkan seçimi də göstərəcək (təxmini seçmək mümkündür).
- **Edilmədi (istifadəçi seçmədi):** qiymət səviyyəsi, reytinq/rəy.

## Parol bərpası, yalnız owner üçün (2026-10-29, boşluq #13)
- **Axın (istifadəçinin dizaynı):** owner giriş ekranında "Owner parolu unutdu?" basır, emailini yazır, sorğu admin panelə düşür ("Password resets" səhifəsi, menyuda gözləyən sorğuların sayı). Admin owner-ə ZƏNG edib onun olduğunu yoxlayır, sonra Approve edir. Owner-in tətbiqi (ekran açıq qalanda 5 saniyədən bir, bağlı olsa qayıdanda) təsdiqi görür və yeni parol + təkrarı formasını açır. Təsdiqdən sonra 1 SAAT vaxt var, bir dəfəlikdir.
- **Təhlükəsizlik:** sorğu verən telefona bağlıdır. Sorğuda telefona gizli açar (`secret`) verilir, bazada yalnız SHA-256 hash saxlanır; status və tamamlama yalnız bu açarla işləyir (bədəndə, ünvanda yox). Başqası owner-in emailini bilib sorğu göndərsə də parolu dəyişə bilməz (açar onda deyil), və admin zəng edib yoxlayır. Cavab bütün emaillər üçün eynidir (hesab olub-olmadığı bilinmir); yalnız Owner rolu olan hesab üçün sorğu saxlanır (waiter və admin üçün saxlanmır). Yeni sorğu əvvəlki açıq sorğunu əvəz edir. Parol dəyişəndə bütün sessiyalar bağlanır və yanlış cəhdlərdən kilid açılır.
- **Parol ADMİNƏ GÖRÜNMÜR və heç yerdə saxlanmır** (heş). İstifadəçinin "bütün parolları görüm" təklifi bu səbəbdən rədd edildi (bax söhbət), əvəzinə bu axın seçildi.
- **Endpoint-lər:** anonim `POST /api/auth/password-reset/{request,status,complete}` (limit: sorğu 5/saat, status 600/saat, complete Login limiti); admin `GET /api/admin/password-resets[?status=]`, `POST .../{id}/approve|reject`. Cədvəl `PasswordResetRequests`, migration `AddPasswordResetRequests`. Admin paneldə zəng üçün owner adı, email, telefon, restoran görünür.
- **Texniki qeyd:** Identity-də token provayderləri qeydiyyatda deyil, ona görə `ResetPassword` işləmir; `IdentityService.SetPasswordAsync` parolu Identity-nin qaydaları ilə yoxlayıb hash-ləyib yazır.
- **Yoxlama:** API 46 yoxlama (izolə bazada, repoda YOXDUR), mobil +16 test, admin səhifə brauzerdə (təsdiq bazaya yazıldı, say göstəricisi yeniləndi). Testlər 2 real səhv tapdı (Identity token provayderi yoxdur; vaxtı keçən sorğuda ekran "yüklənir" vəziyyətində qalırdı).
- **Edilmir / məhdudiyyət:** ofisiant üçün bərpa yoxdur (istifadəçi "yalnız owner" dedi; owner ofisiantı silib yenidən qeydiyyat etdirə bilər); email göndərilmir; admin-ə bildiriş yoxdur (yalnız paneldə say); admin yoxlamanı ZƏNG ilə öz məsuliyyətində edir, sistem bunu məcbur etmir; admin parolu bu axına daxil deyil. Mobil əsas ekranları cihazda (telefonda) yoxlanmayıb.

## İş saatları (2026-10-29, boşluq #6)
- **Saxlanma:** `Restaurant.OpeningHours` (JSON sütunu, 7 gün: açılış/bağlanış dəqiqə ilə) və `LastRequestMinutesBeforeClose` (default 30). Boş siyahı = saat qoyulmayıb = restoran HƏMİŞƏ AÇIQ sayılır (mövcud restoranlar belədir). Migration `AddOpeningHours`.
- **Məntiq:** `Hara.Domain/Restaurants/OpeningHours.cs` (`OpeningSchedule.Evaluate`), Azərbaycan vaxtı (UTC+4). Bağlanış saatı açılışdan əvvəl/bərabərdirsə gecə yarısından sonraya keçir (18:00-02:00); açılış = bağlanış 24 saat açıq deməkdir. Həftə sonu keçidi (şənbə gecəsi bazara) işləyir.
- **Kim dəyişir:** yalnız owner, mobil tətbiqdə, dərhal (admin təsdiqi YOXDUR): `PUT /api/venue/opening-hours` (7 gün və ya boş siyahı = saatları sil + bağlanmadan neçə dəqiqə əvvəl sorğunu dayandır, 0-180). Admin paneldə saat dəyişdirmək yoxdur.
- **Müştəri:** `GET /api/restaurants` və `/{id}` indi `openingHours` + `availability` (açıq / tezliklə bağlanır / bağlı və növbəti açılış) qaytarır. Bağlı və ya bağlanmağa az qalmış restoranda "Rezerv" düyməsi söndürülür, siyahıda səbəb yazılır. `POST /api/reservations` də server tərəfdə 400 ilə rədd edir (ingiliscə mesaj, tətbiq onu olduğu kimi göstərir).
- **Yoxlama:** məntiq 22 yoxlama (scratchpad konsol layihəsi, repoda YOXDUR), API 37 yoxlama (izolə bazada, repoda YOXDUR), mobil +15 test. Mutasiya yoxlaması: serverdə bağlı yoxlamasını söndürəndə 5 yoxlama düşdü.
- **Bilinən məhdudiyyətlər:** tətbiqdə göstərilən vəziyyət siyahını yükləyən andakıdır (saatlar keçəndə siyahı özü yenilənmir, server isə həmişə düzgün qərar verir); bağlı restoranda server mesajı ingiliscədir; qəbul olunmuş rezervin 30 dəqiqəsi bağlanış saatını keçə bilər ("bağlanmadan nə qədər əvvəl" seçimi bunu azaldır).

## Statistika (2026-10-29, boşluq #1 qismən)
- **Admin panel:** "Statistics" səhifəsi (`/statistics`), `GET /api/admin/stats/restaurants`: hər restoran üçün bu ay / keçən ay / hamısı: sorğu, qəbul, rədd, cavabsız, gəldi (təsdiqlənən), gəlmədi (qəbul olunub, vaxtı bitib, kod təsdiqlənməyib). Say sorğunun yaranma tarixinə görədir.
- **Mobil, yeni "Statistika" tabı** (`GET /api/venue/stats`): sahibkar restoranın bu gün / bu ay / bu il üzrə qəbul edilən və gələn (təsdiqlənən) saylarını görür; ofisiant (və sahibkar) bu gün özünün təsdiqlədiyi kodların sayını görür. Ofisiantə restoran üzrə sayılar GÖNDƏRİLMİR (backend `null` qaytarır).
- **Qərarlar:** "gün/ay/il" Azərbaycan vaxtı ilə (UTC+4, `BakuTime.cs`). Qəbul = cavab verilib və rədd edilməyib (`RespondedAt` var, status `Declined` deyil); gələn = `Redeemed`. **Hesab məbləği YAZILMIR** (istifadəçi ləğv etdi), gəlir məbləği göstərilmir; boşluq #4 hələ açıqdır.
- Backend 19 yoxlama (izolə bazada), mobil 3 yeni test; admin panel brauzerdə yoxlanıb. Admin paneldə avtomatik test yoxdur.

## Push bildirişlər (2026-10-13)
- **Necə işləyir:** Firebase Cloud Messaging. Yeni sorğu gələndə restoranın təsdiqlənmiş sahibkarı/ofisiantlarının telefonlarına, qəbul/rədd olunanda müştərinin telefonuna bildiriş gedir (3 dildə mətn, `PushTexts.cs`). `ReservationNotifier` (Application) yaradılma və cavab handler-lərindən çağırılır; göndərmə xətası sorğunu pozmur, Firebase-in rədd etdiyi token-lər silinir. **Cavabsız qalma (15 dəq) üçün push YOXDUR** (serverdə fon işi yoxdur); müştəri tətbiqi bunu özü hesablayır.
- **Token-lər:** `DeviceTokens` cədvəli (`UserId` = restoran hesabı, `ReservationId` = müştəri sorğusu). Müştəri token-i sorğu kodu ilə qeyd olunur; bir telefonda başqa hesab girəndə köhnə hesabın sətri silinir; çıxışda mobil əvvəl `unregister` edir.
- **Açarlar:** `mobile/android/app/google-services.json` (gizli deyil, git-dədir). Server açarı `backend/secrets/firebase-adminsdk.json` **git-ə düşmür** (.gitignore); `Firebase:CredentialsPath` (appsettings.json) yuxarı qovluqlarda axtarılır, istehsalda mütləq yol verin. Açar yoxdursa bildirişlər söndürülür, qalan hər şey işləyir. Firebase layihəsi: `hara1st`.
- **Mobil:** `lib/core/push/` (`PushService` interfeysi, `FirebasePushService`, `PushRegistrar`, `push_events`). Testlərdə `NoPushService`. Yalnız Android işə salınır.
- **⚠ Yoxlanmayıb:** bu maşında Android SDK yoxdur, ona görə Gradle quraşdırması (google-services plugin 4.5.0, AGP 9.1.0 ilə) və real telefona bildiriş çatması **sınanmayıb**. Backend Firebase ilə əlaqə testi (saxta token-in rədd edilib silinməsi) keçib. iPhone üçün Apple APNs açarı + GoogleService-Info.plist lazımdır (edilməyib). Windows-da plugin ilə build üçün Developer Mode lazımdır.

## Pilot (real insanlarla sınaq) — 2026-10-28
- `start-pilot.bat` AYRI mühit qaldırır: baza `hara_pilot`, API `localhost:5082` (Production), admin panel `localhost:5175`, Cloudflare quick tunnel (`tools/cloudflared/cloudflared.exe`, gitignore, rəsmi hash yoxlanıb). Gündəlik dev (5080/5173/5174, baza `hara`) toxunulmaz. Tunel ünvanı `tools/cloudflared/current-url.txt`-dədir.
- **Məhdudiyyət:** quick tunnel ünvanı hər yenidən başlamada dəyişir, APK isə ünvana bağlıdır (`--dart-define=API_BASE_URL`). Sabit ünvan üçün Cloudflare hesabı + domen (named tunnel) və ya VPS lazımdır.
- Server proxy arxasındadır: `UseForwardedHeaders` yalnız lokal proxy-ni (loopback) etibarlı sayır, limitlər real müştəri IP-sinə görə işləyir.

## 1. Layihənin məqsədi

**HARA** ("hara" = "where", şüar: *"Hara? deyə düşünmə"*) — məkan kəşfi + masa rezervasiyası tətbiqidir. Məqsəd: insanlar həmişə eyni tanış yerlərə getməsin, yeni məkanları kəşf etsin.

**Müştəri tərəfi (pulsuz):**
- Müştəri məkanı seçir, **telefon nömrəsi** ilə masa **sorğusu** göndərir (ödəniş yoxdur, hesab yoxdur). **Sorğunu restoran (sahibkar/ofisiant) 15 dəqiqə ərzində qəbul etməlidir; qəbul anından 30 dəqiqəlik taymer başlayır** (2026-10-13). Rədd edilərsə və ya 15 dəq cavab verilməzsə müştəriyə bildiriş çıxır. Bir telefon eyni anda yalnız **1 gözləyən və ya aktiv** sorğu saxlaya bilər. Bildiriş hələlik tətbiq açıqkən avtomatik yenilənmə (polling: müştəri 10 s gözləyəndə/30 s aktivdə, restoran 10 s) ilə; **Push bildirişlər (FCM) də var (2026-10-13), yalnız Android** (aşağıda "Push bildirişlər").
- Rezerv statusları: bazada `Pending=4`, `Active=0`, `Redeemed=1`, `Cancelled=2`, `Declined=5`; oxunanda hesablanır: `Expired=3` (Active, vaxtı keçib), `Unanswered=6` (Pending, 15 dəq keçib). `ExpiresAt` = cari son tarix (gözləyəndə cavab müddəti, qəbuldan sonra +30 dəq). API: `POST /api/venue/reservations/{code}/accept|decline`. Son migration: `AddReservationResponse` (RespondedAt/RespondedByUserId). FAQ 1, 4, 5, 8 yeniləndi, 9 əlavə olundu (real bazada, 3 dil).
- Rezervdən sonra qısa **kod** alır, bu müddət ərzində məkana çatıb kodu göstərir və məkanın təyin etdiyi **faiz endirimi** istəyir.
- Gələcəkdə (v1 deyil): bal/loyallıq sistemi.

**Məkan (restoran) tərəfi (gəlir mənbəyi):**
- Yeni məkana abunə haqqından azad ilkin dövr + 1 ay pulsuz premium reklam; sonra aylıq platforma haqqı; "premium" və "adi" reklam səviyyələri.
- Məkanlar tətbiqə **sorğu → admin təsdiqi** ilə daxil olur (öz-özünə qeydiyyat yoxdur, aşağıya bax).

**İstifadəçinin özü tərəfindən qeyd olunmuş, HƏLƏ AÇIQ qalan biznes suallar (dəyər uydurmayın, soruşun):**
1. Yeni məkanlar üçün pulsuz dövrün müddəti.
2. Aylıq abunə haqqı (AZN).
3. ~~Məkanın müştəri kodunu necə təsdiqləməsi~~ — **qərar verildi (2026-10-08), hələ qurulmayıb:** sahibkar/ofisiant hesabları, bax §6 №7.
4. Bonusun işlədilməsi üçün minimum hesab məbləği (AZN).

**Təsdiqlənmiş MVP həddi (2026-09-22):** məkan onboarding-i sorğu/təsdiq olaraq qalır (owner hesab sistemi yoxdur — yalnız bir ümumi admin login var). Ən vacib hissə rezervasiya + kod axını idi (hazırdır). Bonus/loyallıq, abunə avtomatlaşdırması və reklam səviyyələri **MVP üçün aşağı prioritetdir**, əl ilə/təxirə salına bilər.

## 2. Hazırkı vəziyyət (xülasə)

Üç tətbiq + baza, hamısı bu repoda (`main` branch, GitHub `Toghrule/HARA`, **ictimai** repo):

| Hissə | Qovluq | Vəziyyət |
|---|---|---|
| Backend API (.NET 9) | `backend/` | Hazırdır: restoranlar, rezervasiya, sorğular, reklam, FAQ, şirkət məlumatı, auth |
| Admin panel (React) | `frontend/` | Hazırdır: yuxarıdakıların hamısını idarə edir |
| Mobil app (Flutter) | `mobile/` | 6 planlı addımın hamısı hazırdır; **yalnız brauzerdə (web) yoxlanıb** |
| Baza | `docker-compose.yml` | Postgres 16 (konteyner `hara-postgres`) |

**Mobil app-də olanlar:** restoran siyahısı (axtarış, A-Z/Z-A sıralama, 20-lik səhifələr), restoran detalı, rezervasiya (telefon, masa həmişə 30 dəq → kod ekranı, geri sayım, ləğv), Haqqımızda / Əlaqə / FAQ. **Sahibkar/ofisiant hissəsi (2026-10-08):** qarşılama ekranı ("Müştəri kimi davam et" | Daxil ol / Sahibkar kimi qeydiyyat / Ofisiant kimi qeydiyyat), giriş, qeydiyyat formaları, sahibkar/ofisiant ana ekranı (bax aşağı). Köhnə anonim "Restoranımı əlavə et" forması **silinib** (əvəzində sahibkar qeydiyyatı).

**Rezervasiyanı restoran təsdiqləyir (2026-10-08):** sahibkar/təsdiqlənmiş ofisiant kodu `/api/venue/...` ilə yoxlayıb təsdiqləyir, **yalnız öz restoranının** kodunu (başqasının kodu "tapılmadı" kimi görünür); icazə hər sorğuda bazadakı üzvlükdən yoxlanır (token-dəki rol yetərli deyil, silinmiş ofisiantın köhnə token-i dərhal işləməz). Admin paneldə Redeem YOXDUR, Reservations yalnız oxunur. **Mobil app-də** təsdiqlənmiş sahibkar/ofisiantın ekranları var: "Kodu təsdiqlə" (kodu yaz → yoxla → endirim/telefon → təsdiq sualı), "Rezervlər" (Aktiv/İstifadə olunub/Hamısı); yalnız **sahibkara** əlavə: "Komanda" (ofisiantı təsdiqlə/rədd et/sil) və "Restoran" (dəyişiklik sorğusu göndər, cavabları gör). Ofisiant yalnız ilk iki bölməni görür.

**Aktiv rezerv (2026-10-08):** rezervdən sonra kod itmir, əsas ekranda kart kimi qalır (bax §7).

**Dillər (2026-10-08):** tətbiq **Azərbaycanca (əsas), Rusca, İngiliscə** dəstəkləyir. İlk açılışda telefonun dili (az/ru/en), uyğun deyilsə Azərbaycanca; AppBar-dakı dil düyməsi ilə dəyişir və yadda qalır (`shared_preferences`). Mobil hər sorğuya `?lang=` əlavə edir; server Haqqımızda, FAQ və restoran təsvirini həmin dildə qaytarır, tərcümə boşdursa Azərbaycancaya düşür.

## 3. Əsas qərarlar və səbəbləri

- **Flutter** seçildi (React Native/native yox): `mobile/`-də artıq router, API klienti, tema var idi; Android + iOS üçün tək kod bazası. iOS build üçün **Mac** (və ya bulud Mac CI) lazımdır, Windows-da mümkün deyil.
- **Clean Architecture backend** (`Domain` / `Application` / `Infrastructure` / `Persistence` / `Api`), CQRS (MediatR), doğrulama (FluentValidation). Yeni əməliyyat = `Commands|Queries/<Ad>/` qovluğunda Command/Query + Handler + Validator.
- **Məkan sorğusu təsdiqi restoranı avtomatik yaratmır** (`SubmissionStatus.Approved` yalnız statusdur). Səbəb: sorğuda koordinat, şəkil, endirim yoxdur; avtomatik yaratmaq yarımçıq restoranı müştərilərə göstərərdi. Əvəzinə təsdiqlənmiş sorğuda **"Create restaurant"** düyməsi formanı əvvəlcədən doldurur. İstifadəçi **sadə variantı** seçdi: sorğu ilə yaranan restoran arasında **bağlantı yoxdur** (eyni sorğudan iki dəfə restoran yaratmaq olar).
- **"Expired" və "Unanswered" statusları bazada saxlanmır**, `ExpiresAt`-dan hesablanır (`Reservation.EffectiveStatus`). Bazada `Pending/Active/Redeemed/Cancelled/Declined`.
- **Spam qoruması hesab olmadan:** hər IP üçün sürət limiti + telefon/əlaqə üzrə biznes qaydaları (bax §7). Telefonlar **təsdiqlənmir**, ona görə qərarlı təcavüzkarı saxlamaz; real həll SMS OTP-dir (hələ edilməyib, qərar/xərc lazımdır).
- **Telefon nömrəsi yazılarkən normallaşdırılır** (`+994 50 123-45-67` → `+994501234567`; 7–15 rəqəm), ki, fərqli yazılış eyni nömrə sayılsın.
- **Axtarış Azərbaycan hərflərini nəzərə alır** (`SearchText.Fold`: ə→e, ı/İ→i, ö→o, ü→u, ç→c, ş→s, ğ→g). Diqqət: `ə` → **`e`**-dir, `a` yox (`Əhmədli` = `ehmedli`). Axtarış/sıralama/səhifələmə **serverin yaddaşında** edilir (bütün aktiv restoranlar yüklənir) ki, nəticə verilənlər bazasının collation-undan asılı olmasın.
- **`GET /api/restaurants` hələ də sadə massiv qaytarır** (zərf yox): `search`, `pageSize` (1–100), `page` ixtiyaridir, parametrsiz = hamısı. Səbəb: geriyə uyğunluq.
- **Admin panel enumları tam ədəd kimi** serializasiya olunur (JSON-da `0,1,2…`), `frontend/src/types/index.ts` backend enumları ilə **eyni** olmalıdır.
- **Mobil API ünvanı** `--dart-define=API_BASE_URL=...` ilə dəyişir (defolt `http://localhost:5080`) — real serverdə lazım olacaq.
- **Mobil web port 5174 sabitdir:** backend CORS yalnız `localhost:3000/5173/5174`-ə icazə verir (`appsettings.Development.json`).
- **FluentValidation mesajları həmişə ingilis dilində** (server OS dilindən asılı olmasın deyə; əvvəl rusca çıxırdı).
- **Üç dilli məzmun (Ru/En sütunları):** Azərbaycanca mətn əsas sütunlarda qalır (`Description`, `Question`, `Answer`), yanlarında `...Ru`/`...En` ixtiyari sütunlar var (Haqqımızda təsvir, FAQ sual/cavab, restoran təsviri). Seçim `Common/Localization.Pick`-dədir. Restoran adı/ünvanı, sorğu, əlaqə və sosial şəbəkə mətnləri tərcümə olunmur. Admin API `lang` qəbul etmir (həmişə xam 3 dil qaytarır), ictimai API qəbul edir. **Serverin doğrulama mesajları (`errors`/`title`) hələ də ingiliscədir** və mobilə olduğu kimi çatır.
- **Mobil tərcümələr** `mobile/lib/l10n/app_{en,az,ru}.arb` fayllarındadır (`flutter gen-l10n` ilə `app_localizations*.dart` yaranır, onlar da git-dədir). Yeni mətn əlavə edəndə **üç faylı da** doldurun; `test/localization_test.dart` açarların eyni olduğunu yoxlayır.

## 4. Texnologiyalar və fayl strukturu

```
HARA/
├─ HANDOFF.md                      ← bu fayl
├─ docker-compose.yml              Postgres 16 (db: hara, user/parol: postgres/postgres, port 5432, volume hara_hara-postgres-data)
├─ restart-dev-environment.bat     bir klikləyə: DB + backend + admin panel + mobil app (4 addım)
├─ backend/                        .NET 9 (Hara.sln)
│  └─ src/
│     ├─ core/Hara.Domain          entity-lər (Restaurant, Reservation, RestaurantSubmission, Advertisement, FaqItem, ContactInfo, SocialMediaLink, AboutUsContent)
│     ├─ core/Hara.Application     Commands/Queries/DTO/Validator, Common/{PhoneNumber,SearchText,Exceptions,Interfaces}
│     ├─ external/Hara.Persistence EF Core (Npgsql), Identity (admin istifadəçi, JWT), Configurations/, Migrations/, Repositories/
│     ├─ external/Hara.Infrastructure  LocalFileStorageService (şəkillər diskə yazılır)
│     └─ ui/Hara.Api               Program.cs, Endpoints/*.cs, Middleware/ExceptionHandlingMiddleware.cs, RateLimiting/, appsettings*.json
├─ frontend/                       Admin panel: React 18 + Vite 5 + TypeScript + Tailwind + TanStack Query v5 + react-hook-form + zod
│  └─ src/{features/*, components/ui, lib/{api.ts,auth-context.tsx,token.ts,coordinates.ts,enumLabels.ts}, types/index.ts}
└─ mobile/                         Flutter 3.47.4 / Dart 3.13 (Riverpod 2.6, go_router 14, dio 5)
   └─ lib/
      ├─ main.dart
      ├─ core/{constants/app_constants.dart, network/{api_client,api_error}.dart, router/app_router.dart, theme/, utils/open_link.dart, widgets/error_view.dart}
      └─ features/{restaurants, reservations, auth, venue, company_info, faq}/{data, presentation/{providers,screens,widgets}}
```

**Vacib fayllar:**
- `backend/src/ui/Hara.Api/Program.cs` — pipeline sırası (CORS → rate limiter → auth) və DI.
- `backend/src/ui/Hara.Api/appsettings.json` / `appsettings.Development.json` — bağlantı sətri, JWT, `RateLimiting`, `Cors`, dev admin (`AdminUser`).
- `backend/src/ui/Hara.Api/RateLimiting/RateLimitingExtensions.cs` — limit siyasətləri.
- `backend/src/core/Hara.Application/Reservations/Commands/CreateReservation/CreateReservationCommandHandler.cs` — rezervasiya qaydaları.
- `backend/src/core/Hara.Application/Restaurants/Queries/GetRestaurants/` — axtarış/sıralama/səhifələmə.
- `mobile/lib/core/router/app_router.dart` — bütün mobil route-lar.
- `mobile/lib/features/restaurants/presentation/providers/restaurants_provider.dart` — səhifələnən siyahı məntiqi (yarış vəziyyətindən qoruma, təkrarların atılması).
- `frontend/src/lib/api.ts` — HTTP klienti (`anonymous` bayrağı, şəbəkə xətası mesajı).

**API xülasəsi:**
- Public: `GET /api/restaurants[?sort=name_asc|name_desc|nearest&lat&lng&search&pageSize&page]`, `GET /api/restaurants/{id}`, `POST /api/reservations`, `GET /api/reservations/{code}/status` (yalnız status, bitmə vaxtı; telefon/restoran qaytarmır), `POST /api/reservations/{code}/cancel`, `POST /api/submissions`, `GET /api/faq`, `GET /api/company-info/{about|contacts|social-links}`, `GET /api/advertisements`, `GET /health`, `POST /api/auth/login`.
- Admin (JWT, rol `Admin`): `/api/admin/{restaurants|reservations|submissions|advertisements|faq|company-info/*|uploads/{category}}`.
- **Sahibkar/ofisiant (rol `Owner`/`Staff`, hesab restorana təsdiqlənibsə):** `POST /api/auth/register-owner`, `POST /api/auth/register-staff` (ictimai, 5/saat), `POST /api/auth/refresh`, `POST /api/auth/logout`; `GET /api/venue/me`, `GET /api/venue/reservations[?status]`, `GET /api/venue/reservations/{code}`, `POST /api/venue/reservations/{code}/accept|decline|redeem`, `POST /api/venue/devices` və `/devices/unregister` (push token); ictimai `POST /api/reservations/{code}/device`; yalnız `Owner`: `GET /api/venue/staff`, `POST /api/venue/staff/{id}/approve|reject`, `DELETE /api/venue/staff/{id}`, `GET|POST /api/venue/change-requests` (dəyişiklik sorğusu: ad, ünvan, telefon, 3 dildə təsvir, endirim; eyni anda ən çox 5 gözləyən). Admin: `POST /api/admin/restaurants` body-sində `fromSubmissionId` varsa sorğu təsdiqlənir və qeydiyyatdakı sahibkar həmin restoranın sahibi olur; `GET /api/admin/change-requests[?status]`, `PATCH /api/admin/change-requests/{id}/status` (`{decision: 1|2, adminNote}`; təsdiq dəyişiklikləri restorana tətbiq edir).
- Swagger Development-də açıqdır (`/swagger`).

**Mobil route-lar:** `/` siyahı, `/restaurants/:id`, `/about`, `/contact`, `/faq`, `/submit-restaurant`, `/reservation` (kod ekranı, `extra` ilə).
**Admin route-lar:** `/login`, `/` (dashboard), `restaurants`, `reservations`, `submissions`, `advertisements`, `faq`, `company-info/{about,contacts,social-links}`.

## 5. Necə işə salmaq

**Ön şərtlər:** Docker Desktop (açıq), .NET 9 SDK, Node.js, Flutter (bu maşında `C:\Users\Rashid\Desktop\flutter`, PATH-də **yoxdur**), `dotnet-ef` qlobal aləti (`dotnet tool install --global dotnet-ef --version 9.0.0`, PATH-ə `~/.dotnet/tools`).

**Bir klik:** `restart-dev-environment.bat` — DB (`docker compose up -d`), backend (5080), admin panel (5173), mobil app (5174) qaldırır, hər birinin portunu əvvəlcə boşaldır. Sonra:
- Mobil app: `http://localhost:5174` (ilk açılış 20–60 san, boş qara səhifə = gözləyin).
- Admin panel: `http://localhost:5173`. Login: `admin@hara.local`. **Gizli dəyərlər (2026-10-22) repoda deyil:** `Jwt:SigningKey` və `AdminUser:Password` `dotnet user-secrets`-dədir (`UserSecretsId` Hara.Api.csproj-da; baxmaq: `cd backend/src/ui/Hara.Api && dotnet user-secrets list`). Admin parolu `backend/secrets/admin-login.txt`-dədir (gitignore). **Əsas mənbə:** `backend/secrets/local-settings.json` (gitignore; appsettings ilə eyni forma: `{"Jwt":{"SigningKey":"..."},"AdminUser":{"Email":"admin@hara.local","Password":"..."}}`; Email Production-da məcburidir, çünki appsettings.json-da boşdur; admin hesabı indi hər mühitdə yaranır, Swagger yalnız Development-də), Program.cs onu yuxarı qovluqlarda axtarır, mühitdən asılı deyil (Production-da da işləyir). user-secrets də dəstəklənir. Yeni maşında bu faylı yaradın, yoxsa API açılmır. Admin hesabı yalnız YOXDURSA yaranır (seeder), parolu dəyişmək üçün DB-dən `admin@hara.local` sətrini silib API-ni yenidən başladın. Repo ictimaidir; köhnə dəyərlər git tarixçəsində qalıb, ona görə ləğv edilib (rotate).

**⚠ Təzə baza/maşında migration-lar AVTOMATİK tətbiq olunmur** (son migration: `AddTermsAcceptances`). Skript bunu etmir. Boş bazada əvvəl:
```bash
cd backend
dotnet ef database update --project src/external/Hara.Persistence --startup-project src/ui/Hara.Api --context ApplicationDbContext
```
Admin istifadəçi yalnız **Development-də** və yalnız **yoxdursa** backend start olanda yaradılır (parolu heç vaxt yeniləmir).

**Testlər:** `cd mobile && flutter analyze && flutter test` (295 test: giriş/token yenilənməsi, qarşılama/giriş/qeydiyyat axınları, sahibkar/ofisiant ekranları, hesabı silmə, məxfilik siyasəti və s.). **Backend-də və frontend-də avtomatik test yoxdur** (canlı curl/skriptlərlə və brauzerlə yoxlanıb). **Mobil ↔ backend uyğunluq testi** (`mobile/live_test/live_contract_test.dart`) `flutter test`-ə daxil deyil: boş atılacaq bazaya qarşı həqiqi backend-i (5081) tələb edir, bax "Canlı test" aşağıda.

**Lokal (git-də olmayan) fayl:** `.claude/launch.json` (Claude Code önizləmə konfiqurasiyası: `hara-admin-frontend`, `hara-mobile-web`, `hara-mobile-web-5081`). Yeni maşında yenidən yaradılmalıdır.

## 6. İşlər

### Bitmiş (hamısı `main`-də, push olunub)
| Commit | Nə |
|---|---|
| `3feb2a9` | Admin frontend GitHub-a əlavə olundu, dev alətləri |
| `39700e2` | `docker-compose.yml` (Postgres) |
| `a5f4b55`, `66f30f6` | Restoran koordinatları, sıralama (ad / ən yaxın) |
| `a8564e3` | İlk Flutter ekranı, web platforması |
| `c75aa35` | Android/iOS/Windows platform qovluqları (istifadəçi commit etdi, mesaj "test") |
| `951b23f` | Rezervasiya + müştəri kodu + restoran endirimi (backend, admin, mobil) |
| `40b028d` | Restoran detalı ekranı |
| `03d70e7` | "Restoranımı əlavə et" forması |
| `0a22acb` | Spam qoruması (sürət limiti + biznes qaydaları) |
| `5edc8b2` | Rezervasiyanı ləğv, admin login limiti, ingilis doğrulama mesajları, `API_BASE_URL` |
| `70917e8` | Admin login xəta mesajları düzəldildi |
| `c347a3e` | Təsdiqlənmiş sorğudan "Create restaurant" |
| `bd58077` | Koordinatları Google Maps-dən yapışdırma (DMS və onluq cüt) |
| `fa16fe1` | Haqqımızda / Əlaqə / FAQ ekranları |
| `052c0ba` | Siyahıda axtarış + səhifələmə |
| `afd54ae` | `restart-dev-environment.bat`-a mobil app addımı |
| `41b5d64` | Haqqımızda/FAQ/restoran təsviri üçün Ru/En tərcümə sütunları, `?lang=`, admin forma xanaları |

### Yarımçıq / tam yoxlanmamış
- **FAQ ekranı brauzerdə gözlə görülməyib** (Claude pəncərəsi gizli olduğu üçün); widget testləri və canlı backend ilə yoxlanıb. Haqqımızda və Əlaqə brauzerdə görülüb.
- **Android / iOS / Windows build-ləri yoxlanmayıb:** platform qovluqları var, amma bu maşında Android SDK və Visual Studio (C++) yoxdur; iOS üçün Mac lazımdır. Yalnız **Web** build olunub və işləyir.
- Sorğu ↔ restoran bağlantısı yoxdur (qərarla).
- Real data boşluqları: "Mixək Restoranı" koordinatı hələ `0,0` (endirimi 2026-10-08-də 5% edildi); Haqqımızda 3 dildə dolduruldu (Rusca/İngiliscə mətni Claude tərcüməsidir, bilən biri yoxlamalıdır); FAQ 8 sualla 3 dildə dolduruldu (Claude tərcüməsi, yoxlanmalıdır; №6 kodun ekrandan sonra görünməməsini açıq yazır); Contacts və Social Links hələ doldurulmayıb.

### Növbəti addımlar (istifadəçi hələ seçməyib — soruşun; təxmini prioritet)
1. Real məzmunu admin paneldə doldurmaq (qalan: Mixək koordinatı, Contacts, Social Links).
2. **SMS OTP** (rezervasiya telefonlarını təsdiqləmək) — provayder və xərc qərarı lazımdır.
3. **"Ən yaxın" sıralaması:** backend hazırdır (`?sort=nearest&lat&lng`), mobil app yer icazəsi istəmir.
4. **Real serverə çıxış:** API üçün Dockerfile, gizli açarlar (`Jwt:SigningKey` boşdur → boşdursa API açılmır), real CORS origin-ləri, HTTPS, reverse proxy üçün forwarded headers (IP üzrə limit buna bağlıdır), dev admin parolunun dəyişdirilməsi, bazanın ehtiyat nüsxəsi, **şəkillər üçün bulud saxlama** (indi lokal diskdə).
5. **Avtomatik testlər:** backend üçün xUnit layihəsi, frontend üçün `vitest` (təklif olunub, istənməyib).
6. ~~Lokalizasiya~~ — mobil UI 3 dildədir (2026-10-08). Qalan: Rusca/Azərbaycanca tərcümələrin bilən biri tərəfindən yoxlanması; admin panel UI-ı və server doğrulama mesajları hələ ingiliscədir.
7. **Sahibkar/ofisiant hesabları — Mərhələ 1–4 HAZIRDIR (2026-10-08), yalnız e-poçt (Mərhələ 5) qalıb.** Qərarlar: eyni mobil app; qeydiyyat ekranı iki hissəli "Sahibkar" / "Müştəri" (düymə mətni **"Müştəri kimi davam et"**, müştəri hesabsız qalır); sahibkar hesab + restoran məlumatını birlikdə göndərir, admin restoranı həmin qeydiyyatdan yaradanda ("Submissions" səhifəsində "Create restaurant") hesab sahibkar olur; ofisiantı restoran sahibi təsdiqləyir; sahibkar məlumatı birbaşa dəyişmir, admin-ə dəyişiklik sorğusu göndərir ("Change requests" səhifəsi: indiki dəyər ↔ istənilən dəyər, təsdiq/rədd). **Qalan işlər:** (a) **parol sıfırlama və e-poçtun təsdiqi** — sahibkarın öz Gmail-inə link; göndərən hesab (ayrıca Gmail + "tətbiq parolu", repoya yazılmamalıdır) lazımdır, hələ yoxdur; (b) sahibkar şəkil yükləyə bilmir (yükləmə endpoint-i yalnız admindir) — şəkil dəyişikliyi sorğuda yoxdur; (c) dəyişiklik sorğusunda boş xana = "dəyişmə" (isteğe bağlı mətni silmək üçün mobil formada yol yoxdur; API boş sətri qəbul edir); (d) admin panelində sahibkar/ofisiant siyahısı yoxdur; (e) backend-də köhnə anonim `POST /api/submissions` hələ də var (mobil artıq istifadə etmir) — silmək olar; (f) e-poçtlar təsdiqlənmir.
8. Sorğu ↔ restoran bağlantısı (`RestaurantId` + migration), admin siyahılarında səhifələmə/axtarış.
9. Android Studio / Visual Studio qurub Android/Windows build; Mac ilə iOS.
10. Biznes qərarları (bonus/loyallıq, abunə avtomatlaşdırması, reklam səviyyələri).

## 7. Bilinən problemlər və diqqət edilməli məqamlar

**Məlumat və fayllar**
- Baza məlumatı Docker volume-dadır (`hara_hara-postgres-data`), **git-də deyil**. Yüklənmiş şəkillər `backend/src/ui/Hara.Api/App_Data/uploads/`-dadır və **`.gitignore`-dadır** (git-də də, ehtiyatda da yoxdur). API yüklənmiş şəkilləri heç vaxt silmir (restoran silinəndə fayl qalır).
- İstifadəçinin öz test məlumatları var (məsələn restoran "Mixək Restoranı", sorğu "TEST Cafe 1" — təsdiqlənib, restoran yaradılmayıb, Mixək-də rezervasiya). **Aydın şəkildə sizin olmayan heç nəyi silməyin.** Test məlumatı yaradanda `ZZ` prefiksi işlədin və sonra silin.

**Qaydalar (indi işləyən davranış)**
- Rezervasiya: bir telefon eyni anda **1 gözləyən və ya aktiv** sorğu saxlaya bilər; 24 saatda ən çox **5** (ləğv olunanlar da sayılır); kod 6 simvoldur (0/O/1/I yoxdur); rezerv `ExpiresAt`-dan sonra redeem olunmur.
- Sürət limitləri (hər IP, `RateLimiting` bölməsi): rezervasiya 5/saat, sorğu 3/saat, ləğv 10/saat, status yoxlaması 300/saat, admin login 10/10 dəq. **Development-də 100-ə yüksəldilib** (əl ilə sınaq bloklanmasın).
- Sorğu: eyni əlaqədən eyni adlı gözləyən sorğu rədd edilir; bir əlaqədən ən çox 3 gözləyən sorğu.
- Giriş (access) tokeni 60 dəqiqə yaşayır; `refreshToken` (60 gün, hər istifadədə yenisi verilir, köhnəsi ölür) ilə yenilənir. **Artıq istifadə olunmuş refresh token təkrar gələrsə həmin hesabın bütün sessiyaları bağlanır** (mobil klient yeniləməni bir-bir, paralel yox etməlidir). Admin panel hələ refresh istifadə etmir, saatda bir yenidən login. Parol qaydası: 8+ simvol, kiçik hərf və rəqəm.
- **Aktiv rezerv cihazda saxlanılır** (`shared_preferences`, açar `active_reservations`): əsas ekranın yuxarısında "Rezerviniz" kartı çıxır, basanda kod ekranı açılır. Kod **yalnız həmin cihazda** var (hesab/SMS yoxdur): tətbiq məlumatı/brauzer yaddaşı silinəndə və ya başqa cihazda görünmür. Kart silinir: vaxt bitəndə, ləğv edəndə, və **server kodu "istifadə olundu"/"ləğv"/"tanınmır" bildirəndə** (`GET /status`; siyahı açılanda, tətbiq ön plana qayıdanda və açıq qaldıqca 60 san-də bir yoxlanılır; açıq kod ekranı da "artıq aktiv deyil" göstərir). Server əlçatmaz/xətalıdırsa kart saxlanılır. Ləğv zamanı yerli silmə UI-ı gözlətmir (`unawaited`).
- Backend səhv/etibarsız UTF-8 JSON gələndə 400 yox **500** qaytarır (köhnə davranış).

**İşlədərkən**
- **Canlı test (mobil ↔ backend):** `hara_test` boş bazası yaradın və migration edin (aşağıdakı `--connection` qaydası), API-ni ona qarşı 5081-də `ASPNETCORE_ENVIRONMENT=Development` ilə qaldırın, sonra `cd mobile && ADMIN_PW=<AdminUser parolu> flutter test live_test/live_contract_test.dart --dart-define=API_BASE_URL=http://localhost:5081`. Hər işə düşmədən əvvəl baza **boş** olmalıdır (test məlumat yaradır), sonda `DROP DATABASE hara_test WITH (FORCE)`. İstifadəçinin real bazasına (`hara`) və 5080/5173/5174 proseslərinə toxunmayın.
- **Windows konsolu ASCII-dən kənar simvolları komanda sətrində pozur** (curl-a `Ə`, `ı` kimi hərfləri arqument kimi vermək 500/`?` verir). Test məlumatını **UTF-8 JSON fayldan** göndərin (`curl --data-binary @fayl.json`).
- İstifadəçinin işlətdiyi backend (5080) **Debug DLL-lərini kilidləyir** — o işləyərkən `dotnet build` xəta verir. Test üçün `-c Release` ilə build edib 5081-də ayrıca nüsxə qaldırın (`dotnet bin/Release/net9.0/Hara.Api.dll --urls http://localhost:5081`, `src/ui/Hara.Api`-dən), `dotnet ef`-i də `--configuration Release` ilə işlədin. İstifadəçinin 5080/5173/5174 proseslərini öldürməyin (yalnız `restart-dev-environment.bat` bunu edir).
- **Canlı test üçün təcrid olunmuş baza:** konteynerdə `hara_test` yaradın, `dotnet ef database update --connection "...Database=hara_test..." --configuration Release ...` ilə migrate edin, API-ni `ConnectionStrings__DefaultConnection` ilə ona yönəldin, admin API ilə məlumat yazın, sonda `DROP DATABASE hara_test WITH (FORCE)`.
- Flutter web debug-da `main.dart.js` həmişə ~7 KB açılış faylıdır — "kompilyasiya bitdi" yoxlaması üçün ölçüsünə baxmayın, səhifəni yükləyin. Claude pəncərəsi gizli/minimize olanda brauzer paneli kadr çəkmir (kliklər qəbul olunur, amma ekran yenilənmir) — bu halda widget testləri və ya canlı backendə qarşı müvəqqəti widget testi (`HttpOverrides.global = null` + `tester.runAsync`, `--dart-define=API_BASE_URL=...`) işlədin, sonra silin.
- Flutter web canvas-dır: oxumaq üçün `document.querySelector('flt-semantics-placeholder').click()` ilə semantikanı açın, sonra `read_page`/`find` işləyir.
- Git `LF will be replaced by CRLF` xəbərdarlıqları zərərsizdir (Windows `autocrlf`).
- Axtarış və sıralama minlərlə restoranda bazaya köçürülməlidir (indi hamısı yaddaşa yüklənir).

## 8. İstifadəçi ilə iş qaydası

- İstifadəçi **texniki deyil** (kodlaşdırma, Flutter, GitHub, Docker bilmir), **Azərbaycan dilində** yazır — cavabları Azərbaycan dilində, sadə dildə verin, texniki terminləri izah edin.
- İş **addım-addım** gedir: bir şeyi hazırlayın, nəticəni qısa və dürüst təqdim edin (nə yoxlandı, nə yoxlanmadı), istifadəçi davam edib-etməyəcəyini deyir.
- **Commit/push yalnız istifadəçi istəyəndə** ("commit və push et", "CP et"). Əvvəl nəyin commit olunacağını göstərin. Commit mesajlarının sonuna Claude `Co-Authored-By` sətri əlavə olunur.
- Kod yazmazdan əvvəl biznes məntiqi/TBD varsa soruşun (§1); spesifikasiya mesajını avtomatik "başla" kimi qəbul etməyin.
- Dəyişikliyi **özünüz yoxlayın** (build, test, mümkünsə canlı) və yoxlanmayanı açıq yazın. Test üçün zəif/boş keçən testlərə qarşı mutasiya yoxlaması (qoruyucunu söndürüb testin uğursuz olduğunu görmək) faydalı oldu.
- İstifadəçi öz serverlərini özü işlədir (`restart-dev-environment.bat`); dəyişiklikdən sonra onlara yenidən başlatmaq lazım olduğunu deyin.

## 9. Biznes məntiqindəki boşluqlar (2026-10-13, MVP-dən SONRAYA saxlanılıb)

İstifadəçi MVP-ni yüngül saxlamaq istəyir: bunlardan heç birini özü seçməyincə **başlamayın**. Qayıdanda əvvəl yalnız seçilən bəndə dair qısa qərar sualı verin, kod yox. (Eyni siyahı Claude yaddaşında `project_hara_business_gaps.md`-dədir.)

**A. Gəlirə təhlükə**
1. ✅ QİSMƏN HƏLL OLUNUB (2026-10-29): admin panelində restoran üzrə sayğaclar və sahibkar/ofisiant üçün mobil statistika var (bax "Statistika"). Hesabat PDF/aylıq göndəriş və gəlir məbləği yoxdur.
2. Abunə modeli yoxdur: pulsuz dövr, haqq, dayandırma, ödəniş yolu (kart/köçürmə/e-qaimə); ödəməyən restoranı avtomatik gizlətmək olmur; premium/adi reklam səviyyələri yoxdur.
3. Reklam admin paneldə var, mobil tətbiqdə heç göstərilmir.
4. Kodu təsdiqləyəndə hesab məbləği qeyd olunmur (bonus "minimum hesab" qaydası və gələcək komissiya üçün lazımdır).

**B. "Rezerv" real olandan çox vəd edir**
5. Rezerv əslində endirim kuponudur: masa sayı, doluluq, nəfər sayı, gəliş vaxtı yoxdur. Ya "endirim kodu" deyin, ya real masa sistemi qurun (ən böyük məhsul qərarı).
6. ✅ HƏLL OLUNUB (2026-10-29): iş saatları var, owner tətbiqdə qoyur, bağlı restoranda rezerv olmur (bax "İş saatları").
7. Restoran rezervi ləğv edə bilmir, sahibkarın "bu gün doluyuq, rezervləri dayandır" açarı yoxdur; hər dəyişiklik admindən keçir (yavaş).
8. Gəlməyənə (no-show) nəticə yoxdur; telefon təsdiqlənmir (SMS təxirə salınıb): başqasının nömrəsini bloklamaq və ya spam mümkündür.
9. 30 dəq yol vaxtını nəzərə almır; 31-ci dəqiqədə çatan endirimi itirir.

**C. Restoran və hesab dövrü**
10. Admin tərəfindən yaradılmış restoranların (məs. Mixək) sahibi YOXDUR: sahibkar qeydiyyatı həmişə YENİ restoran yaradır. "Bu mənim restoranımdır" (claim) axını və ya admin dəvəti lazımdır.
11. Adminin sahibkarın həqiqətən restoranın sahibi olduğunu yoxlama qaydası təyin olunmayıb (zəng? VÖEN?); dublikat aşkarlanması (eyni ad+ünvan) yoxdur.
12. Bir hesab = bir restoran: filiallar/şəbəkə sığmır.
13. ✅ QİSMƏN HƏLL OLUNUB (2026-10-29): owner parolunu admin təsdiqi ilə bərpa edə bilir (bax "Parol bərpası"). Ofisiant üçün, email ilə bərpa və sahibkarı dəyişmək hələ yoxdur.
14. Endirim qaydaları yalnız bir faizdir: saat/gün məhdudiyyəti, gündə maksimum say, istisnalar (spirtli içki), digər kampaniya ilə birləşmə yoxdur.

**D. Müştəri tərəfi**
15. Heç bir bildiriş yoxdur: sahibkara ofisiant sorğusu, admin-ə yeni qeydiyyat/sorğu, müştəriyə "10 dəq qalıb" gəlmir; hamı tətbiqi özü açmalıdır.
16. ✅ QİSMƏN HƏLL OLUNUB (2026-10-29): "indi açıq", "ən yaxın" + məsafə, mətbəx növü, sevimlilər və şəkil qalereyası (infrastruktur, şəkillər hələ yoxdur) var (bax "Kəşf"). Qiymət səviyyəsi və reytinq/rəy yoxdur. Əvvəlki qeyd: yalnız A–Z; mətbəx növü, açıq/bağlı, məsafə (backend "ən yaxın"ı bilir, tətbiq yer icazəsi istəmir), şəkil qalereyası, qiymət səviyyəsi, reytinq/rəy, sevimlilər yoxdur.
17. Hesabsız müştəri = planlaşdırılmış bal/loyallıq mümkün deyil (kimlik, yəni telefon təsdiqi lazımdır).
18. Şikayət yolu yoxdur ("restoran endirim vermədi"), yalnız əlaqə e-poçtu.

**E. Hüquqi və mağaza tələbləri**
19. Restoran müştərinin telefonunu görür: **məxfilik siyasəti mobildə var (2026-10-13, `/privacy`, 3 dildə, proqramın indiki davranışını təsvir edir — HÜQUQİ YOXLAMADAN KEÇMƏYİB)**. Qalan: saxlama müddəti qərarı (indi nömrələr əbədi saxlanılır, siyasət "lazım olduğu müddət" deyir), razılıq mətni, şəxsi məlumat qanununa uyğunluq, müştərinin nömrəsini silmə yolu (hələlik yalnız əlaqə e-poçtu ilə).
20. ~~Apple/Google hesabı silmə~~ — **HAZIRDIR (2026-10-13):** sahibkar/ofisiant tətbiqdə "Hesabımı sil" (parol təsdiqi ilə, `POST /api/auth/delete-account`). Ofisiant tam silinir; sahibkarın ad/e-poçt/telefonu silinir, restoran qalır (sahibsiz qalır, bax №10). Admin hesabları silinmir. **Qalan:** mağazalar ictimai **URL** tələb edir (siyasət hələ yalnız tətbiqin içindədir, eyni mətni vebdə yerləşdirmək lazımdır).
21. ✅ QARALAMA HAZIRDIR (2026-10-29): istifadə şərtləri və restoran razılaşması mətnləri (3 dil) və qəbul mexanizmi var (bax "İstifadə şərtləri və restoran razılaşması"). **Hüquqşünas baxışı hələ lazımdır**; ödəniş şərtləri yoxdur (xidmət pulsuzdur).

**F. İdarəetmə**
22. Bir ümumi admin girişi var: kimin nəyi təsdiqlədiyi görünmür (audit yoxdur).

**Qayıdanda təklif olunan sıra:** əvvəl (kodsuz) qərar: rezerv masa tutur, yoxsa endirim kodudur? (№5, 6, 9). Sonra ilk real restoranlar üçün №10, №7, №1, №15. Pul üçün №2, №4. Mağazaya çıxmazdan əvvəl məcburi: №19, 20, 21.
