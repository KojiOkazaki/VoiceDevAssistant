# Ray-Ban Meta AI - スマートグラス視覚AIアシスタント

Ray-Ban Metaグラスのカメラで見ているものをリアルタイムでAI分析するAndroidアプリです。

## 機能

- **グラス接続**: Meta Wearables DAT SDKでRay-Ban Metaグラスに接続
- **カメラストリーミング**: グラスのカメラ映像をリアルタイムで取得（最大720p/30fps）
- **AI視覚分析**: OpenAI GPT-4o Visionで画像を分析
- **5つの分析モード**:
  - 一般分析: 見えているものを総合的に説明
  - テキスト認識: 看板やドキュメントの文字を読み取り・翻訳
  - 物体検出: 画像内の物体を識別・リストアップ
  - ナビゲーション: 周囲の環境・道路標識・ランドマークを分析
  - 製品情報: ブランド・製品を識別して情報提供

## 必要なもの

### ハードウェア
- Ray-Ban Meta グラス (Gen-1 または Gen-2) ※ファームウェア v20.0以上
- Android スマートフォン (Android 10以上)

### ソフトウェア
- Android Studio (Arctic Fox以上)
- Meta AI アプリ (グラスとのペアリング用)
- GitHub Personal Access Token (`read:packages` スコープ)
- OpenAI API キー

### Facebook App
- App ID: `696998827356456` (設定済み)
- [Facebook Developer Console](https://developers.facebook.com/apps/696998827356456/dashboard/)

## セットアップ手順

### 1. Meta Wearables Developer Center に登録

1. [developers.meta.com/wearables](https://developers.meta.com/wearables/) にアクセス
2. Developer Previewに申し込み
3. APPLICATION_ID を取得（開発モードでは `0` でもテスト可能）

### 2. GitHub Token の設定

Meta DAT SDKはGitHub Packagesで配布されています。

```bash
# GitHub Personal Access Token (classic) を作成
# Settings > Developer settings > Personal access tokens > Tokens (classic)
# スコープ: read:packages を有効化
```

### 3. local.properties の設定

`local.properties.example` をコピーして `local.properties` を作成:

```properties
# GitHub Token (Meta DAT SDK取得用)
github_token=ghp_YOUR_GITHUB_TOKEN_HERE

# OpenAI API Key (AI分析用)
openai_api_key=sk-YOUR_OPENAI_API_KEY_HERE
```

### 4. グラスのDeveloper Mode有効化

1. Meta AI アプリでグラスとペアリング
2. Meta AI アプリの設定 > バージョン番号を **5回タップ**
3. Developer Mode が有効化される

### 5. ビルド＆実行

```bash
cd rayban-meta-ai
./gradlew assembleDebug
# または Android Studio でプロジェクトを開いてRun
```

## 使い方

1. アプリを起動
2. 「接続」ボタンを押す → Meta AIアプリで登録が行われる
3. グラスが接続されたら「ストリーミング開始」を押す
4. グラスのカメラ映像がプレビューに表示される
5. 分析モードを選択して「分析する」を押す
6. AIが見ているものを日本語で説明

## アーキテクチャ

```
Ray-Ban Meta グラス
    ↓ (Bluetooth / DAT SDK)
Android スマートフォンアプリ
    ├── GlassesConnectionManager: グラス接続・ストリーミング管理
    ├── VisionAnalyzer: 画像をOpenAI APIに送信して分析
    ├── MainViewModel: UI状態管理
    └── MainActivity: UI表示
    ↓ (HTTPS / REST API)
OpenAI GPT-4o Vision API
    ↓
分析結果 (日本語テキスト)
```

## トラブルシューティング

### Gradle 401 エラー
GitHub Tokenに `read:packages` スコープがあるか確認してください。

### グラスが見つからない
- Meta AIアプリでグラスがペアリングされていることを確認
- グラスのファームウェアがv20.0以上か確認
- Bluetooth権限が許可されているか確認

### 分析が失敗する
- OpenAI APIキーが正しく設定されているか確認
- インターネット接続を確認
- APIの利用制限に達していないか確認

### Mock Device Kitでのテスト
実機がなくてもMock Device Kitでテスト可能:
```kotlin
// build.gradle.ktsに mwdat-mockdevice が含まれています
// SDK提供のMock Deviceツールでシミュレーション可能
```

## 参考リンク

- [Meta Wearables Developer Center](https://developers.meta.com/wearables/)
- [Meta DAT SDK Documentation](https://wearables.developer.meta.com/docs/)
- [Meta DAT Android SDK (GitHub)](https://github.com/facebook/meta-wearables-dat-android)
- [VisionClaw (参考実装)](https://github.com/sseanliu/VisionClaw)
- [OpenAI Vision API](https://platform.openai.com/docs/guides/vision)
