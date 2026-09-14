# راهنمای فارسی سناریوی Networks در Docker Compose

این Repository یک سناریوی عملی برای یادگیری شبکه‌بندی در Docker Compose است و روی `DEV-1` اجرا می‌شود. آدرس `192.0.2.10` در این مستند فقط نمونه است و باید با IP واقعی ماشین آزمایشگاهی جایگزین شود.

## هدف سناریو

در این پروژه سه سرویس داریم:

- سرویس `frontend` یک Nginx است و تنها سرویس قابل‌دسترسی از بیرون Docker است.
- سرویس `api` عضو هر دو شبکه است و ارتباط کنترل‌شده بین Frontend و Redis را برقرار می‌کند.
- سرویس `redis` فقط داخل شبکه داخلی Backend قرار دارد و روی Ubuntu پورت منتشرشده ندارد.

## معماری

```mermaid
flowchart LR
    Client["مرورگر کاربر"] -->|"192.0.2.10:8086"| Frontend["Frontend / Nginx :80"]
    Frontend -->|"frontend_net"| API["Python API :5000"]
    API -->|"backend_net"| Redis["Redis :6379"]
```

شبکه `frontend_net` میان Frontend و API مشترک است. شبکه `backend_net` میان API و Redis مشترک است. Frontend و Redis هیچ شبکه مشترکی ندارند.

## اجرای پروژه

فایل متغیرهای محلی را بساز:

```bash
cp .env.example .env
```

Syntax و متغیرهای Compose را بررسی کن:

```bash
docker compose --env-file .env config --quiet
```

سرویس‌ها را Build و اجرا کن:

```bash
docker compose up -d --build
```

وضعیت سرویس‌ها را ببین:

```bash
docker compose ps
```

## تست مسیر کامل

```bash
curl http://127.0.0.1:8086/api/info
```

اگر ارتباط کامل باشد، مقدار `redis_response` برابر `PONG` خواهد بود.

## تست DNS داخلی Docker

Frontend باید API را Resolve کند:

```bash
docker compose exec frontend nslookup api
```

API باید Redis را Resolve کند:

```bash
docker compose exec api python -c "import socket; print(socket.gethostbyname('redis'))"
```

Frontend نباید Redis را Resolve کند:

```bash
docker compose exec frontend nslookup redis
```

شکست دستور آخر نتیجه صحیح آزمایش Network Isolation است.

## نکات مهم

- برای ارتباط Containerها از نام سرویس استفاده می‌کنیم، نه IP ثابت.
- آدرس `localhost` داخل هر Container به همان Container اشاره می‌کند.
- گزینه `expose` پورت را روی Ubuntu منتشر نمی‌کند و فایروال محسوب نمی‌شود.
- شبکه Bridge فقط داخل یک Docker Host کار می‌کند و به `DEV-2` گسترش پیدا نمی‌کند.
- گزینه `internal: true` شبکه Backend را از دسترسی خارجی مستقیم جدا می‌کند.

## پاک‌سازی

حذف Containerها و Networkها با حفظ Volume:

```bash
docker compose down
```

حذف Containerها، Networkها و Volume:

```bash
docker compose down -v
```

هشدار: گزینه `-v` داده‌های Volume را حذف می‌کند.
