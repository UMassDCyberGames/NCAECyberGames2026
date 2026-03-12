import pyautogui
import time

print("=== MikroTik Router Configuration ===\n")

# Gather inputs
wan_ip      = input("WAN IP (ether1) with prefix [172.18.13.9/16]: ").strip() or "172.18.13.9/16"
lan_ip      = input("LAN IP (ether2) with prefix [192.168.9.1/24]: ").strip() or "192.168.9.1/24"
wan_iface   = input("WAN interface [ether1]: ").strip() or "ether1"
lan_iface   = input("LAN interface [ether2]: ").strip() or "ether2"
gateway     = input("Default gateway [172.18.0.1]: ").strip() or "172.18.0.1"
dns_servers = input("Upstream DNS servers [172.18.0.12]: ").strip() or "172.18.0.12"
router_name = input("Router identity name [Team9Router]: ").strip() or "Team9Router"
web_target  = input("HTTP/HTTPS DST-NAT target IP [192.168.9.5]: ").strip() or "192.168.9.5"
setup_dhcp  = input("Set up DHCP server for LAN? [y/N]: ").strip().lower() == "y"
if setup_dhcp:
    dhcp_pool = input("DHCP pool range [192.168.9.100-192.168.9.200]: ").strip() or "192.168.9.100-192.168.9.200"

# Derived values
wan_addr    = wan_ip.split("/")[0]
lan_addr    = lan_ip.split("/")[0]
lan_network = ".".join(lan_ip.split("/")[0].split(".")[:3]) + ".0"
lan_prefix  = lan_ip.split("/")[1]

commands = [
    # --- Interfaces ---
    f"/ip address add address={wan_ip} interface={wan_iface}",
    f"/ip address add address={lan_ip} interface={lan_iface}",

    # --- Default gateway ---
    f"/ip route add gateway={gateway}",

    # --- DNS: use upstream DNS, allow LAN clients to query this router ---
    f"/ip dns set servers={dns_servers} allow-remote-requests=yes",

    # --- NAT Masquerade (LAN -> WAN) ---
    f"/ip firewall nat add chain=srcnat src-address={lan_network}/{lan_prefix} action=masquerade out-interface={wan_iface}",

    # --- DST-NAT: forward HTTP/HTTPS from WAN to web server ---
    f"/ip firewall nat add chain=dstnat dst-address={wan_addr} protocol=tcp dst-port=80 action=dst-nat to-addresses={web_target} to-ports=80",
    f"/ip firewall nat add chain=dstnat dst-address={wan_addr} protocol=tcp dst-port=443 action=dst-nat to-addresses={web_target} to-ports=443",

    # --- Firewall: INPUT chain (protect the router itself) ---
    "/ip firewall filter add chain=input action=accept connection-state=established,related",
    f"/ip firewall filter add chain=input in-interface={lan_iface} action=accept",
    "/ip firewall filter add chain=input in-interface=lo action=accept",
    f"/ip firewall filter add chain=input in-interface={wan_iface} action=drop comment=block-wan-input",

    # --- Firewall: FORWARD chain ---
    "/ip firewall filter add chain=forward action=accept connection-state=established,related",
    f"/ip firewall filter add chain=forward src-address={lan_network}/{lan_prefix} action=accept",
    f"/ip firewall filter add chain=forward dst-address={lan_network}/{lan_prefix} action=accept",
    "/ip firewall filter add chain=forward action=drop comment=drop-all-else",

    # --- Identity ---
    f"/system identity set name={router_name}",
]

# --- Optional DHCP server ---
if setup_dhcp:
    commands += [
        f"/ip pool add name=lan-pool ranges={dhcp_pool}",
        f"/ip dhcp-server add name=lan-dhcp interface={lan_iface} address-pool=lan-pool disabled=no",
        f"/ip dhcp-server network add address={lan_network}/{lan_prefix} gateway={lan_addr} dns-server={lan_addr}",
    ]

print(f"\nYou have 3 seconds to click on the noVNC terminal...")
time.sleep(3)

for cmd in commands:
    pyautogui.typewrite(cmd, interval=0.02)
    pyautogui.press('enter')
    time.sleep(1)

print("All commands sent!")
