import pyautogui

print("--- Testing PyAutoGUI ---")
print("If this message appears, PyAutoGUI imported successfully.")

try:
    width, height = pyautogui.size()
    print(f"✅ Successfully fetched screen size: {width}x{height}")
except Exception as e:
    print(f"❌ Could not get screen size. Error: {e}")

print("--- Test complete ---")
