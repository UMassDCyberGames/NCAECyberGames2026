import pyautogui
import time

print("=== SSH Hardening ===\n")

new_port = input("SSH port [22]: ").strip() or "22"

def send_command(cmd, delay=1):
    pyautogui.typewrite(cmd, interval=0.02)
    pyautogui.press('enter')
    time.sleep(delay)

print(f"\nSSH port: {new_port}")
print("2 seconds to click the terminal...")
time.sleep(2)

# Backup original config
send_command("sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak", delay=1)

# Append hardening settings (later lines override earlier ones in sshd_config)
send_command("sudo tee -a /etc/ssh/sshd_config > /dev/null << EOF", delay=1)
send_command("", delay=0.3)
send_command("# == Competition Hardening ==", delay=0.3)
send_command(f"Port {new_port}", delay=0.3)
send_command("PermitRootLogin no", delay=0.3)
send_command("MaxAuthTries 3", delay=0.3)
send_command("LoginGraceTime 30", delay=0.3)
send_command("X11Forwarding no", delay=0.3)
send_command("EOF", delay=1)

# Test config before restarting
send_command("sudo sshd -t && echo CONFIG_OK", delay=2)
send_command("sudo systemctl restart ssh", delay=3)
send_command("sudo systemctl status ssh --no-pager", delay=2)

print("Done!")
