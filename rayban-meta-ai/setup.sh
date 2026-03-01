#!/bin/bash
# =============================================
# Ray-Ban Meta AI アプリ セットアップスクリプト
# =============================================
# 使い方: ./setup.sh
# 前提: Android Studio がインストール済みであること

set -e

echo "=== Ray-Ban Meta AI セットアップ ==="
echo ""

# 1. local.properties の確認
if [ ! -f "local.properties" ]; then
    echo "[1/3] local.properties を作成します..."
    cp local.properties.example local.properties
    echo "  -> local.properties を作成しました"
    echo "  -> github_token と openai_api_key を編集してください"
    echo ""
    read -p "  local.properties を編集してから Enter を押してください..."
else
    echo "[1/3] local.properties は既に存在します"
fi

# 2. GitHub Token の確認
GITHUB_TOKEN=$(grep "^github_token=" local.properties | cut -d= -f2)
if [ "$GITHUB_TOKEN" = "YOUR_GITHUB_TOKEN_HERE" ] || [ -z "$GITHUB_TOKEN" ]; then
    echo ""
    echo "  [警告] GitHub Token が設定されていません"
    echo "  GitHub > Settings > Developer settings > Personal access tokens で作成してください"
    echo "  スコープ: read:packages を有効にしてください"
    echo ""
    read -p "  local.properties に github_token を設定してから Enter を押してください..."
fi

# 3. OpenAI API Key の確認
OPENAI_KEY=$(grep "^openai_api_key=" local.properties | cut -d= -f2)
if [ "$OPENAI_KEY" = "YOUR_OPENAI_API_KEY_HERE" ] || [ -z "$OPENAI_KEY" ]; then
    echo ""
    echo "  [警告] OpenAI API Key が設定されていません"
    echo "  https://platform.openai.com/api-keys で作成してください"
    echo ""
    read -p "  local.properties に openai_api_key を設定してから Enter を押してください..."
fi

echo "[2/3] Gradle でビルドを実行します..."
echo ""

# Android Studio の Gradle Wrapper がない場合はダウンロード
if [ ! -f "gradlew" ]; then
    echo "  Gradle Wrapper が見つかりません"
    echo "  Android Studio でプロジェクトを開いてビルドしてください"
    echo ""
    echo "  手順:"
    echo "    1. Android Studio を起動"
    echo "    2. File > Open でこのフォルダを選択"
    echo "    3. Gradle の同期が自動的に開始されます"
    echo "    4. Build > Make Project でビルド"
    echo ""
    exit 0
fi

./gradlew assembleDebug

echo ""
echo "[3/3] ビルド完了!"
echo ""
echo "=== 次のステップ ==="
echo "1. Meta AI アプリでグラスをペアリング"
echo "2. グラスの Developer Mode を有効化 (設定 > バージョン番号を5回タップ)"
echo "3. アプリをスマートフォンにインストール"
echo "4. アプリを起動して「接続」をタップ"
echo ""
