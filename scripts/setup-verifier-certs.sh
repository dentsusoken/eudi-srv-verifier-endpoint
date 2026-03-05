#!/bin/bash
# Verifier JAR 署名証明書チェーンのセットアップスクリプト
# 前提: eudi-srv-issuer-oidc-py/script/setup-certs.sh 実行済み
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

IACA_CERT="$ROOT/eudi-srv-issuer-oidc-py/script/certs/trusted_cas/IACA_UT.pem"
IACA_KEY="$ROOT/eudi-srv-issuer-oidc-py/script/certs/privKey/IACA_UT_key.pem"
WALLET_CERT_DIR="${WALLET_DIR:-$HOME/work/eudi-app-ios-wallet-ui}/Wallet/Certificate"
VERIFIER_RESOURCES="$SCRIPT_DIR/../src/main/resources"

# 前提ファイルの確認
for f in "$IACA_CERT" "$IACA_KEY"; do
  if [ ! -f "$f" ]; then
    echo "ERROR: $f が見つかりません。先に setup-certs.sh を実行してください。"
    exit 1
  fi
done

VTMP=$(mktemp -d)
trap 'rm -rf "$VTMP"' EXIT

# ----------------------------------------------------------------
# 1. IACA_UT.pem → DER 変換して pidissuerca02_ut.der を差し替え
# ----------------------------------------------------------------
echo "=== Replacing pidissuerca02_ut.der with IACA_UT ==="
openssl x509 \
  -in "$IACA_CERT" \
  -outform DER \
  -out "$WALLET_CERT_DIR/pidissuerca02_ut.der"
echo "  -> $WALLET_CERT_DIR/pidissuerca02_ut.der"

# ----------------------------------------------------------------
# 2. Verifier JAR 署名証明書チェーン生成 (IACA_UT → intermediate → verifier)
# ----------------------------------------------------------------
echo "=== Generating Verifier JAR signing certificate chain ==="

# Intermediate CA (IACA_UT で署名)
openssl ecparam -name prime256v1 -genkey -noout \
  -out "$VTMP/intermediate.key" 2>/dev/null
openssl req -new -key "$VTMP/intermediate.key" \
  -out "$VTMP/intermediate.csr" \
  -subj "/CN=intermediate" 2>/dev/null
openssl x509 -req -in "$VTMP/intermediate.csr" \
  -CA "$IACA_CERT" -CAkey "$IACA_KEY" -CAcreateserial \
  -out "$VTMP/intermediate.crt" -days 36500 \
  -extfile <(printf "basicConstraints=critical,CA:TRUE\nkeyUsage=critical,keyCertSign,cRLSign\nsubjectAltName=DNS:intermediate\nissuerAltName=DNS:intermediate") \
  2>/dev/null

# Verifier 証明書 (intermediate で署名)
openssl ecparam -name prime256v1 -genkey -noout \
  -out "$VTMP/verifier.key" 2>/dev/null
openssl req -new -key "$VTMP/verifier.key" \
  -out "$VTMP/verifier.csr" \
  -subj "/CN=verifier" 2>/dev/null
openssl x509 -req -in "$VTMP/verifier.csr" \
  -CA "$VTMP/intermediate.crt" -CAkey "$VTMP/intermediate.key" -CAcreateserial \
  -out "$VTMP/verifier.crt" -days 36500 \
  -extfile <(printf "subjectAltName=DNS:localhost,DNS:verifier\nbasicConstraints=CA:FALSE\nkeyUsage=critical,digitalSignature") \
  2>/dev/null

echo "  chain: verifier -> intermediate -> IACA_UT"

# ----------------------------------------------------------------
# 3. keystore.jks を生成して Verifier バックエンドに配置
# ----------------------------------------------------------------
echo "=== Generating keystore.jks ==="

openssl pkcs12 -export \
  -in "$VTMP/verifier.crt" \
  -inkey "$VTMP/verifier.key" \
  -certfile <(cat "$VTMP/intermediate.crt" "$IACA_CERT") \
  -name verifier \
  -out "$VTMP/keystore.p12" \
  -passout pass:keystore 2>/dev/null

keytool -importkeystore \
  -srckeystore "$VTMP/keystore.p12" -srcstoretype PKCS12 -srcstorepass keystore \
  -destkeystore "$VTMP/keystore.jks" -deststoretype JKS \
  -deststorepass keystore -destkeypass verifier \
  -noprompt 2>/dev/null

cp "$VTMP/keystore.jks" "$VERIFIER_RESOURCES/keystore.jks"
echo "  -> $VERIFIER_RESOURCES/keystore.jks"

# ----------------------------------------------------------------
# 4. application-local.properties を更新
# ----------------------------------------------------------------
echo "=== Updating application-local.properties ==="

LOCAL_PROPS="$VERIFIER_RESOURCES/application-local.properties"
cat > "$LOCAL_PROPS" <<EOF
verifier.originalClientId=localhost
verifier.clientIdPrefix=x509_san_dns
verifier.jar.signing.algorithm=ES256
verifier.requestJwt.requestUriMethod=Post
verifier.allowedRedirectUriSchemes=http,https
verifier.publicUrl=http://localhost:8080
EOF
echo "  -> $LOCAL_PROPS"

echo ""
echo "=== Done ==="
echo ""
echo "次のステップ:"
echo "  1. Verifier バックエンドを再起動: cd $(basename "$SCRIPT_DIR"/.. ) && ./gradlew bootRun --args='--spring.profiles.active=local'"
echo "  2. Wallet アプリをクリーンビルド: Xcode で ⌘⇧K -> ⌘R"
echo "  3. 下記の内容を Verifier UI の Configure Issuer Chain に貼り付け"
echo ""
echo "-------- Configure Issuer Chain --------"
cat "$IACA_CERT"
echo "----------------------------------------"
