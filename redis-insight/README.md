# Redis Insight

GUI resmi dari Redis buat browse & manage data Redis (redis-cli tapi versi visual).

## Isi `docker-compose.yml`

| Bagian | Penjelasan |
| :--- | :--- |
| `image: redis/redisinsight:latest` | Image resmi Redis Insight |
| `ports: 5540` | Port akses web UI |
| `volumes: redis_insight_data` | Named volume, nyimpen konfigurasi & koneksi yang udah disave di UI |
| `extra_hosts: host.docker.internal:host-gateway` | Biar container bisa konek ke service yang jalan langsung di host (bukan di docker), pakai hostname `host.docker.internal` |

Catatan: service ini **tidak** ikut `dev-network` — dan itu memang gak masalah, karena redis-insight cuma dipakai buat connect ke Redis (satu arah), bukan buat resource yang perlu diakses balik oleh container lain. Berkat `extra_hosts`, dia tetap bisa jangkau Redis yang jalan di compose lain lewat `host.docker.internal:6379` (soalnya port Redis sudah di-expose ke host).

## Cara Pakai

```bash
docker compose up -d
```

Buka di browser: http://localhost:5540

Waktu nambah koneksi baru di UI, isi host Redis dengan **`host.docker.internal`** (port `6379`) — bukan `redis`, karena hostname container cuma resolve kalau satu network, dan redis-insight sengaja gak ikut `dev-network`.
