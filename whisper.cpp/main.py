# main.py (Final Improved Version)
import subprocess
import os
import time
import pyperclip
from pynput import keyboard
from pydub import AudioSegment
from pydub.playback import play
import threading

# --- 設定項目 ---
# whisper.cppのルートディレクトリ（このファイルがある場所）
WHISPER_CPP_PATH = os.path.dirname(os.path.abspath(__file__))
# 使用するWhisperモデル
WHISPER_MODEL = "tiny"
# 使用するマイクのインデックス番号
# ターミナルで`ffmpeg -f avfoundation -list_devices true -i ""`を実行して確認
# "MacBook Airのマイク" は [1] でした
AUDIO_DEVICE_INDEX = "1" 
# 一時保存する音声ファイル名
TEMP_AUDIO_FILE = "temp_recording.wav"
# 音声認識のための録音秒数
RECORDING_DURATION = 7 # 7秒に延長

# --- サービス開発に特化したプロンプトテンプレート ---
PROMPT_TEMPLATES = {
    'engineering': (
        "あなたは優秀なソフトウェアエンジニアです。"
        "以下の日本語の発話内容を解釈し、それを実現するための具体的な実装案をPythonまたはJavaScriptの疑似コードで示してください。"
        "発話内容:「{}」"
        "\n\n# 実装案"
    ),
    'spec': (
        "あなたは優秀なプロダクトマネージャーです。"
        "以下の日本語の発話内容から、ユーザーが求めている機能や要件を抽出し、箇条書きで明確な仕様書を作成してください。"
        "発話内容:「{}」"
        "\n\n# 要件定義書"
    ),
    'uiux': (
        "あなたは経験豊富なUI/UXデザイナーです。"
        "以下の日本語の発話内容で言及されている機能やアイデアについて、ユーザー体験を向上させるための具体的なUI/UX改善案を3つ提案してください。"
        "発話内容:「{}」"
        "\n\n# UI/UX改善提案"
    ),
    'db': (
        "あなたはデータベース設計の専門家です。"
        "以下の日本語の発話内容で示唆されているサービスや機能に必要なデータ構造を考え、テーブル定義（テーブル名、カラム名、データ型、制約）を設計してください。"
        "発話内容:「{}」"
        "\n\n# データベース設計"
    ),
    'raw': "{}" # 変換なし
}

# --- 状態管理 ---
current_mode = 'engineering'
is_processing = threading.Lock()
stop_program_event = threading.Event()
keyboard_controller = keyboard.Controller()

def set_mode(mode_name):
    """プロンプトの変換モードを切り替える"""
    global current_mode
    if mode_name in PROMPT_TEMPLATES:
        current_mode = mode_name
        print(f"\n✅ モード変更: '{current_mode}'")
        play_sound("success")

def play_sound(sound_type):
    """短い効果音を再生して状態を通知する"""
    # この機能はffplayに依存します。Homebrewで`brew install ffmpeg`をしていれば通常は入っています。
    try:
        if sound_type == "start": # 録音開始
            sound = AudioSegment.from_mono_audiosegments(AudioSegment.silent(duration=10), AudioSegment.sine(660, duration=100))
        elif sound_type == "processing": # 処理中
            sound = AudioSegment.from_mono_audiosegments(AudioSegment.silent(duration=10), AudioSegment.sine(440, duration=50), AudioSegment.silent(duration=50), AudioSegment.sine(440, duration=50))
        elif sound_type == "success": # 成功
            sound = AudioSegment.from_mono_audiosegments(AudioSegment.silent(duration=10), AudioSegment.sine(880, duration=150))
        else: # エラー
            sound = AudioSegment.from_mono_audiosegments(AudioSegment.silent(duration=10), AudioSegment.sine(220, duration=300))
        
        # 音の再生を別スレッドで行うことで、メインの処理をブロックしない
        threading.Thread(target=play, args=(sound,), daemon=True).start()
    except Exception as e:
        # 音が再生できなくてもプログラムは止まらないようにする
        # print(f"サウンド再生エラー: {e}")
        pass

