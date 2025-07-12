from pynput import keyboard

def on_press(key):
    print(f'Key {key} pressed')
    if key == keyboard.Key.esc:
        # Stop listener
        return False

print("--- Testing pynput ---")
print("If this runs, pynput is OK. Press a few keys.")
print("Press the 'ESC' key to exit.")

# Collect events until released
with keyboard.Listener(on_press=on_press) as listener:
    listener.join()

print("--- Test complete ---")
