# HARA — Handoff (yeni söhbət üçün)

Bu fayl yeni söhbətin (insan və ya Claude) layihə haqqında heç nə bilmədən işə başlaması üçündür.
Vəziyyət **2026-10-08**-ə görədir. Hər şeydən əvvəl `git log --oneline -10` və `git status` ilə faylın hələ də aktual olduğunu yoxlayın.

---

## 1. Layihənin məqsədi

**HARA** ("hara" = "where", şüar: *"Hara? deyə düşünmə"*) — məkan kəşfi + masa rezervasiyası tətbiqidir. Məqsəd: insanlar həmişə eyni tanış yerlərə getməsin, yeni məkanları kəşf etsin.

**Müştəri tərəfi (pulsuz):**
- Müştəri məkanı seçir, **telefon nömrəsi** ilə masanı **30 və ya 60 dəqiqəlik** rezerv edir (ödəniş yoxdur, hesab yoxdur).
- Rezervdən sonra qısa **kod** alır, bu müddət ərzində məkana çatıb kodu göstərir və məkanın təyin etdiyi **faiz endirimi** istəyir.
- Gələcəkdə (v1 deyil): bal/loyallıq sistemi.

**Məkan (restoran) tərəfi (gəlir mənbəyi):**
- Yeni məkana abunə haqqından azad ilkin dövr + 1 ay pulsuz premium reklam; sonra aylıq platforma haqqı; "premium" və "adi" reklam səviyyələri.
- Məkanlar tətbiqə **sorğu → admin təsdiqi** ilə daxil olur (öz-özünə qeydiyyat yoxdur, aşağıya bax).

**İstifadəçinin özü tərəfindən qeyd olunmuş, HƏLƏ AÇIQ qalan biznes suallar (dəyər uydurmayın, soruşun):**
1. Yeni məkanlar üçün pulsuz dövrün müddəti.
2. Aylıq abunə haqqı (AZN).
3. Məkanın müştəri kodunu öz tərəfində qeydiyyatdan keçirmə/istifadə mexanizmi (indiki müvəqqəti həll: admin paneldə "Reservations" səhifəsi).
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

**Mobil app-də olanlar:** restoran siyahısı (axtarış, A-Z/Z-A sıralama, 20-lik səhifələr), restoran detalı, rezervasiya (telefon + 30/60 dəq → kod ekranı, geri sayım, ləğv), "restoranımı əlavə et" forması, Haqqımızda / Əlaqə / FAQ.

**Dillər (2026-10-08):** tətbiq **Azərbaycanca (əsas), Rusca, İngiliscə** dəstəkləyir. İlk açılışda telefonun dili (az/ru/en), uyğun deyilsə Azərbaycanca; AppBar-dakı dil düyməsi ilə dəyişir və yadda qalır (`shared_preferences`). Mobil hər sorğuya `?lang=` əlavə edir; server Haqqımızda, FAQ və restoran təsvirini həmin dildə qaytarır, tərcümə boşdursa Azərbaycancaya düşür.

## 3. Əsas qərarlar və səbəbləri

- **Flutter** seçildi (React Native/native yox): `mobile/`-də artıq router, API klienti, tema var idi; Android + iOS üçün tək kod bazası. iOS build üçün **Mac** (və ya bulud Mac CI) lazımdır, Windows-da mümkün deyil.
- **Clean Architecture backend** (`Domain` / `Application` / `Infrastructure` / `Persistence` / `Api`), CQRS (MediatR), doğrulama (FluentValidation). Yeni əməliyyat = `Commands|Queries/<Ad>/` qovluğunda Command/Query + Handler + Validator.
- **Məkan sorğusu təsdiqi restoranı avtomatik yaratmır** (`SubmissionStatus.Approved` yalnız statusdur). Səbəb: sorğuda koordinat, şəkil, endirim yoxdur; avtomatik yaratmaq yarımçıq restoranı müştərilərə göstərərdi. Əvəzinə təsdiqlənmiş sorğuda **"Create restaurant"** düyməsi formanı əvvəlcədən doldurur. İstifadəçi **sadə variantı** seçdi: sorğu ilə yaranan restoran arasında **bağlantı yoxdur** (eyni sorğudan iki dəfə restoran yaratmaq olar).
- **Rezervasiya "Expired" statusu bazada saxlanmır**, `ExpiresAt`-dan hesablanır (`Reservation.EffectiveStatus`). Bazada yalnız `Active/Redeemed/Cancelled`.
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
      └─ features/{restaurants, reservations, submissions, company_info, faq}/{data, presentation/{providers,screens,widgets}}
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
- Public: `GET /api/restaurants[?sort=name_asc|name_desc|nearest&lat&lng&search&pageSize&page]`, `GET /api/restaurants/{id}`, `POST /api/reservations`, `POST /api/reservations/{code}/cancel`, `POST /api/submissions`, `GET /api/faq`, `GET /api/company-info/{about|contacts|social-links}`, `GET /api/advertisements`, `GET /health`, `POST /api/auth/login`.
- Admin (JWT, rol `Admin`): `/api/admin/{restaurants|reservations|submissions|advertisements|faq|company-info/*|uploads/{category}}`.
- Swagger Development-də açıqdır (`/swagger`).

