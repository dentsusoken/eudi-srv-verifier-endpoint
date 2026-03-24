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

Open `http://localhost:4200` in a browser.

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

1. In the Verifier UI (`http://localhost:4200`), initiate a presentation request
2. Select the VC to present and approve in the wallet app

> **Note:** In the Verifier UI, select **OpenID4VP** as the Presentation Profile.
