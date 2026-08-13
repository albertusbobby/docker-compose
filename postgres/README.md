# PostgreSQL

Docker compose untuk PostgreSQL 17 buat kebutuhan development lokal.

## Isi `docker-compose.yml`

| Bagian | Penjelasan |
| :--- | :--- |
| `image: postgres:17` | Image resmi PostgreSQL versi 17 |
| `environment` | `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` — ambil dari `.env`, kalau tidak ada fallback ke `postgres`/`postgres`/`app_db` |
| `ports: 5432` | Port default Postgres, bisa dioverride lewat `POSTGRES_PORT` |
| `volumes: postgres_data` | Named volume, biar data survive walau container dihapus (`docker compose down` tanpa `-v`) |
| `healthcheck` | Cek kesiapan pakai `pg_isready`, tiap 10s, max 5x retry — berguna kalau ada service lain yang `depends_on: condition: service_healthy` |
| `networks: dev-network` | Network bersama, biar bisa diakses container lain (misal CloudBeaver) pakai hostname `postgres` |

## File Pendukung

- **`.env.example`** — template environment variable. Copy jadi `.env` untuk override kredensial default:
  ```bash
  cp .env.example .env
  ```
  Isinya: `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `POSTGRES_PORT`.

## Cara Pakai

```bash
docker compose up -d
```

Koneksi dari host:
```bash
psql -h localhost -p 5432 -U postgres -d postgres
```

Koneksi dari container lain (satu network `dev-network`):
```
host: postgres
port: 5432
```
