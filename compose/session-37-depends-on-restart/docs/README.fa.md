# راهنمای فارسی جلسه ۳۷ — depends_on و Restart Policy

این سناریو روی `DEV-2` اجرا و از `DEV-1` آزمایش می‌شود. آدرس‌های `192.0.2.10` و `192.0.2.11` در این مستند نمونه هستند و باید با IPهای واقعی Lab جایگزین شوند.

## هدف سناریو

- ابتدا PostgreSQL اجرا شود.
- Adminer تا Healthy شدن واقعی PostgreSQL منتظر بماند.
- هر دو سرویس پس از Crash به‌صورت خودکار اجرا شوند.
- Restart صریح دیتابیس توسط Compose باعث Restart شدن Adminer شود.
- Crash دیتابیس توسط Docker Runtime باعث Restart شدن Adminer نشود.

## تفاوت دو Restart

گزینه `restart: unless-stopped` در سطح سرویس، سیاست Docker Engine است. این سیاست بعد از Crash یا Restart میزبان، کانتینر را دوباره اجرا می‌کند؛ مگر اینکه مدیر آن را عمداً Stop کرده باشد.

گزینه `depends_on.db.restart: true` توسط Docker Compose مدیریت می‌شود. این گزینه فقط زمانی سرویس وابسته را Restart می‌کند که Dependency با یک عملیات صریح Compose مانند `docker compose restart db` راه‌اندازی مجدد شود.

## ترتیب راه‌اندازی

شکل کوتاه `depends_on` فقط اجراشدن Dependency را بررسی می‌کند. در این سناریو از شکل بلند و شرط `service_healthy` استفاده شده است؛ بنابراین Adminer بعد از موفق‌شدن Healthcheck دیتابیس شروع می‌شود.

Healthcheck با `pg_isready` بررسی می‌کند که PostgreSQL واقعاً آماده دریافت Connection باشد.

## اجرای سناریو روی DEV-2

```bash
cp .env.example .env
chmod 600 .env
docker compose config --quiet
docker compose pull
docker compose up -d
docker compose ps
```

بعد از اجرا، وضعیت `db` باید `healthy` باشد.

## بررسی خودکار

```bash
./scripts/verify.sh
```

## آزمایش رفتار Restart

```bash
./scripts/test-restart-behavior.sh
```

## ورود به Adminer از DEV-1

آدرس زیر را در Browser باز کنید:

```text
http://192.0.2.11:8086
```

برای Server از نام سرویس `db` استفاده کنید. آدرس `localhost` داخل کانتینر Adminer به خود Adminer اشاره می‌کند و آدرس دیتابیس نیست.

## نکات مهم

- وضعیت `running` به‌معنای آماده‌بودن Application نیست.
- وضعیت `unhealthy` به‌تنهایی کانتینر را Restart نمی‌کند.
- `depends_on` جایگزین Retry Logic داخل Application نیست.
- پورت دیتابیس عمداً روی Ubuntu منتشر نشده است.
- تغییر متغیرهای اولیه PostgreSQL روی Volume قدیمی، کاربر و Password موجود را تغییر نمی‌دهد.
