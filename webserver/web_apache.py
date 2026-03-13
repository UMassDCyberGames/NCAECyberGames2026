import pyautogui
import time

def send_command(cmd, delay=1):
    pyautogui.typewrite(cmd, interval=0.02)
    pyautogui.press('enter')
    time.sleep(delay)

print("2 seconds to click the terminal...")
time.sleep(2)

# Enable and start Apache2
send_command("sudo systemctl enable apache2", delay=2)
send_command("sudo systemctl start apache2", delay=2)


# Allow HTTP through firewall (if ufw is active)
send_command("sudo ufw allow 80/tcp", delay=1)
send_command("sudo ufw allow 443/tcp", delay=1)

# Verify Apache is running and serving
send_command("sudo systemctl status apache2 --no-pager", delay=2)
send_command("curl -s -o /dev/null -w '%{http_code}' http://localhost", delay=2)

print("Apache setup done!")
