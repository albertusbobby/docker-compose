# Kafka Docker Compose (PLAINTEXT & SASL SCRAM-SHA-256)

Docker Compose ini menyediakan klaster **Kafka** (menggunakan KRaft mode, tanpa ZooKeeper) dengan dua tipe listener:
1. **Non-SASL (PLAINTEXT)**: untuk koneksi tanpa autentikasi.
2. **SASL SCRAM-SHA-256**: untuk koneksi dengan autentikasi menggunakan username `user` dan password `password`.

Kedua listener di atas di-expose agar bisa diakses dari:
- **Localhost** (host machine Anda)
- **Container lain** (dalam network docker `kafka-net`)

Untuk memudahkan visualisasi dan pengujian, disertakan juga **Kafka UI** yang sudah dikonfigurasi untuk terhubung ke kedua listener tersebut.

---

## Cara Menjalankan

Jalankan perintah berikut di folder ini:
```bash
docker compose up -d
```

Setelah berjalan, Anda dapat mengakses **Kafka UI** di browser:
👉 **[http://localhost:8080](http://localhost:8080)**

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

### 1. Dari Container Lain (Dalam Docker Network `kafka-net`)

Pastikan container aplikasi Anda berada di network `kafka-net`.

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
