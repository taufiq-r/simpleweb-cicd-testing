# GitHub Secrets Setup - Complete & Troubleshooting

## ✅ Step 1: Add Secret ke GitHub

**Path:** Repo → Settings → Secrets and variables → Actions → New repository secret

### Secret: DISCORD_WEBHOOK

```
Name:  DISCORD_WEBHOOK
Value: https://discord.com/api/webhooks/WEBHOOK_ID/WEBHOOK_TOKEN
```

**Contoh lengkap:**
```
Name:  DISCORD_WEBHOOK
Value: https://discord.com/api/webhooks/1234567890123456789/abc-def-ghi-jklmnopqrst_UVWXYZ_1234567890abcdef_5678910
```

---

## ✅ Step 2: Get Discord Webhook URL (QUICK WAY)

### 3 Langkah Dapatkan Webhook URL:

1. **Buka Discord server** → Klik server name (top-left)
2. **Settings → Integrations → Webhooks → New Webhook**
3. **Pilih channel** (misal: #notifications) → **Copy Webhook URL**

**Copy format:** 
```
https://discord.com/api/webhooks/1234567890123456789/abc-XYZ-123
```

**Paste ke GitHub:** Settings → Secrets → New secret
```
Name:  DISCORD_WEBHOOK
Value: https://discord.com/api/webhooks/...
```

### Verifikasi Webhook (Di Terminal):

```bash
# Replace dengan webhook URL Anda
WEBHOOK="https://discord.com/api/webhooks/YOUR_ID/YOUR_TOKEN"

# Test 1: Simple test
curl -X POST -H 'Content-Type: application/json' \
  -d '{"content":"Test message from terminal"}' \
  $WEBHOOK

# Test 2: Dengan embed (seperti workflow)
curl -X POST -H 'Content-Type: application/json' \
  -d '{
    "embeds": [{
      "title": "CI Test",
      "description": "Test dari terminal",
      "color": 3066993
    }]
  }' \
  $WEBHOOK
```

Jika berhasil, akan ada message di Discord channel.

---

## ✅ Contoh GitHub Secrets Lengkap

Untuk testing, minimal hanya perlu **DISCORD_WEBHOOK**:

| Name | Value | Required? |
|------|-------|-----------|
| `DISCORD_WEBHOOK` | `https://discord.com/api/webhooks/...` | ✅ YES |
| `STAGE_HOST` | `staging.example.com` | ❌ No (untuk deploy nanti) |
| `PROD_HOST` | `prod.example.com` | ❌ No (untuk deploy nanti) |

---

## ❌ Troubleshooting: Notif Tidak Masuk

### Masalah 1: Secret Name Salah

**GitHub menginginkan:** `DISCORD_WEBHOOK`

Pastikan:
- ✅ Huruf besar semua
- ✅ Underscore `_` di tengah
- ✅ Bukan `DISCORD_HOOK`, `DISCORD_URL`, etc.

### Masalah 2: Secret Value Tidak Valid

**Cek format webhook URL:**
```
✅ BENAR:   https://discord.com/api/webhooks/1234567890/abc_XYZ
❌ SALAH:   discord.com/api/webhooks/...
❌ SALAH:   https://discordapp.com/api/webhooks/...
```

Gunakan `https://discord.com/api/webhooks/` (bukan discordapp).

### Masalah 3: Workflow Tidak Trigger

**Cek:**
```bash
# Lihat file ada atau tidak
ls -la .github/workflows/ci.yml

# Cek action file
ls -la .github/actions/discord-notify/action.yml
```

Jika tidak ada, file belum ter-push ke GitHub.

### Masalah 4: Bug di Discord Action

**Kemungkinan:** payload JSON tidak ter-substitute dengan benar.

**Solusi:** Update action file dengan kode yang benar di bawah.

---

## 🔧 FIX: Update Discord Action (Jika Notif Tidak Masuk)

Kalau notif masih tidak masuk, replace `.github/actions/discord-notify/action.yml` dengan:

```yaml
name: Discord notify composite
description: Send Discord webhook notification with embeds
inputs:
  webhook:
    description: 'Discord webhook URL'
    required: true
  status:
    description: 'success|failure|info'
    required: true
  title:
    description: 'Title for embed'
    required: true
  body:
    description: 'Body/description for embed'
    required: true
runs:
  using: composite
  steps:
    - name: Send Discord notification
      shell: bash
      env:
        WEBHOOK_URL: ${{ inputs.webhook }}
        STATUS: ${{ inputs.status }}
        TITLE: ${{ inputs.title }}
        BODY: ${{ inputs.body }}
      run: |
        # Determine color based on status
        case "$STATUS" in
          success)
            COLOR=3066993  # Green
            ;;
          failure)
            COLOR=15158332  # Red
            ;;
          *)
            COLOR=9807270   # Orange
            ;;
        esac
        
        # Send to Discord
        curl -X POST "$WEBHOOK_URL" \
          -H 'Content-Type: application/json' \
          -d "{
            \"embeds\": [{
              \"title\": \"$TITLE\",
              \"description\": \"$BODY\",
              \"color\": $COLOR,
              \"timestamp\": \"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\"
            }]
          }"
```

---

## 🧪 Test Checklist

### 1. Verify Secret Added to GitHub

```bash
# Push perubahan ke GitHub
git add .
git commit -m "Add discord action fix"
git push origin main

# Go to: repo → Settings → Secrets and variables → Actions
# Verify: DISCORD_WEBHOOK ada di list
```

### 2. Verify Workflow File

```bash
# Pastikan workflow file benar
ls -la .github/workflows/ci.yml
cat .github/workflows/ci.yml
```

### 3. Manual Test Discord Webhook

```bash
# Di terminal laptop Anda
WEBHOOK="https://discord.com/api/webhooks/YOUR_ID/YOUR_TOKEN"

curl -X POST -H 'Content-Type: application/json' \
  -d '{
    "embeds": [{
      "title": "CI Test Manual",
      "description": "Testing webhook dari terminal",
      "color": 3066993
    }]
  }' \
  $WEBHOOK

# Cek Discord - seharusnya ada message
```

### 4. Trigger Workflow dengan Push

```bash
# Buat perubahan kecil
echo "# Updated" >> README.md

git add README.md
git commit -m "Test workflow trigger"
git push origin main

# Go to: repo → Actions tab
# Tunggu workflow selesai
# Cek Discord untuk notification
```

---

## 📋 Complete Secret Setup Example

Jika ingin setup lengkap untuk nanti (staging + production), tambahkan semua ini di GitHub:

### Setting → Secrets and Variables → Actions → New repository secret

**Secret 1: CI Notification**
```
Name:  DISCORD_WEBHOOK
Value: https://discord.com/api/webhooks/1234567890/abc-def-ghi
```

**Secret 2: Staging Deployment** (optional, untuk nanti)
```
Name:  STAGE_HOST
Value: staging.example.com
```

**Secret 3: Production Deployment** (optional, untuk nanti)
```
Name:  PROD_HOST
Value: prod.example.com
```

**Secret 4: Deploy User** (optional, untuk nanti)
```
Name:  DEPLOY_USER
Value: deploy
```

**Secret 5: SSH Key** (optional, untuk nanti)
```
Name:  SSH_PRIVATE_KEY
Value: -----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA...
...
-----END RSA PRIVATE KEY-----
```

**Secret 6: Staging URL** (optional, untuk nanti)
```
Name:  STAGE_APP_URL
Value: https://staging.example.com
```

**Secret 7: Production URL** (optional, untuk nanti)
```
Name:  PROD_APP_URL
Value: https://example.com
```

---

## ✅ Workflow Execution Order

1. **Push code ke GitHub** → ci.yml trigger
2. **Checkout code** → success
3. **Setup Docker** → success
4. **Build frontend image** → success/failure
5. **Build backend image** → success/failure
6. **Push to GHCR** → success/failure
7. **Send Discord notification** → ✅ Success/Failure message

---

## 🐛 Common Errors & Solutions

### Error: "webhook validation failed"
```
Penyebab: Webhook URL tidak valid atau sudah dihapus
Solusi:   Re-copy webhook URL dari Discord
```

### Error: "401 Unauthorized"
```
Penyebab: Webhook token tidak valid/expired
Solusi:   Delete webhook di Discord, buat baru, copy URL
```

### Workflow Success tapi No Discord Message
```
Penyebab: Secret DISCORD_WEBHOOK tidak ada/salah nama
Solusi:   Check Settings → Secrets → verify DISCORD_WEBHOOK ada
```

### Error at "Post failure notification to Discord"
```
Penyebab: Action syntax atau variable substitution error
Solusi:   Update action.yml dengan code di atas (FIX section)
```

---

## 🎯 Next Steps

1. ✅ Add `DISCORD_WEBHOOK` secret ke GitHub
2. ✅ Test webhook URL di terminal dengan curl
3. ✅ Fix action.yml jika perlu (copy dari section FIX di atas)
4. ✅ Push code dengan `git push origin main`
5. ✅ Check Actions tab → lihat workflow run
6. ✅ Check Discord → cari notification

Mau saya update action file langsung di repo Anda?
