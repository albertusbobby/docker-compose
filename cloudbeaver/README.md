# CloudBeaver

GUI database universal (support Postgres, MySQL, dll) berbasis web, dari DBeaver.

## Isi `docker-compose.yml`

| Bagian | Penjelasan |
| :--- | :--- |
| `image: dbeaver/cloudbeaver:latest` | Image resmi CloudBeaver |
| `ports: 8978` | Port akses web UI |
| `volumes: cloudbeaver_data` | Named volume, nyimpen workspace: koneksi DB yang udah disave, user, konfigurasi server |
| `extra_hosts: host.docker.internal:host-gateway` | Biar bisa konek ke database yang jalan langsung di host (bukan di docker) |
| `networks: dev-network` | Biar bisa konek ke database lain di compose ini (misal `postgres`) langsung pakai hostname container |

## Cara Pakai

```bash
docker compose up -d
```

Buka di browser: http://localhost:8978

Setup awal (first run) akan diminta bikin admin user. Setelah itu, tambah koneksi database baru, misal ke Postgres:
```
host: postgres
port: 5432
database: postgres
```
(hostname `postgres` bisa di-resolve karena satu network `dev-network` dengan container postgres)
