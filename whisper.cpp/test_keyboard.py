# test_keyboard.py
import keyboard
import time
import os

def main():
    print("✅ Keyboard library imported successfully.")

    def my_callback():
        print("👍 Hotkey 'option+shift+t' pressed!")

    try:
        keyboard.add_hotkey('option+shift+t', my_callback)
        print("Hotkey set. Press 'option+shift+t' to test.")
        print("Press 'ESC' to quit.")
        keyboard.wait('esc')
        print("\nExiting.")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == '__main__':
    if os.geteuid() != 0:
        print("❌ This test must be run with sudo.")
    else:
        main()
