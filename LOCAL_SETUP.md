# Local Environment Setup

## 0. Prerequisites

| Tool | Purpose | Install |
|---|---|---|
| openssl | Generate keys and certificates | `brew install openssl` |
| keytool | Generate JKS keystore | Bundled with JDK (`brew install openjdk`) |
| Node.js / npm | Run Verifier UI | `brew install node` |

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
At the end of the output, the certificate to be registered in the Verifier UI is printed between the following markers — copy this for the next step:

```
-------- Configure Issuer Chain --------
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
----------------------------------------
```

> **Note:** Requires `eudi-srv-issuer-oidc-py/script/setup-certs.sh` to have been run first (IACA certs are required).
> If `setup-certs.sh` is re-run, `setup-verifier-certs.sh` must also be re-run (IACA key changes).

### Start verifier backend

```bash
cd eudi-srv-verifier-endpoint
./gradlew bootRun --args='--spring.profiles.active=local'
```

### Register issuer chain in Verifier UI

Generate local override files and start the verifier UI:

```bash
cd eudi-web-verifier
bash scripts/patch_academic_credit.sh
npm run config && npx ng serve --configuration local
```

Open `http://localhost:4200` in a browser, select **Configure Issuer Chain** from the header menu, and paste the content of the following file into the text area:

```
eudi-srv-issuer-oidc-py/script/certs/trusted_cas/IACA_UT.pem
```

> **Note:** This must be done after every `setup-verifier-certs.sh` run.

### Clean build the wallet app

In Xcode, do a clean build and run:

**⌘⇧K** (Clean Build Folder) → **⌘R** (Run)

### Present VC

1. In the Verifier UI (`http://localhost:4200`), initiate a presentation request
2. Select the VC to present and approve in the wallet app

> **Note:** In the Verifier UI, select **OpenID4VP** as the Presentation Profile.
