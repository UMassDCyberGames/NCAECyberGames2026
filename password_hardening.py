import pyautogui
import time

print("=== Password Hardening ===\n")
print("Note: avoid single quotes (') in passwords.\n")

users = []
while True:
    user = input("Username (or Enter to finish): ").strip()
    if not user:
        break
    pwd = input(f"  New password for '{user}': ").strip()
    users.append((user, pwd))

if not users:
    print("No users specified, exiting.")
    exit()

def send_command(cmd, delay=1):
    pyautogui.typewrite(cmd, interval=0.05)
    pyautogui.press('enter')
    time.sleep(delay)

print(f"\nWill change passwords for: {[u for u, _ in users]}")
print("2 seconds to click the terminal...")
time.sleep(2)

for user, pwd in users:
    send_command(f"echo '{user}:{pwd}' | sudo chpasswd", delay=2)

# Verify accounts exist
send_command("sudo cat /etc/passwd | grep -v nologin | grep -v false", delay=1)

print("Done!")
