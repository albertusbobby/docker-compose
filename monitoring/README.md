# Monitoring (Prometheus + Grafana)

Stack monitoring dasar: Prometheus buat scrape & simpan metrics, Grafana buat visualisasi.

## Isi `docker-compose.yml`

| Service | Bagian | Penjelasan |
| :--- | :--- | :--- |
| **prometheus** | `image: prom/prometheus` | Image resmi Prometheus |
| | `ports: 9090` | Port akses web UI Prometheus |
| | `volumes: ./prometheus.yml:/etc/prometheus/prometheus.yml` | Mount config scrape target dari file lokal |
| | `volumes: prometheus_data` | Named volume, nyimpen time-series data metrics |
| | `command: --config.file / --storage.tsdb.path` | Nunjuk lokasi config & lokasi penyimpanan data di dalam container |
| | `extra_hosts: host.docker.internal` | Biar bisa scrape service yang jalan langsung di host, bukan cuma di docker |
| **grafana** | `image: grafana/grafana` | Image resmi Grafana |
| | `ports: 3000` | Port akses web UI Grafana |
| | `environment: GF_SECURITY_ADMIN_USER/PASSWORD` | Kredensial admin, ambil dari `.env`, fallback `admin`/`admin` |
| | `volumes: grafana_data` | Named volume, nyimpen dashboard, user, konfigurasi Grafana |
| | `volumes: ./grafana/provisioning` | Mount provisioning (auto-setup datasource tanpa config manual di UI) |
| | `depends_on: prometheus` | Grafana nunggu Prometheus jalan dulu sebelum start |

Keduanya satu network `dev-network`, jadi Grafana bisa akses Prometheus pakai hostname `prometheus`.

## File Pendukung

- **`prometheus.yml`** — config utama Prometheus. Berisi `scrape_interval` (tiap berapa detik ambil metrics) dan `scrape_configs` (daftar target yang di-scrape). Saat ini cuma scrape dirinya sendiri (`localhost:9090`) — tambah target baru di sini kalau mau monitor service lain (contoh: exporter buat postgres/redis/kafka).

- **`grafana/provisioning/datasources/datasource.yml`** — auto-provisioning datasource Grafana. Begini Grafana begitu start udah otomatis punya datasource **Prometheus** (`http://prometheus:9090`) tanpa perlu setup manual lewat UI.

- **`.env.example`** — template kredensial admin Grafana (`GRAFANA_USER`, `GRAFANA_PASSWORD`). Copy jadi `.env` untuk override:
  ```bash
  cp .env.example .env
  ```

## Cara Pakai

```bash
docker compose up -d
```

- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (login: `admin`/`admin` default, atau sesuai `.env`)

## Nambah Target Scrape Baru

Edit `prometheus.yml`, tambah entry di `scrape_configs`, lalu restart Prometheus:
```yaml
scrape_configs:
  - job_name: "postgres"
    static_configs:
      - targets: ["postgres-exporter:9187"]
```
```bash
docker compose restart prometheus
```
