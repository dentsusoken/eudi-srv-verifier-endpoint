#!/bin/bash
# ローカルTLS証明書のセットアップスクリプト
# iOSシミュレータ・実機から信頼されるHTTPS証明書を生成する
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCKER_DIR="$SCRIPT_DIR/../docker"

# mkcert のインストール確認
if ! command -v mkcert &>/dev/null; then
  echo "Installing mkcert..."
  brew install mkcert
fi

# ローカルCAをシステムに登録
mkcert -install

# Mac のローカルIPを取得
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "")

# 証明書を生成
echo "=== Generating TLS certificate ==="
if [ -n "$LOCAL_IP" ]; then
  echo "  Hosts: localhost, 127.0.0.1, $LOCAL_IP"
  mkcert -cert-file "$DOCKER_DIR/server.crt" -key-file "$DOCKER_DIR/server.key" \
    localhost 127.0.0.1 "$LOCAL_IP"
else
  echo "  Hosts: localhost, 127.0.0.1"
  mkcert -cert-file "$DOCKER_DIR/server.crt" -key-file "$DOCKER_DIR/server.key" \
    localhost 127.0.0.1
fi

# HAProxy用に証明書と秘密鍵を結合
cat "$DOCKER_DIR/server.crt" "$DOCKER_DIR/server.key" > "$DOCKER_DIR/haproxy.pem"
rm "$DOCKER_DIR/server.crt" "$DOCKER_DIR/server.key"
echo "  -> $DOCKER_DIR/haproxy.pem"

# haproxy-local.conf を生成
echo "=== Generating haproxy-local.conf ==="
patch -o "$DOCKER_DIR/haproxy-local.conf" "$DOCKER_DIR/haproxy.conf" "$DOCKER_DIR/patches/haproxy-local.conf.patch"
echo "  -> $DOCKER_DIR/haproxy-local.conf"

# 起動中のシミュレータにCAをインストール
CAROOT=$(mkcert -CAROOT)
echo ""
echo "=== Installing root CA on booted iOS simulator ==="
if xcrun simctl keychain booted add-root-cert "$CAROOT/rootCA.pem" 2>/dev/null; then
  echo "  -> Installed successfully"
else
  echo "  -> No booted simulator found, skipped"
fi

echo ""
echo "=== For real device ==="
echo "  1. Transfer $CAROOT/rootCA.pem to your device (AirDrop etc.)"
echo "  2. Settings > General > VPN & Device Management > install the profile"
echo "  3. Settings > General > About > Certificate Trust Settings > enable full trust"

if [ -n "$LOCAL_IP" ]; then
  echo ""
  echo "=== VERIFIER_PUBLICURL for real device access ==="
  echo "  Set VERIFIER_PUBLICURL to: https://$LOCAL_IP"
  echo "  in docker/docker-compose.yaml"
fi

echo ""
echo "=== Done ==="
