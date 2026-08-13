# Docker Compose Dev Stack

Kumpulan docker compose buat kebutuhan development lokal. Tiap service punya folder sendiri, dan semuanya nyambung ke satu network bersama: `dev-network`.

## Services

| Folder | Service | Port |
| :--- | :--- | :--- |
| `postgres/` | PostgreSQL | `5432` |
| `redis/` | Redis | `6379` |
| `redis-insight/` | Redis Insight (GUI) | `5540` |
| `cloudbeaver/` | CloudBeaver (DB GUI) | `8978` |
| `kafka/` | Kafka + Kafka UI | `29092`/`29093` (Kafka), `8999` (UI) |
| `monitoring/` | Prometheus + Grafana + Zipkin | `9090` (Prometheus), `3000` (Grafana), `9411` (Zipkin) |

## Prasyarat: bikin network dulu

Semua service butuh network `dev-network` (external). Bikin sekali aja di awal:

```bash
docker network create dev-network
```

Cek network sudah ada atau belum:

```bash
docker network ls | grep dev-network
```

## Menjalankan Service

Masuk ke folder service-nya, lalu:

```bash
docker compose up -d
```

Jalankan semua service sekaligus:

```bash
for d in postgres redis redis-insight cloudbeaver kafka monitoring; do
  (cd "$d" && docker compose up -d)
done
```

## Command Cheatsheet (dijalankan dari dalam folder service)

| Command | Kegunaan |
| :--- | :--- |
| `docker compose up -d` | Start service (background) |
| `docker compose down` | Stop & hapus container (volume tetap ada) |
| `docker compose down -v` | Stop & hapus container **+ volume** (data ikut hilang) |
| `docker compose restart` | Restart service |
| `docker compose up -d --force-recreate` | Recreate container (misal abis ubah `networks`/env) |
| `docker compose logs -f` | Lihat log realtime |
| `docker compose logs -f <service>` | Lihat log service tertentu (misal `kafka-ui`) |
| `docker compose ps` | Cek status container |
| `docker compose pull` | Update image ke versi terbaru |
| `docker compose exec <service> sh` | Masuk shell container |

Contoh spesifik yang sering dipakai:

```bash
# masuk psql
cd postgres && docker compose exec postgres psql -U postgres -d postgres

# masuk redis-cli (pakai password bobby123)
cd redis && docker compose exec redis redis-cli -a bobby123

# lihat log kafka broker
cd kafka && docker compose logs -f kafka
```

## Reset Total (hati-hati, data ilang)

```bash
cd <folder-service>
docker compose down -v
```

## Akses Cepat

| Service | URL / Connection |
| :--- | :--- |
| Postgres | `localhost:5432` (user/pass: lihat `.env` atau default `postgres`/`postgres`) |
| Redis | `localhost:6379` (pass: `bobby123`) |
| Redis Insight | http://localhost:5540 |
| CloudBeaver | http://localhost:8978 |
| Kafka (PLAINTEXT) | `localhost:29092` |
| Kafka (SASL SCRAM-SHA-256) | `localhost:29093` (user: `user`, pass: `password`) |
| Kafka UI | http://localhost:8999 |
| Prometheus | http://localhost:9090 |
| Grafana | http://localhost:3000 (login: lihat `.env` atau default `admin`/`admin`) |
| Zipkin | http://localhost:9411 |

Detail lebih lengkap per service ada di README masing-masing folder (kalau tersedia), misalnya `kafka/README.md`.

## Catatan

- Semua service default pakai network **`dev-network`** kecuali disebutkan lain — jadi antar container bisa saling akses pakai container name (`postgres`, `redis`, `kafka`, dst).
- Kalau baru pertama kali clone repo ini, urutannya: `docker network create dev-network` → masuk tiap folder → `docker compose up -d`.
