# Xcode プロジェクト セットアップ手順

## 手順1: Xcode で新規プロジェクトを作成

1. Xcode を開く
2. **File > New > Project...** (⇧⌘N)
3. **iOS > App** を選択して Next
4. 以下を入力:
   - **Product Name**: `RayBanMetaAI`
   - **Team**: 自分の Apple Developer アカウント
   - **Organization Identifier**: `com.example` (自分のに変更可)
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - Include Tests: チェック外してOK
5. 保存先: `rayban-meta-ios/RayBanMetaAI/` を選択
6. Create

## 手順2: 自動生成されたファイルを置き換え

Xcode が作成した以下のファイルを、リポジトリにあるファイルで **上書き** してください:

| Xcode が生成したファイル | → 置き換えるファイル |
|------------------------|-------------------|
| `RayBanMetaAIApp.swift` | `RayBanMetaAI/RayBanMetaAI/RayBanMetaAIApp.swift` |
| `ContentView.swift` | `RayBanMetaAI/RayBanMetaAI/ContentView.swift` |

さらに、以下のファイルをプロジェクトに **追加** (ドラッグ&ドロップ):
- `RayBanMetaAI/RayBanMetaAI/CameraViewModel.swift`

## 手順3: Meta Wearables DAT SDK を追加 (Swift Package Manager)

1. Xcode > **File > Add Package Dependencies...**
2. 右上の検索欄に入力:
   ```
   https://github.com/facebook/meta-wearables-dat-ios
   ```
3. `meta-wearables-dat-ios` を選択
4. Dependency Rule: **Up to Next Major Version** → `0.4.0`
5. **Add Package** をクリック
6. ターゲット `RayBanMetaAI` に以下の3つを追加:
   - ✅ **MWDATCore**
   - ✅ **MWDATCamera**
   - ✅ **MWDATMockDevice**
7. **Add Package** をクリック

## 手順4: Info.plist を設定

Xcode のプロジェクトナビゲーターで Info.plist を開き、以下のキーを追加:

### 方法A: Xcode UI で追加

| Key | Type | Value |
|-----|------|-------|
| `CFBundleURLTypes` | Array | (下記参照) |
| `LinkURLScheme` | String | `raybanmetaai` |
| `MetaAppID` | String | (空文字列 - 開発者モード用) |
| `NSCameraUsageDescription` | String | `Ray-Ban Meta グラスのカメラストリームを受信するために使用します` |
| `NSBluetoothAlwaysUsageDescription` | String | `Ray-Ban Meta グラスと接続するために使用します` |
| `LSApplicationQueriesSchemes` | Array | `fb-metaai` |

#### URL Schemes の設定:
1. Info.plist > URL Types > + ボタン
2. URL Schemes: `raybanmetaai`
3. Identifier: `com.example.raybanmetaai`

### 方法B: リポジトリの Info.plist で上書き

`RayBanMetaAI/RayBanMetaAI/Info.plist` をそのまま使用。
ただし Xcode のビルド設定で **Generate Info.plist File = NO** に設定し、
**Info.plist File** パスを `RayBanMetaAI/Info.plist` に設定してください。

## 手順5: ビルド設定の確認

1. プロジェクト設定 > General:
   - **Minimum Deployments**: iOS 15.2
   - **Bundle Identifier**: `com.example.raybanmetaai` (自分のに変更)

2. Signing & Capabilities:
   - **Team**: 自分のアカウント
   - **Automatically manage signing**: ✅ ON

## 手順6: iPhone 実機で実行

1. iPhone を USB で Mac に接続
2. Xcode 上部のデバイス選択で iPhone を選択
3. ▶ Run (⌘R) でビルド & インストール