def record_audio(duration, filename):
    """ffmpegを使って音声を録音する"""
    print(f"🎤 録音開始...（{duration}秒間）")
    play_sound("start")
    command = ["ffmpeg", "-f", "avfoundation", "-i", f":{AUDIO_DEVICE_INDEX}", "-y", "-t", str(duration), filename]
    try:
        # ffmpegの冗長な出力を非表示にする
        proc = subprocess.Popen(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        proc.wait()
        print("🧠 録音完了。文字起こしと整形を開始します...")
        play_sound("processing")
        return True
    except Exception:
        play_sound("error")
        print("❌ 録音エラーが発生しました。マイクの設定やffmpegのインストールを確認してください。")
        return False

def transcribe_audio(audio_file):
    """whisper.cppを使って音声をテキストに変換する"""
    whisper_executable = os.path.join(WHISPER_CPP_PATH, "build", "bin", "whisper-cli")
    model_path = os.path.join(WHISPER_CPP_PATH, "models", f"ggml-{WHISPER_MODEL}.bin")
    if not (os.path.exists(whisper_executable) and os.path.exists(model_path)):
        play_sound("error")
        print("❌ whisper.cppの実行ファイルまたはモデルが見つかりません。")
        return None
        
    command = [whisper_executable, "-m", model_path, "-f", audio_file, "-l", "ja", "-otxt", "--no-timestamps"]
    try:
        subprocess.run(command, check=True, capture_output=True, text=True, encoding='utf-8')
        with open(f"{audio_file}.txt", "r", encoding='utf-8') as f:
            return f.read().strip()
    except Exception:
        play_sound("error")
        print("❌ 文字起こし中にエラーが発生しました。")
        return None
    finally:
        # 一時ファイルを削除
        if os.path.exists(audio_file): os.remove(audio_file)
        if os.path.exists(f"{audio_file}.txt"): os.remove(f"{audio_file}.txt")

def process_voice_command():
    """録音から貼り付けまでの一連の流れを管理する"""
    if not is_processing.acquire(blocking=False):
        print("⚠️ 現在処理中です。完了までお待ちください。")
        return
    try:
        print("\n--- 音声コマンド起動 ---")
        if record_audio(RECORDING_DURATION, TEMP_AUDIO_FILE):
            recognized_text = transcribe_audio(TEMP_AUDIO_FILE)
            if recognized_text:
                print(f"🗣️  認識されたテキスト: 「{recognized_text}」")
                formatted_prompt = PROMPT_TEMPLATES[current_mode].format(recognized_text)
                
                pyperclip.copy(formatted_prompt)
                time.sleep(0.2)
                
                print("✨ テキストを貼り付けます！")
                with keyboard_controller.pressed(keyboard.Key.cmd):
                    keyboard_controller.press('v')
                    keyboard_controller.release('v')
                time.sleep(0.1)
                keyboard_controller.press(keyboard.Key.enter)
                keyboard_controller.release(keyboard.Key.enter)

                play_sound("success")
                print("✅ 処理完了")
            else:
                print("❌ 音声が認識できませんでした。")
    finally:
        is_processing.release()

def main():
    """ホットキーリスナーを起動し、プログラムのメインループを実行する"""
    print("🚀 VoiceDevAssistant 起動完了！")
    print(f"現在のモード: '{current_mode}'")
    print("\n--- ホットキー一覧 ---")
    print("▶︎ 音声入力開始:  'cmd+shift+v'")
    print("1️⃣ 実装案モード:   'cmd+shift+1'")
    print("2️⃣ 仕様書モード:   'cmd+shift+2'")
    print("3️⃣ UI/UXモード:    'cmd+shift+3'")
    print("4️⃣ DB設計モード:   'cmd+shift+4'")
    print("0️⃣ 変換なしモード: 'cmd+shift+0'")
    print("----------------------")
    print("\nプログラムを終了するには 'ESC' キーを押してください。")

    COMBINATIONS = {
        frozenset([keyboard.Key.cmd, keyboard.Key.shift, keyboard.KeyCode(char='v')]): process_voice_command,
        frozenset([keyboard.Key.cmd, keyboard.Key.shift, keyboard.KeyCode(char='1')]): lambda: set_mode('engineering'),
        frozenset([keyboard.Key.cmd, keyboard.Key.shift, keyboard.KeyCode(char='2')]): lambda: set_mode('spec'),
        frozenset([keyboard.Key.cmd, keyboard.Key.shift, keyboard.KeyCode(char='3')]): lambda: set_mode('uiux'),
        frozenset([keyboard.Key.cmd, keyboard.Key.shift, keyboard.KeyCode(char='4')]): lambda: set_mode('db'),
        frozenset([keyboard.Key.cmd, keyboard.Key.shift, keyboard.KeyCode(char='0')]): lambda: set_mode('raw'),
    }
    current_keys = set()

    def on_press(key):
        if key == keyboard.Key.esc:
            stop_program_event.set()
            return False # リスナーを停止
        
        current_keys.add(key)
        for combination, action in COMBINATIONS.items():
            if combination.issubset(current_keys):
                # 処理が重ならないように別スレッドで実行
                threading.Thread(target=action, daemon=True).start()
                break

    def on_release(key):
        try:
            current_keys.remove(key)
        except KeyError:
            pass

    with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
        listener.join()

if __name__ == '__main__':
    main()
