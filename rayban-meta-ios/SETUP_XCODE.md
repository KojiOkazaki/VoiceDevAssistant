# Ray-Ban Meta iOS アプリ セットアップ手順

## 推奨: Meta 公式サンプルアプリを使う

手動で xcodeproj を作成する必要はありません。Meta が提供する公式サンプルアプリをそのまま使えます。

### 手順1: サンプルアプリをクローン & 開く

```bash
git clone https://github.com/facebook/meta-wearables-dat-ios.git
open meta-wearables-dat-ios/samples/CameraAccess/*.xcodeproj
```

プロジェクトを開いたら SPM の依存関係は自動で解決されます。そのままビルドできるはずです。

### 手順2: Signing を設定

1. Xcode > プロジェクト設定 > **Signing & Capabilities**
2. **Team**: 自分の Apple Developer アカウントを選択
3. **Bundle Identifier**: `com.cbt.mrbtest`

### 手順3: Info.plist を編集

サンプルアプリの Info.plist に以下の `MWDAT` キーを追加します。
Xcode UI または Info.plist ファイルを直接編集してください。

```xml
<key>MWDAT</key>
<dict>
    <key>MetaAppID</key>
    <string>4225976931002254</string>
    <key>Analytics</key>
    <dict>
        <key>OptOut</key>
        <true/>
    </dict>
    <key>AppLinkURLScheme</key>
    <string>https://kojiokazaki.github.io/dat-link/</string>
</dict>
```

また、`CFBundleURLTypes` にも URL スキームを追加:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>https://kojiokazaki.github.io/dat-link/</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.cbt.mrbtest</string>
    </dict>
</array>
```

**重要**: `AppLinkURLScheme` と `CFBundleURLSchemes` の値は同一にすること。

### 手順4: アプリの起動 & 接続

1. iPhone を USB で Mac に接続
2. Xcode 上部でデバイスを選択
3. **Run (⌘R)** でビルド & インストール
4. 自作アプリと Meta AI アプリを行き来して動画ストリーミングを開始

動かない場合の確認ポイント:
- MetaAppID が正しいか
- URL スキーマの設定が一致しているか
- Meta AI アプリ (v254+) でグラスが接続済みか

### カメラ設定

| 解像度 | サイズ |
|--------|--------|
| 高 | 720 x 1280 |
| 中 | 504 x 896 |
| 低 | 360 x 640 |

フレームレート: 2, 7, 15, 24, 30 fps

帯域幅が不足すると自動的に解像度 → フレームレートの順で段階的に下がります (15fps 未満にはならない)。

### ハードウェアなしでテスト (Mock Device)

Mock Device Kit を使えば、Ray-Ban Meta グラスがなくても開発・テストが可能です。
`MWDATMockDevice` パッケージを追加して使用してください。

---

## 参考: カスタムアプリを新規作成する場合

サンプルアプリを改造するのではなく、ゼロから作りたい場合:

1. Xcode > **File > New > Project...** > iOS > App (SwiftUI)
2. **File > Add Package Dependencies...** で `https://github.com/facebook/meta-wearables-dat-ios` を追加
3. MWDATCore, MWDATCamera, MWDATMockDevice を選択
4. Info.plist に上記の MWDAT 設定を追加
5. `RayBanMetaAI/RayBanMetaAI/` 内の Swift ファイルを参考にコードを記述
