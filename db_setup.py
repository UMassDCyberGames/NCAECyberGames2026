import pyautogui
import time

print("=== PostgreSQL Setup (192.168.9.7) ===\n")

pg_password = input("Set postgres superuser password: ").strip()
db_name     = input("Competition DB name [compdb]: ").strip() or "compdb"
db_user     = input("Competition DB user [compuser]: ").strip() or "compuser"
db_pass     = input(f"Password for {db_user}: ").strip()

def send_command(cmd, delay=1):
    pyautogui.typewrite(cmd, interval=0.05)
    pyautogui.press('enter')
    time.sleep(delay)

print("\n2 seconds to click the terminal...")
time.sleep(2)

# Enable and start PostgreSQL
send_command("sudo systemctl enable postgresql", delay=2)
send_command("sudo systemctl start postgresql", delay=3)

# Set postgres superuser password
send_command(f"sudo -u postgres psql -c \"ALTER USER postgres PASSWORD '{pg_password}';\"", delay=2)

# Create competition DB and user
send_command(f"sudo -u postgres psql -c \"CREATE USER {db_user} WITH PASSWORD '{db_pass}';\"", delay=2)
send_command(f"sudo -u postgres psql -c \"CREATE DATABASE {db_name} OWNER {db_user};\"", delay=2)
send_command(f"sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE {db_name} TO {db_user};\"", delay=2)

# Verify
send_command("sudo systemctl status postgresql --no-pager", delay=2)
send_command("sudo ss -tlnp | grep 5432", delay=1)

print("Done!")
