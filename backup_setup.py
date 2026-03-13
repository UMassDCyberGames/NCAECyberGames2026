import pyautogui
import time

print("=== Backup Server Setup (192.168.9.15) ===\n")
print("Sources to back up (one per line, empty to finish):")

sources = []
while True:
    src = input("  Source path (or Enter to stop): ").strip()
    if not src:
        break
    sources.append(src)

if not sources:
    sources = ["/var/www/html"]
    print(f"  No input, defaulting to: {sources}")

backup_dst = input("Backup destination [/backup]: ").strip() or "/backup"
interval   = input("Cron schedule [0 * * * *] (hourly): ").strip() or "0 * * * *"

def send_command(cmd, delay=1):
    pyautogui.typewrite(cmd, interval=0.02)
    pyautogui.press('enter')
    time.sleep(delay)

print(f"\nWill back up: {sources} -> {backup_dst}")
print("2 seconds to click the terminal...")
time.sleep(2)

# Install rsync
send_command("sudo apt-get install -y rsync", delay=10)

# Create backup directory structure
for src in sources:
    folder = src.replace("/", "_").strip("_")
    send_command(f"sudo mkdir -p {backup_dst}/{folder}", delay=1)
    # Do an initial sync
    send_command(f"sudo rsync -av {src}/ {backup_dst}/{folder}/", delay=5)

# Add cron jobs
for src in sources:
    folder = src.replace("/", "_").strip("_")
    cron_line = f"{interval} rsync -av {src}/ {backup_dst}/{folder}/"
    send_command(f"(crontab -l 2>/dev/null; echo \"{cron_line}\") | crontab -", delay=2)

# Verify
send_command("crontab -l", delay=1)
send_command(f"ls -la {backup_dst}", delay=1)

print("Done!")