**Mobil route-lar:** `/` siyahı, `/restaurants/:id`, `/about`, `/contact`, `/faq`, `/submit-restaurant`, `/reservation` (kod ekranı, `extra` ilə).
**Admin route-lar:** `/login`, `/` (dashboard), `restaurants`, `reservations`, `submissions`, `advertisements`, `faq`, `company-info/{about,contacts,social-links}`.

## 5. Necə işə salmaq

**Ön şərtlər:** Docker Desktop (açıq), .NET 9 SDK, Node.js, Flutter (bu maşında `C:\Users\Rashid\Desktop\flutter`, PATH-də **yoxdur**), `dotnet-ef` qlobal aləti (`dotnet tool install --global dotnet-ef --version 9.0.0`, PATH-ə `~/.dotnet/tools`).

**Bir klik:** `restart-dev-environment.bat` — DB (`docker compose up -d`), backend (5080), admin panel (5173), mobil app (5174) qaldırır, hər birinin portunu əvvəlcə boşaldır. Sonra:
- Mobil app: `http://localhost:5174` (ilk açılış 20–60 san, boş qara səhifə = gözləyin).
- Admin panel: `http://localhost:5173`. Login: `admin@hara.local`, parol `backend/src/ui/Hara.Api/appsettings.Development.json`-da (`AdminUser`). **Repo ictimaidir — real serverə çıxmazdan əvvəl mütləq dəyişin.**

**⚠ Təzə baza/maşında migration-lar AVTOMATİK tətbiq olunmur** (son migration: `AddRuEnTranslations`). Skript bunu etmir. Boş bazada əvvəl:
```bash
cd backend
dotnet ef database update --project src/external/Hara.Persistence --startup-project src/ui/Hara.Api --context ApplicationDbContext
```
Admin istifadəçi yalnız **Development-də** və yalnız **yoxdursa** backend start olanda yaradılır (parolu heç vaxt yeniləmir).

**Testlər:** `cd mobile && flutter analyze && flutter test` (66 test, 8 fayl). **Backend-də və frontend-də avtomatik test yoxdur** (canlı curl və brauzerlə yoxlanıb).

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
7. Məkan sahibləri üçün hesab sistemi (kodu özləri təsdiqləsin) — MVP-dən sonra.
8. Sorğu ↔ restoran bağlantısı (`RestaurantId` + migration), admin siyahılarında səhifələmə/axtarış.
9. Android Studio / Visual Studio qurub Android/Windows build; Mac ilə iOS.
10. Biznes qərarları (bonus/loyallıq, abunə avtomatlaşdırması, reklam səviyyələri).

## 7. Bilinən problemlər və diqqət edilməli məqamlar

**Məlumat və fayllar**
- Baza məlumatı Docker volume-dadır (`hara_hara-postgres-data`), **git-də deyil**. Yüklənmiş şəkillər `backend/src/ui/Hara.Api/App_Data/uploads/`-dadır və **`.gitignore`-dadır** (git-də də, ehtiyatda da yoxdur). API yüklənmiş şəkilləri heç vaxt silmir (restoran silinəndə fayl qalır).
- İstifadəçinin öz test məlumatları var (məsələn restoran "Mixək Restoranı", sorğu "TEST Cafe 1" — təsdiqlənib, restoran yaradılmayıb, Mixək-də rezervasiya). **Aydın şəkildə sizin olmayan heç nəyi silməyin.** Test məlumatı yaradanda `ZZ` prefiksi işlədin və sonra silin.

**Qaydalar (indi işləyən davranış)**
- Rezervasiya: bir telefon eyni anda **1 aktiv** rezerv saxlaya bilər; 24 saatda ən çox **5** (ləğv olunanlar da sayılır); kod 6 simvoldur (0/O/1/I yoxdur); rezerv `ExpiresAt`-dan sonra redeem olunmur.
- Sürət limitləri (hər IP, `RateLimiting` bölməsi): rezervasiya 5/saat, sorğu 3/saat, ləğv 10/saat, admin login 10/10 dəq. **Development-də 100-ə yüksəldilib** (əl ilə sınaq bloklanmasın).
- Sorğu: eyni əlaqədən eyni adlı gözləyən sorğu rədd edilir; bir əlaqədən ən çox 3 gözləyən sorğu.
- Admin JWT 60 dəqiqə yaşayır, yenilənmə (refresh) yoxdur — saatda bir yenidən login.
- Müştərinin rezervasiya kodu yalnız kod ekranındadır; ekrandan çıxanda itir (hesab/SMS yoxdur, kodla axtarış yoxdur).
- Backend səhv/etibarsız UTF-8 JSON gələndə 400 yox **500** qaytarır (köhnə davranış).

**İşlədərkən**
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
