import pyautogui
import time

print("=== Web Server Network Configuration ===\n")

# Gather inputs
iface    = input("Interface name [ens18]: ").strip() or "ens18"
ip_cidr  = input("IP with prefix [192.168.9.5/24]: ").strip() or "192.168.9.5/24"
gateway  = input("Default gateway [192.168.9.1]: ").strip() or "192.168.9.1"
dns      = input("DNS server [172.18.0.12]: ").strip() or "172.18.0.12"

def send_command(cmd, delay=1):
    pyautogui.typewrite(cmd, interval=0.05)
    pyautogui.press('enter')
    time.sleep(delay)

print("\n2 seconds to click the terminal...")
time.sleep(2)

# Remove old netplan configs
send_command("sudo rm /etc/netplan/*.yaml", delay=2)

# Write netplan config using tee
send_command("sudo tee /etc/netplan/00-netcfg.yaml > /dev/null << EOF", delay=1)
send_command("network:", delay=0.5)
send_command("  version: 2", delay=0.5)
send_command("  ethernets:", delay=0.5)
send_command(f"    {iface}:", delay=0.5)
send_command("      addresses:", delay=0.5)
send_command(f"        - {ip_cidr}", delay=0.5)
send_command("      routes:", delay=0.5)
send_command("        - to: default", delay=0.5)
send_command(f"          via: {gateway}", delay=0.5)
send_command("      nameservers:", delay=0.5)
send_command(f"        addresses: [{dns}]", delay=0.5)
send_command("EOF", delay=1)

# Set permissions
send_command("sudo chmod 600 /etc/netplan/00-netcfg.yaml", delay=2)

# Apply netplan - give it plenty of time
send_command("sudo netplan apply", delay=10)

# Verify
send_command(f"ip a show {iface}", delay=2)
send_command("ip route", delay=2)
send_command("sudo cat /etc/netplan/00-netcfg.yaml", delay=2)

print("All done!")
