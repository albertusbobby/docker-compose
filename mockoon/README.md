# Mockoon CLI

Jalanin mock API dari environment Mockoon (dibuat di Mockoon desktop app) via Mockoon CLI, tanpa buka app-nya.

## Isi `docker-compose.yml`

| Bagian | Penjelasan |
| :--- | :--- |
| `image: mockoon/cli:9.8.0` | Image resmi Mockoon CLI |
| `command: --data /data/surrounding.json --port 3001` | Load environment `surrounding.json`, serve di port 3001 (port ini sesuai port yang udah diset di environment-nya lewat Mockoon app) |
| `ports: 3001` | Port akses mock API |
| `volumes` | Bind mount **read-only** ke file environment asli di storage Mockoon desktop app: `${HOME}/Library/Application Support/mockoon/storage/surrounding.json` (`${HOME}` di-substitusi docker compose dari env var, bukan `~` — compose nggak proses tilde expansion) |
| `networks: dev-network` | Biar bisa diakses container lain lewat hostname `surrounding-mockoon` |

## Kenapa bind mount ke storage Mockoon app langsung?

File `surrounding.json` di-mount langsung dari folder storage Mockoon desktop app (`~/Library/Application Support/mockoon/storage/`). Jadi kalau environment-nya diubah & disave di app (endpoint baru, response baru, dll), container **tidak perlu di-rebuild** — tinggal:

```bash
docker compose restart
```

dan container bakal baca ulang file yang udah ter-update.

## Cara Pakai

```bash
docker compose up -d
```

Mock API bisa diakses di: http://localhost:3001

Lihat log request masuk (Mockoon CLI kirim log ke stdout):

```bash
docker compose logs -f
```

## Ganti/nambah environment lain

Folder storage Mockoon app (`~/Library/Application Support/mockoon/storage/`) bisa berisi lebih dari satu environment (misalnya `demo.json` di port 3000). Kalau mau ikut dijalankan, tambah service baru di `docker-compose.yml` dengan pola yang sama (nama service ikut nama environment-nya, misal `demo-mockoon`), ganti path file & port sesuai environment-nya. Penamaan per-environment gini sengaja dipakai biar tiap environment bisa di-restart/stop sendiri-sendiri tanpa ganggu yang lain.
