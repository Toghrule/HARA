# HARA serverdə (24/7 işləyən sistem)

Məqsəd: server, baza və admin panel kompüterdən asılı olmasın. Hər şey bir kirayə serverdə (VPS) Docker ilə işləyir.
`api.hara.rest` (telefonlar) və `admin.hara.rest` (admin panel) Cloudflare tuneli ilə həmin serverə çatır, serverdə açıq port yoxdur.

Bu qovluqdakı hər şey sınaqdan keçirilib (kompüterdə ayrı Docker mühitində: baza avtomatik qurulur, admin giriş, CORS, müştəri başına sorğu limiti, məlumatın və şəkillərin köçürülməsi).

## 1. Server (bir dəfə)
Tövsiyə: **Hetzner Cloud**, plan **CX22** (2 CPU, 4 GB, təxminən 4-5 avro/ay), sistem **Ubuntu 24.04**, yer: Helsinki və ya Falkenstein.
Hesab açmaq, ödəniş və serveri yaratmaq səndədir. Yaradanda SSH açarı əlavə et (və ya Hetzner e-poçtla göndərən root parolu ilə gir).

## 2. Serverdə qurulum (SSH ilə və ya Hetzner veb konsolunda)
```bash
apt-get update && apt-get install -y docker.io docker-compose-v2 git ufw
ufw allow OpenSSH && ufw --force enable
git clone https://github.com/Toghrule/HARA.git
cd HARA/deploy
```

## 3. Sirlər (serverdə əl ilə, GitHub-a düşmür)
```bash
cp .env.example .env
nano .env                       # POSTGRES_PASSWORD: uzun təsadüfi parol yaz
mkdir -p secrets cloudflared
cp secrets.example/local-settings.json secrets/local-settings.json
nano secrets/local-settings.json
```
`local-settings.json` içində dəyiş:
- `Jwt.SigningKey`: yeni uzun açar (`openssl rand -hex 48` ilə düzəlt). **Kompüterdəkindən fərqli olsun.**
- `AdminUser.Password`: admin parolu (indikini saxlaya bilərsən).
- `Email.Password`: Resend açarı.

Kompüterdən serverə iki fayl köçür (PowerShell-də, `SERVER-IP`-ni yaz):
```bash
scp C:\Users\Rashid\Desktop\HARA\backend\secrets\firebase-adminsdk.json root@SERVER-IP:~/HARA/deploy/secrets/
scp C:\Users\Rashid\.cloudflared\TUNEL-ID.json root@SERVER-IP:~/HARA/deploy/cloudflared/credentials.json
```
(`TUNEL-ID.json` = `.cloudflared` qovluğundakı uzun adlı `.json` fayl.) Serverdə tunel ayarını yarat:
```bash
cp cloudflared/config.yml.example cloudflared/config.yml
nano cloudflared/config.yml     # TUNNEL-ID yerinə həmin uzun ad (.json olmadan)
```

## 4. Birinci başlatma (verilənlər boş)
```bash
docker compose up -d --build    # baza + API + admin panel (tunelsiz, hələ heç kim çatmır)
docker compose ps
```

## 5. KEÇİD (qısa fasilə: bir neçə dəqiqə)
Eyni ünvana iki yerdən cavab gəlməsin deyə əvvəl kompüterdəki pilotu dayandırırıq.
1. Kompüterdə `start-pilot.bat` pəncərələrini (API, admin, tunel) bağla.
2. Kompüterdə (Git Bash, `deploy` qovluğunda): `bash export-from-pc.sh` → `deploy/backups/hara-data.tar.gz` yaranır.
3. Onu serverə köçür: `scp deploy\backups\hara-data.tar.gz root@SERVER-IP:~/`
4. Serverdə: `cd ~/HARA/deploy && bash restore-on-server.sh ~/hara-data.tar.gz`
5. Admin panelin ünvanı üçün bir dəfə, kompüterdə: `cloudflared tunnel route dns hara-pilot admin.hara.rest`
6. Serverdə tuneli qaldır: `docker compose --profile tunnel up -d`
7. Yoxla: `https://api.hara.rest/health` və `https://admin.hara.rest` (admin girişi ilə).

## 6. Hər gün
- **Yeni versiya:** kodu GitHub-a göndərəndən sonra serverdə `cd ~/HARA/deploy && bash update.sh`.
- **Gecə nüsxəsi:** serverdə `crontab -e` və bu sətri əlavə et: `0 3 * * * cd /root/HARA/deploy && bash backup.sh >> backups/backup.log 2>&1`. Son 14 nüsxə `deploy/backups` qovluğunda qalır. Vaxtaşırı onu başqa yerə (öz kompüterinə) köçür: `scp root@SERVER-IP:~/HARA/deploy/backups/hara-*.sql.gz .`
- **Baxmaq:** `docker compose logs -f api`
- **Yenidən başlatma sonrası:** hər şey özü qalxır (`restart: unless-stopped`).

## Qeydlər
- Serverə keçəndən sonra baza bir ədəddir: serverdəki. Kompüterdəki `hara_pilot` artıq köhnədir. Admin panel `https://admin.hara.rest` olur (`localhost:5173/5175` əvəzinə).
- Gündəlik inkişaf üçün kompüterdəki sistem ayrı qalır; test üçün ayrıca baza işlət, real məlumatla qarışdırma.
- Real email serverdən Resend ilə gedir (açar `secrets/local-settings.json`-da).
