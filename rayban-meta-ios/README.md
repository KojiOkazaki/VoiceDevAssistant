# Ray-Ban Meta AI - iOS (Swift)

Ray-Ban Meta グラスのカメラストリームを iPhone で受信し、AI 分析を行うアプリ。

## 必要環境

- **Xcode 14.0 以降** (推奨: Xcode 15+)
- **iOS 15.2 以上** の iPhone 実機
- **Ray-Ban Meta グラス** (第1世代 or 第2世代) または Meta Ray-Ban Display グラス
- **Meta AI アプリ** v254 以上

## セットアップ手順

### 1. Xcode でプロジェクトを開く

```bash
open RayBanMetaAI/RayBanMetaAI.xcodeproj
```

### 2. Swift Package Manager で SDK を追加

プロジェクトを開くと、Xcode が自動的に Meta Wearables DAT SDK を解決します。
手動で追加する場合:

1. Xcode > File > Add Package Dependencies...
2. URL: `https://github.com/facebook/meta-wearables-dat-ios`
3. バージョン: `0.4.0` 以上を選択
4. パッケージ: `MWDATCore`, `MWDATCamera`, `MWDATMockDevice` を追加

### 3. Bundle Identifier を変更

`com.example.raybanmetaai` を自分の Bundle ID に変更してください。

### 4. 署名設定

- Xcode > Signing & Capabilities
- Team を自分の Apple Developer アカウントに設定
- Automatically manage signing にチェック

### 5. メガネのセットアップ

1. Meta AI アプリ (v254+) をインストール
2. グラスを Meta AI アプリに接続
3. グラスのソフトウェアバージョンを確認:
   - Ray-Ban Meta: v20 以上
   - Meta Ray-Ban Display: v21 以上
4. **開発者モードを有効化**:
   - Meta AI アプリ > 設定 > アプリ情報
   - バージョン番号を **5回タップ**
   - 開発者モードのトグルを有効化

### 6. 実機で実行

iPhone を Mac に接続し、Xcode から Run (⌘R) で実機にインストール。

## アプリの使い方

1. **「Meta AI アプリに登録」** ボタンをタップ
2. Meta AI アプリが開き、アプリの登録を確認
3. グラスが接続されたら **「開始」** ボタンでカメラストリーム開始
4. **「撮影」** ボタンで写真をキャプチャ

## カメラストリーム設定

| 解像度 | ピクセル |
|--------|---------|
| high | 720 x 1280 |
| medium | 504 x 896 |
| low | 360 x 640 |

| フレームレート | 値 |
|-------------|---|
| FPS | 2, 7, 15, 24, 30 |

## 配布アプリの設定

開発者モードでのテストが完了したら、配布用に:

1. [Meta ウェアラブル開発者センター](https://wearables.developer.meta.com/) でアプリを登録
2. `Info.plist` の `MetaAppID` に取得した App ID を設定
3. `ClientToken` と `TeamID` も設定
