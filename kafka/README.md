# Kafka Docker Compose (PLAINTEXT & SASL SCRAM-SHA-256)

Docker Compose ini menyediakan klaster **Kafka** (menggunakan KRaft mode, tanpa ZooKeeper) dengan dua tipe listener:
1. **Non-SASL (PLAINTEXT)**: untuk koneksi tanpa autentikasi.
2. **SASL SCRAM-SHA-256**: untuk koneksi dengan autentikasi menggunakan username `user` dan password `password`.

Kedua listener di atas di-expose agar bisa diakses dari:
- **Localhost** (host machine Anda)
- **Container lain** (dalam network docker `dev-network`)

Untuk memudahkan visualisasi dan pengujian, disertakan juga **Kafka UI** yang sudah dikonfigurasi untuk terhubung ke kedua listener tersebut.

---

## Cara Menjalankan

Jalankan perintah berikut di folder ini:
```bash
docker compose up -d
```

Setelah berjalan, Anda dapat mengakses **Kafka UI** di browser:
👉 **[http://localhost:8999](http://localhost:8999)**

---

## Isi `docker-compose.yml`

| Service | Bagian | Penjelasan |
| :--- | :--- | :--- |
| **kafka** | `KAFKA_PROCESS_ROLES: broker,controller` | KRaft mode — satu node berperan jadi broker sekaligus controller (tanpa ZooKeeper) |
| | `KAFKA_LISTENERS` / `KAFKA_ADVERTISED_LISTENERS` | Definisi 5 listener: 2 buat akses dari container lain (`INTERNAL_PLAIN`/`INTERNAL_SASL`), 2 buat akses dari host (`EXTERNAL_PLAIN`/`EXTERNAL_SASL`), 1 buat komunikasi controller |
| | `KAFKA_OPTS` | Nunjuk lokasi file JAAS config (`kafka_server_jaas.conf`) buat aktifin SASL auth |
| | `KAFKA_SASL_ENABLED_MECHANISMS` | Mekanisme SASL yang dipakai: `SCRAM-SHA-256` |
| | `KAFKA_AUTHORIZER_CLASS_NAME` + `KAFKA_ALLOW_EVERYONE_IF_NO_ACL_FOUND: false` | Aktifin ACL — user yang gak punya ACL eksplisit gak bisa akses topic |
| | `KAFKA_SUPER_USERS` | User yang bypass ACL check (`admin`, `ANONYMOUS`) |
| | `volumes: kafka-data` | Named volume, nyimpen data topic/partition |
| | `volumes: ./config/...` dan `./init` | Mount config JAAS dan script inisialisasi (lihat bagian di bawah) |
| **kafka-ui** | `DYNAMIC_CONFIG_ENABLED: true` | Bisa nambah/edit koneksi cluster langsung dari UI, gak cuma dari env |

---

## Detail Port & Endpoint

| Tipe Akses | Protokol / Listener | Hostname / IP | Port | Keterangan |
| :--- | :--- | :--- | :--- | :--- |
| **Localhost (Host)** | PLAINTEXT (Non-SASL) | `localhost` | `29092` | Tanpa autentikasi |
| **Localhost (Host)** | SASL SCRAM-SHA-256 | `localhost` | `29093` | User: `user`, Pass: `password` |
| **Docker Container** | PLAINTEXT (Non-SASL) | `kafka` | `9092` | Tanpa autentikasi |
| **Docker Container** | SASL SCRAM-SHA-256 | `kafka` | `9093` | User: `user`, Pass: `password` |

---

## Contoh Cara Menghubungkan (Connection Examples)

### 1. Dari Container Lain (Dalam Docker Network `dev-network`)

Pastikan container aplikasi Anda berada di network `dev-network`.

#### Koneksi Tanpa Autentikasi (Non-SASL):
- **Bootstrap Servers:** `kafka:9092`

#### Koneksi dengan SASL SCRAM-SHA-256:
- **Bootstrap Servers:** `kafka:9093`
- **Security Protocol:** `SASL_PLAINTEXT`
- **SASL Mechanism:** `SCRAM-SHA-256`
- **JAAS Config:**
  ```properties
  org.apache.kafka.common.security.scram.ScramLoginModule required username="user" password="password";
  ```

---

### 2. Dari Mesin Lokal (Host Machine / Local Program)

#### Koneksi Tanpa Autentikasi (Non-SASL):
- **Bootstrap Servers:** `localhost:29092`

#### Koneksi dengan SASL SCRAM-SHA-256:
- **Bootstrap Servers:** `localhost:29093`
- **Security Protocol:** `SASL_PLAINTEXT`
- **SASL Mechanism:** `SCRAM-SHA-256`
- **JAAS Config:**
  ```properties
  org.apache.kafka.common.security.scram.ScramLoginModule required username="user" password="password";
  ```

---

## Contoh Pengujian dengan CLI

Jika Anda memiliki Kafka CLI di lokal, Anda dapat menguji producer/consumer:

### Menguji Listener Non-SASL:
```bash
# Membuat Topic
kafka-topics.sh --bootstrap-server localhost:29092 --create --topic test-plaintext

# Mengirim Pesan (Producer)
kafka-console-producer.sh --bootstrap-server localhost:29092 --topic test-plaintext
```

### Menguji Listener SASL SCRAM-SHA-256:
Buat file konfigurasi klien terlebih dahulu bernama `client-sasl.properties`:
```properties
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-256
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="user" password="password";
```

Kemudian gunakan konfigurasi tersebut:
```bash
# Membuat Topic
kafka-topics.sh --bootstrap-server localhost:29093 --command-config client-sasl.properties --create --topic test-sasl

# Mengirim Pesan (Producer)
kafka-console-producer.sh --bootstrap-server localhost:29093 --producer.config client-sasl.properties --topic test-sasl
```

---

## File Pendukung

### `config/kafka_server_jaas.conf`

JAAS config yang di-mount ke broker (dirujuk lewat env `KAFKA_OPTS`). Isinya cuma aktifin `ScramLoginModule` — kredensial user SCRAM sendiri **tidak** disimpan di file ini, tapi didaftarkan langsung ke Kafka lewat `kafka-configs` (lihat `create-users.sh` di bawah).

### `init/create-users.sh`

Bikin user SCRAM-SHA-256 buat autentikasi. Dijalankan manual (bukan otomatis saat `up`), karena butuh broker udah running dulu:
```bash
docker compose exec kafka bash /init/create-users.sh
```
User yang dibuat:
| User | Password |
| :--- | :--- |
| `admin` | `admin123` |
| `app-a` | `appa123` |
| `app-b` | `appb123` |
| `readonly` | `readonly123` |

### `init/create-topics.sh`

Bikin 3 topic default (`topic-a`, `topic-b`, `topic-c`), masing-masing 3 partition, replication factor 1 (karena single broker):
```bash
docker compose exec kafka bash /init/create-topics.sh
```

### `init/create-acls.sh`

Set ACL per user ke topic (jalanin setelah user & topic dibuat):
```bash
docker compose exec kafka bash /init/create-acls.sh
```
Aturan yang di-set:
- `app-a` → READ+WRITE ke `topic-a`, `topic-b`, `topic-c`
- `app-b` → READ+WRITE hanya ke `topic-a`
- `readonly` → READ-only ke semua topic

> Urutan setup dari fresh start: `docker compose up -d` → `create-users.sh` → `create-topics.sh` → `create-acls.sh`.
