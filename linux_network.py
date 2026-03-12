import pyautogui
import time

print("=== Linux VM Network Configuration (Team 9) ===\n")
print("Internal VMs: DB=192.168.9.7  DNS=192.168.9.12  Backup=192.168.9.15\n")

ip_cidr = input("IP with prefix, e.g. 192.168.9.7/24: ").strip()
iface   = input("Interface name [ens18]: ").strip() or "ens18"

# Fixed for Team 9
gateway = "192.168.9.1"
dns     = "172.18.0.12"

def send_command(cmd, delay=1):
    pyautogui.typewrite(cmd, interval=0.05)
    pyautogui.press('enter')
    time.sleep(delay)

print(f"\nConfig: {ip_cidr} | gw={gateway} | dns={dns}")
print("2 seconds to click the terminal...")
time.sleep(2)

send_command("sudo rm /etc/netplan/*.yaml", delay=2)
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
send_command("sudo chmod 600 /etc/netplan/00-netcfg.yaml", delay=2)
send_command("sudo netplan apply", delay=10)
send_command(f"ip a show {iface}", delay=2)
send_command("ip route", delay=2)

print("Done!")
