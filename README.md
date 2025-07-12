# VoiceDevAssistant (音声開発アシスタント)

Whisper.cppを利用して、音声入力から開発用の指示プロンプトを生成し、自動で貼り付けるためのツールです。

## ✨ 主な機能

* マイクからの音声をリアルタイムで文字起こし
* 目的に応じて、文字起こし結果を開発用のプロンプトに整形
    * 実装案モード
    * 仕様書モード
    * UI/UX改善提案モード
    * データベース設計モード
* ホットキー一つで、アクティブなウィンドウに結果を自動入力

## 🎬 動作デモ

（ここに、実際に動いている様子を録画したGIF動画を貼り付けると最高です！）

## ⚙️ 必要なもの

* Python 3.9以上
* [FFmpeg](https://ffmpeg.org/): マイクからの録音に使用
* [whisper.cpp](https://github.com/ggerganov/whisper.cpp): 高速な文字起こしに使用 (このリポジトリに同梱済み)

## 🔧 セットアップ手順

1.  **リポジトリをクローン**
    ```bash
    git clone [https://github.com/KojiOkazaki/VoiceDevAssistant.git](https://github.com/KojiOkazaki/VoiceDevAssistant.git)
    cd VoiceDevAssistant
    ```
2.  **仮想環境の作成と有効化**
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```
3.  **必要なライブラリをインストール**
    ```bash
    pip install -r requirements.txt
    ```
4.  **whisper.cppをビルド**
    ```bash
    cd whisper.cpp
    make
    ```
5.  **（macOSのみ）アクセシビリティ権限の設定**
    「システム設定」>「プライバシーとセキュリティ」>「アクセシビリティ」で、お使いのターミナルアプリに権限を許可してください。

## 使い方

1.  以下のコマンドでプログラムを起動します。
    ```bash
    python whisper.cpp/main.py
    ```
2.  テキストを入力したいウィンドウをアクティブにして、以下のホットキーを押します。
    * **音声入力開始**: `Cmd + Shift + V`
    * **モード切替**: `Cmd + Shift + 1` (実装案), `2` (仕様書), ...
