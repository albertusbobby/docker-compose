# Monitoring (Prometheus + Grafana + Zipkin)

Stack monitoring dasar: Prometheus buat scrape & simpan metrics, Zipkin buat nyimpen distributed trace, Grafana buat visualisasi keduanya (metrics + trace) dalam satu tempat.

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
| | `depends_on: prometheus, zipkin` | Grafana nunggu Prometheus & Zipkin jalan dulu sebelum start |
| **zipkin** | `image: openzipkin/zipkin` | Image resmi Zipkin — server penyimpan & UI distributed trace |
| | `ports: 9411` | Port akses web UI Zipkin sekaligus endpoint buat app ngirim trace (`POST /api/v2/spans`) |
| | `extra_hosts: host.docker.internal` | Biar service yang jalan di host (misal `personal-service`) bisa kirim trace ke Zipkin lewat hostname ini kalau perlu resolve balik |

> Catatan: Zipkin di sini pakai **in-memory storage** (default image, tanpa storage backend seperti Elasticsearch/Cassandra) — jadi data trace hilang tiap kali container di-restart. Cukup buat kebutuhan dev/debug lokal.

Semua service satu network `dev-network`, jadi Grafana bisa akses Prometheus & Zipkin pakai hostname container (`prometheus`, `zipkin`).

## File Pendukung

- **`prometheus.yml`** — config utama Prometheus. Berisi `scrape_interval` (tiap berapa detik ambil metrics) dan `scrape_configs` (daftar target yang di-scrape). Saat ini scrape dirinya sendiri (`localhost:9090`) dan `personal-service` (`host.docker.internal:8080`, service Spring Boot yang jalan di host, di-scrape lewat `/personal-service/actuator/prometheus`) — tambah target baru di sini kalau mau monitor service lain (contoh: exporter buat postgres/redis/kafka).

- **`grafana/provisioning/datasources/datasource.yml`** — auto-provisioning datasource Grafana. Begitu Grafana start, udah otomatis punya 2 datasource tanpa setup manual lewat UI:
  - **Prometheus** (`http://prometheus:9090`) — metrics, jadi default datasource
  - **Zipkin** (`http://zipkin:9411`) — buat lihat/cari trace langsung dari Grafana (Explore → pilih datasource Zipkin)

- **`.env.example`** — template kredensial admin Grafana (`GRAFANA_USER`, `GRAFANA_PASSWORD`). Copy jadi `.env` untuk override:
  ```bash
  cp .env.example .env
  ```

## Ngirim Trace dari Aplikasi ke Zipkin

Supaya trace muncul di Zipkin/Grafana, aplikasi (misal `personal-service` yang Spring Boot) perlu dikonfigurasi kirim trace ke endpoint Zipkin. Karena Zipkin jalan di Docker dan app-nya di host, endpoint-nya pakai `host.docker.internal` juga (kebalikan arah dari Prometheus yang nge-scrape):

```yaml
# application.yml
management:
  tracing:
    sampling:
      probability: 1.0 # 100% trace buat dev, turunin kalau di prod
  zipkin:
    tracing:
      endpoint: http://localhost:9411/api/v2/spans
```

Dependency yang dibutuhkan (Spring Boot 3.x + Micrometer Tracing):
```
micrometer-tracing-bridge-brave
zipkin-reporter-brave
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

## Contoh Query PromQL

Coba di `http://localhost:9090/graph`. Contoh di bawah pakai target `personal-service` (Spring Boot + Micrometer), sesuaikan label `application`/`uri` untuk service lain.

**Request count & rate**
```promql
# Total request ke endpoint tertentu
http_server_requests_seconds_count{application="personal-service", uri="/personal/v1/inquiry"}

# Request per detik (5 menit terakhir)
rate(http_server_requests_seconds_count{application="personal-service", uri="/personal/v1/inquiry"}[5m])
```

**Latency rata-rata** (pakai `_sum`/`_count`, bukan histogram — lihat catatan di bawah)
```promql
rate(http_server_requests_seconds_sum{application="personal-service", uri="/personal/v1/inquiry"}[5m])
/
rate(http_server_requests_seconds_count{application="personal-service", uri="/personal/v1/inquiry"}[5m])
```

**Error rate** (status 5xx / total)
```promql
sum(rate(http_server_requests_seconds_count{application="personal-service", status=~"5.."}[5m]))
/
sum(rate(http_server_requests_seconds_count{application="personal-service"}[5m]))
```

**JVM heap usage**
```promql
jvm_memory_used_bytes{application="personal-service", area="heap"}
```

**CPU usage process**
```promql
process_cpu_usage{application="personal-service"}
```

**Cek service up/down**
```promql
up{job="personal-service"}
```

> Query `histogram_quantile(...)` buat p95/p99 latency butuh metric `_bucket`, yang defaultnya tidak diaktifkan Spring Boot. Aktifkan dulu di `application.yml` service-nya:
> ```yaml
> management:
>   metrics:
>     distribution:
>       percentiles-histogram:
>         http.server.requests: true
> ```
