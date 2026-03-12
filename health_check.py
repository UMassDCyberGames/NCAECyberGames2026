import pyautogui
import time

print("=== Service Health Check (Team 9) ===\n")
print("  1. Web Server  (apache2)")
print("  2. Database    (postgresql)")
print("  3. DNS Server  (bind9/named)")
print("  4. Backup      (rsync/cron)")

vm_type = input("\nSelect VM type (1-4): ").strip()

def send_command(cmd, delay=1):
    pyautogui.typewrite(cmd, interval=0.05)
    pyautogui.press('enter')
    time.sleep(delay)

print("\n2 seconds to click the terminal...")
time.sleep(2)

# Common checks for all VMs
send_command("ip a", delay=1)
send_command("ip route", delay=1)
send_command("sudo ufw status", delay=1)

if vm_type == "1":
    send_command("sudo systemctl status apache2 --no-pager", delay=2)
    send_command("curl -s -o /dev/null -w 'HTTP status: %{http_code}' http://localhost", delay=2)
    send_command("ls -la /var/www/html", delay=1)

elif vm_type == "2":
    send_command("sudo systemctl status postgresql --no-pager", delay=2)
    send_command("sudo ss -tlnp | grep 5432", delay=1)
    send_command("sudo -u postgres psql -c '\\l'", delay=2)

elif vm_type == "3":
    send_command("sudo systemctl status named --no-pager", delay=2)
    send_command("sudo systemctl status bind9 --no-pager", delay=2)
    send_command("sudo ss -tlnp | grep 53", delay=1)
    send_command("dig @localhost google.com", delay=2)

elif vm_type == "4":
    send_command("crontab -l", delay=1)
    send_command("ls -la /backup", delay=1)
    send_command("df -h", delay=1)

print("Done!")
