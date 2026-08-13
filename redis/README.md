# Redis

Docker compose untuk Redis 8.8.0 dengan persistence (AOF) aktif.

## Isi `docker-compose.yml`

| Bagian | Penjelasan |
| :--- | :--- |
| `image: redis:8.8.0` | Image resmi Redis |
| `ports: 6379` | Port default Redis |
| `volumes: redis_data` | Named volume buat persist data (folder `/data` di container) |
| `command: redis-server --appendonly yes --requirepass bobby123` | Aktifin **AOF** (append-only file) biar data survive restart, dan set password auth `bobby123` |
| `networks: dev-network` | Biar bisa diakses container lain pakai hostname `redis` |

Tidak ada file konfigurasi terpisah — semua setting langsung lewat `command:` di compose.

## Cara Pakai

```bash
docker compose up -d
```

Konek pakai `redis-cli` dari host:
```bash
redis-cli -h localhost -p 6379 -a bobby123
```

Konek dari dalam container:
```bash
docker compose exec redis redis-cli -a bobby123
```

Koneksi dari container lain (satu network `dev-network`):
```
host: redis
port: 6379
password: bobby123
```
