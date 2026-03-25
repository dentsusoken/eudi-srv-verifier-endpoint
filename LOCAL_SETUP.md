# Local Environment Setup

## 0. Prerequisites

| Tool | Purpose | Install |
|---|---|---|
| openssl | Generate keys and certificates | `brew install openssl` |
| keytool | Generate JKS keystore | Bundled with JDK (`brew install openjdk`) |
| Docker | Run containers | [docker.com](https://www.docker.com/) |

## 1. Directory Structure

```
<working directory>/
├── eudi-srv-verifier-endpoint/
│   └── scripts/
│       └── setup-verifier-certs.sh
├── eudi-web-verifier/
│   ├── patches/                    ← patch files for local overrides
│   └── scripts/
│       └── patch_academic_credit.sh
└── eudi-app-ios-wallet-ui/
```

## 2. Start server

### Generate certificates

```bash
bash eudi-srv-verifier-endpoint/scripts/setup-verifier-certs.sh
```

Generates `src/main/resources/keystore.jks` and updates `application-local.properties`.

> **Note:** Requires `eudi-srv-issuer-oidc-py/script/setup-certs.sh` to have been run first (IACA certs are required).
> If `setup-certs.sh` is re-run, `setup-verifier-certs.sh` must also be re-run (IACA key changes).

### Generate TLS certificate for HTTPS (local only)

```bash
bash eudi-srv-verifier-endpoint/scripts/setup-local-tls.sh
```

Generates `docker/haproxy.pem` and `docker/haproxy-local.conf`, and installs the local CA into the booted iOS simulator.

> **Note:** Run with a simulator already booted to install the CA automatically. For real devices, follow the instructions printed by the script.
> This step is for local development only. For cloud deployment, use a certificate issued by Let's Encrypt (see [Deploy to cloud](#3-deploy-to-cloud)).

### Generate Verifier UI local override files

```bash
bash eudi-web-verifier/scripts/patch_nii_demo.sh
```

### Start containers

```bash
cd eudi-srv-verifier-endpoint/docker
docker compose --profile local up --build
```

> **Note:** `--build` is required on first run. Subsequent runs can omit it unless source code has changed.

Open `https://localhost` in a browser.

### Accessing from another machine

If the wallet or browser runs on a different machine, set `VERIFIER_PUBLICURL` in `docker/docker-compose.yaml` to the IP address of the machine running the containers:

```yaml
VERIFIER_PUBLICURL: "http://<machine-ip>:8080"
```

This URL is embedded in QR codes and used by the wallet to communicate with the verifier backend directly. No rebuild is required — just restart the containers after changing the value.

> **Note:** Configure Issuer Chain is not required — leave it empty to trust all issuers.

### Clean build the wallet app

In Xcode, do a clean build and run:

**⌘⇧K** (Clean Build Folder) → **⌘R** (Run)

### Present VC

1. In the Verifier UI (`https://localhost`), initiate a presentation request
2. Select the VC to present and approve in the wallet app

> **Note:** In the Verifier UI, select **OpenID4VP** as the Presentation Profile.

## 3. Deploy to cloud

### Replace TLS certificate

Replace `docker/haproxy.pem` with a certificate issued for the server's domain (e.g. via Let's Encrypt):

```bash
cat /etc/letsencrypt/live/<your-domain>/fullchain.pem \
    /etc/letsencrypt/live/<your-domain>/privkey.pem \
    > docker/haproxy.pem
```

### Update VERIFIER_PUBLICURL

Set `VERIFIER_PUBLICURL` in `docker/docker-compose.yaml` to the server's domain:

```yaml
VERIFIER_PUBLICURL: "https://<your-domain>"
```

### Start containers

```bash
cd eudi-srv-verifier-endpoint/docker
docker compose --profile local up --build
```
