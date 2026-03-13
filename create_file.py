import pyautogui
import time

print("=== Create File ===\n")

filepath = input("File path (e.g. /etc/myconfig.conf): ").strip()
print("Enter file content. Type END on a new line when done:")

lines = []
while True:
    line = input()
    if line == "END":
        break
    lines.append(line)

def send_command(cmd, delay=1):
    pyautogui.typewrite(cmd, interval=0.05)
    pyautogui.press('enter')
    time.sleep(delay)

print(f"\nFile: {filepath}")
print(f"Lines: {len(lines)}")
print("2 seconds to click the terminal...")
time.sleep(2)

send_command(f"sudo tee {filepath} > /dev/null << 'EOF'", delay=0.5)
for line in lines:
    send_command(line, delay=0.2)
send_command("EOF", delay=1)

send_command(f"cat {filepath}", delay=1)

print("Done!")
