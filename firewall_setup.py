import pyautogui
import time

print("=== UFW Firewall Setup (Team 9) ===\n")
print("  1. Web Server     — ports: 22, 80, 443")
print("  2. Database       — ports: 22, 5432 (internal only)")
print("  3. DNS Server     — ports: 22, 53 tcp/udp")
print("  4. Backup Server  — ports: 22, 873 (internal only)")
print("  5. Shell/SMB      — ports: 22, 445, 139")

vm_type = input("\nSelect VM type (1-5): ").strip()

INTERNAL = "192.168.9.0/24"

def send_command(cmd, delay=1):
    pyautogui.typewrite(cmd, interval=0.05)
    pyautogui.press('enter')
    time.sleep(delay)

print("\n2 seconds to click the terminal...")
time.sleep(2)

# Base: reset and set defaults
send_command("sudo ufw --force reset", delay=3)
send_command("sudo ufw default deny incoming", delay=1)
send_command("sudo ufw default allow outgoing", delay=1)
send_command("sudo ufw allow 22/tcp", delay=1)

if vm_type == "1":
    send_command("sudo ufw allow 80/tcp", delay=1)
    send_command("sudo ufw allow 443/tcp", delay=1)

elif vm_type == "2":
    send_command(f"sudo ufw allow from {INTERNAL} to any port 5432 proto tcp", delay=1)

elif vm_type == "3":
    send_command("sudo ufw allow 53/tcp", delay=1)
    send_command("sudo ufw allow 53/udp", delay=1)

elif vm_type == "4":
    send_command(f"sudo ufw allow from {INTERNAL} to any port 873 proto tcp", delay=1)

elif vm_type == "5":
    send_command("sudo ufw allow 445/tcp", delay=1)
    send_command("sudo ufw allow 139/tcp", delay=1)

send_command("sudo ufw --force enable", delay=2)
send_command("sudo ufw status verbose", delay=2)

print("Done!")
