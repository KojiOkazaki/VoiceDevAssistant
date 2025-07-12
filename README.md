# VoiceDevAssistant (音声開発アシスタント)

## 概要

Whisper.cppを利用して、音声入力から開発用の指示プロンプトを生成し、アクティブなウィンドウに自動で貼り付けるためのツールです。

## 主な機能

* マイクからの音声をリアルタイムで文字起こし
* 目的に応じて、文字起こし結果を開発用のプロンプトに整形
    * 実装案モード
    * 仕様書モード
    * UI/UX改善提案モード
    * データベース設計モード
* ホットキー一つで、アクティブなウィンドウに結果を自動入力

## 必要なもの

* Python 3.9以上
* [FFmpeg](https://ffmpeg.org/): マイクからの録音に使用します。
* [whisper.cpp](https://github.com/ggerganov/whisper.cpp): 高速な文字起こしに使用します (本リポジトリに同梱済み)。

## セットアップ手順

### 1. リポジトリのクローン

```bash
git clone [https://github.com/your-username/VoiceDevAssistant.git](https://github.com/your-username/VoiceDevAssistant.git)
cd VoiceDevAssistant
※ your-username の部分は、ご自身のGitHubユーザー名に置き換えてください。

2. 仮想環境の作成と有効化
Bash

python3 -m venv venv
source venv/bin/activate
※ Windowsの場合は venv\Scripts\activate を実行してください。

3. 必要なライブラリをインストール
Bash

pip install -r requirements.txt
4. whisper.cppのビルド
Bash

cd whisper.cpp
make
5. （macOSのみ）アクセシビリティ権限の設定
「システム設定」>「プライバシーとセキュリティ」>「アクセシビリティ」を開き、お使いのターミナルアプリケーション（例: Terminal.app, iTerm.app）に操作権限を許可してください。これは、スクリプトが他のウィンドウにテキストをペーストするために必要です。

使い方
以下のコマンドでプログラムを起動します。

Bash

python main.py
※ リポジトリのルートディレクトリで実行してください。

テキストを入力したいウィンドウをアクティブにして、以下のホットキーを使用します。

音声入力開始: Cmd + Shift + V

モード切替: Cmd + Shift + 1 (実装案), 2 (仕様書), 3 (UI/UX), 4 (DB設計)
