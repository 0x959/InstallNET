#!/bin/bash

# License: GPL
## Debian network reinstaller.
## Supports Debian 6 - 14 (squeeze - forky).
## Default root password: a59~12 (override with -p/--password).

DEFAULT_PASSWORD='a59~12'

export tmpVER=''
export tmpDIST=''
export tmpURL=''
export tmpWORD=''
export tmpMirror=''
export ipAddr=''
export ipMask=''
export ipGate=''
export ipDNS=''
export ip6Addr=''
export ip6Mask=''
export ip6Gate=''
export ip6DNS=''
export ip6AddrFromUser='0'
export ipDNSAll=''
export NET_MODE='static'
export ip6Auto='0'
export SERVER_HOSTNAME=''
export SERVER_DOMAIN=''
export PRIMARY_FAMILY=''
export PRIMARY_IP=''
export PRIMARY_MASK=''
export PRIMARY_GATE=''
export IncDisk='default'
export interface=''
export interfaceSelect=''
export sshPORT='22'
export ddMode='0'
export setNet='0'
export setRDP='0'
export setIPv6='0'
export isMirror='0'
export loaderMode='0'
export IncFirmware='0'
export setInterfaceName='0'
export GRUBDIR=''
export GRUBFILE=''
export GRUBVER=''
export setConsole=''
export ARCH=''
export DIST=''
export SWAP_MB='0'
export SWAP_SPEC=''
export INSECURE='0'
export ASSUME_YES='0'
export DISK_OVERRIDE=''
export IMAGE_SHA256=''
export POST_INSTALL_CMD=''
export DRY_RUN='0'
export WinRemote=''

usage() {
  cat <<'EOF'
Usage:
  bash InstallNET.sh [options]

Debian version / architecture:
  -v, --ver <version>          Debian version or codename, default: 13 (trixie)
                               Examples: -v 13, -v trixie, -v 14, -v bookworm
      --arch <arch>            Architecture: amd64, arm64, i386, riscv64
                               Default: auto-detect
                               Note: Debian 13/14 do not provide i386 installers.

Network:
  -i, --interface <name>       Network interface used by the installer
      --hostname <name>        Hostname for the installed system
      --domain <domain>        Domain name for the installed system
      --ip-addr <ipv4>         Static IPv4 address
      --ip-mask <mask|prefix>  IPv4 netmask or prefix length
      --ip-gate <ipv4>         IPv4 default gateway
      --ip6-addr <ipv6>        Static IPv6 address (primary if no IPv4)
      --ip6-mask <prefix>      IPv6 prefix length, default: 64
      --ip6-gate <ipv6>        IPv6 default gateway
      --ip-dns <ip>            DNS server(s), IPv4 or IPv6
      --ip6-dns <ipv6>         Additional IPv6 DNS server(s)
      --dhcp                   Use DHCP for IPv4 and SLAAC/DHCPv6 for IPv6
                               (alias: --auto-net)
      --ip6-auto               Auto-configure IPv6 (SLAAC/DHCPv6) while IPv4 may be static
                               (aliases: --dhcp6, --ipv6-auto)
      --dev-net                Disable predictable interface names during installation
      --noipv6                 Disable IPv6 during installation and target IPv6 config

Debian installer:
  -p, --password <password>    Override the default root password
      --password-stdin         Read root password from stdin
      --mirror <url>           Use a custom Debian mirror (aliases: -apt, -yum)
      -firmware                Include non-free firmware
      -port <port>             SSH port, default: 22
  -console <console>           Kernel console option, e.g. ttyS0,115200n8
      --swap <size>            Create an exact-size swap partition
                               Examples: --swap 512M, --swap 2G, --swap 2048
      --disk <device>          Target whole disk, e.g. /dev/sda
      --yes                    Skip all interactive prompts and disk confirmation
      --post-install-cmd <cmd> Run one command once after the first boot
      --dry-run                Generate and print configuration, do not modify /boot or GRUB
      --insecure               Allow HTTP mirrors and disable TLS/signature verification
                               (required for some EOL Debian releases)

Raw image mode:
  -dd, --image <url>           Download a gzipped image and write it directly to disk
      --image-sha256 <hash>    Verify the downloaded image SHA-256
  -rdp <port>                  Enable RDP on the installed Windows image (TCP only, NLA kept)

Loader mode:
      --loader                 Do not modify GRUB; put kernel/initrd in ~/loader

Compatibility (accepted and ignored):
  -a, --auto
  -m, --manual
  -ssl

Other:
  -h, --help                   Show this help

Examples:
  bash InstallNET.sh -v 13 --arch amd64 -p 'MyPassword' --swap 2G
  bash InstallNET.sh -v 12 --disk /dev/vda --yes --swap 1G
  bash InstallNET.sh -v 13 --firmware --mirror https://deb.debian.org/debian
  bash InstallNET.sh -v 13 --dhcp -p 'MyPassword' --swap 2G
  bash InstallNET.sh -v 13 --ip-addr 203.0.113.10 --ip-mask 24 --ip-gate 203.0.113.1 --ip6-auto
  bash InstallNET.sh -v 13 --dry-run --swap 2G
  bash InstallNET.sh -dd 'https://example.com/windows.img.gz' --image-sha256 '<sha256>'

Removed options:
  -d/--debian, -u/--ubuntu, -c/--centos are no longer supported.
  Use -v <version> instead.
EOF
}

die() {
  printf '\033[31mError: \033[0m%s\n' "$*" >&2
  exit 1
}

warn() {
  printf '\033[33mWarning: \033[0m%s\n' "$*" >&2
}

while [ $# -ge 1 ]; do
  case "$1" in
    -v|--ver)
      [ $# -ge 2 ] || die "Missing value for $1"
      tmpVER="$2"
      shift 2
      ;;
    --arch)
      [ $# -ge 2 ] || die "Missing value for $1"
      ARCH="$2"
      shift 2
      ;;
    -dd|--image)
      [ $# -ge 2 ] || die "Missing value for $1"
      ddMode='1'
      tmpURL="$2"
      shift 2
      ;;
    -p|--password)
      [ $# -ge 2 ] || die "Missing value for $1"
      tmpWORD="$2"
      shift 2
      ;;
    --password-stdin)
      IFS= read -r tmpWORD || true
      shift
      ;;
    -i|--interface)
      [ $# -ge 2 ] || die "Missing value for $1"
      interfaceSelect="$2"
      shift 2
      ;;
    --ip-addr)
      [ $# -ge 2 ] || die "Missing value for $1"
      ipAddr="$2"
      shift 2
      ;;
    --ip-mask)
      [ $# -ge 2 ] || die "Missing value for $1"
      ipMask="$2"
      shift 2
      ;;
    --ip-gate)
      [ $# -ge 2 ] || die "Missing value for $1"
      ipGate="$2"
      shift 2
      ;;
    --ip-dns)
      [ $# -ge 2 ] || die "Missing value for $1"
      ipDNS="$2"
      shift 2
      ;;
    --ip6-addr)
      [ $# -ge 2 ] || die "Missing value for $1"
      ip6Addr="$2"
      ip6AddrFromUser='1'
      shift 2
      ;;
    --ip6-mask)
      [ $# -ge 2 ] || die "Missing value for $1"
      ip6Mask="$2"
      shift 2
      ;;
    --ip6-gate)
      [ $# -ge 2 ] || die "Missing value for $1"
      ip6Gate="$2"
      shift 2
      ;;
    --ip6-dns)
      [ $# -ge 2 ] || die "Missing value for $1"
      ip6DNS="$2"
      shift 2
      ;;
    --hostname)
      [ $# -ge 2 ] || die "Missing value for $1"
      SERVER_HOSTNAME="$2"
      shift 2
      ;;
    --domain)
      [ $# -ge 2 ] || die "Missing value for $1"
      SERVER_DOMAIN="$2"
      shift 2
      ;;
    --dhcp|--auto-net)
      NET_MODE='dhcp'
      shift
      ;;
    --ip6-auto|--dhcp6|--ipv6-auto)
      ip6Auto='1'
      shift
      ;;
    --dev-net)
      setInterfaceName='1'
      shift
      ;;
    --loader)
      loaderMode='1'
      shift
      ;;
    -apt|-yum|--mirror)
      [ $# -ge 2 ] || die "Missing value for $1"
      isMirror='1'
      tmpMirror="$2"
      shift 2
      ;;
    -rdp)
      [ $# -ge 2 ] || die "Missing value for $1"
      setRDP='1'
      WinRemote="$2"
      shift 2
      ;;
    -console)
      [ $# -ge 2 ] || die "Missing value for $1"
      setConsole="$2"
      shift 2
      ;;
    -firmware)
      IncFirmware='1'
      shift
      ;;
    -port)
      [ $# -ge 2 ] || die "Missing value for $1"
      sshPORT="$2"
      shift 2
      ;;
    --noipv6)
      setIPv6='1'
      shift
      ;;
    --swap)
      [ $# -ge 2 ] || die "Missing value for $1"
      SWAP_SPEC="$2"
      shift 2
      ;;
    --disk)
      [ $# -ge 2 ] || die "Missing value for $1"
      DISK_OVERRIDE="$2"
      shift 2
      ;;
    --yes)
      ASSUME_YES='1'
      shift
      ;;
    --insecure)
      INSECURE='1'
      shift
      ;;
    --image-sha256)
      [ $# -ge 2 ] || die "Missing value for $1"
      IMAGE_SHA256="$2"
      shift 2
      ;;
    --post-install-cmd)
      [ $# -ge 2 ] || die "Missing value for $1"
      POST_INSTALL_CMD="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN='1'
      shift
      ;;
    -a|--auto|-m|--manual|-ssl)
      shift
      ;;
    -d|--debian|-u|--ubuntu|-c|--centos)
      die "$1 has been removed. This script now supports Debian only. Use: bash $0 -v 13 --arch amd64"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf '\nInvalid option: %s\n\n' "$1" >&2
      usage
      exit 1
      ;;
  esac
done

[ "$(id -u)" -eq 0 ] || die "This script must be run as root."

# Basic validators -----------------------------------------------------------

is_ipv4() {
  local ip="$1" o1 o2 o3 o4 o
  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  IFS='.' read -r o1 o2 o3 o4 <<< "$ip"
  for o in "$o1" "$o2" "$o3" "$o4"; do
    [ "$o" -ge 0 ] 2>/dev/null && [ "$o" -le 255 ] 2>/dev/null || return 1
  done
  return 0
}

is_ipv4_list() {
  local ip
  [ -n "$1" ] || return 1
  for ip in $1; do
    is_ipv4 "$ip" || return 1
  done
  return 0
}

is_ipv6() {
  local ip="$1"
  [[ "$ip" =~ ^[0-9A-Fa-f:.]+$ ]] || return 1
  [[ "$ip" == *:* ]] || return 1
  return 0
}

is_ipv6_prefix() {
  [[ "$1" =~ ^[0-9]{1,3}$ ]] || return 1
  [ "$1" -ge 0 ] 2>/dev/null && [ "$1" -le 128 ] 2>/dev/null
}

is_ip_or_ipv6() {
  is_ipv4 "$1" && return 0
  is_ipv6 "$1"
}

is_dns_list() {
  local ip
  [ -n "$1" ] || return 1
  for ip in $1; do
    is_ip_or_ipv6 "$ip" || return 1
  done
  return 0
}

is_hostname() {
  local h="$1"
  [ ${#h} -le 63 ] || return 1
  [[ "$h" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$ ]]
}

is_domain() {
  local d="$1"
  [ ${#d} -le 253 ] || return 1
  [[ "$d" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ ]]
}

is_port() {
  [[ "$1" =~ ^[0-9]{1,5}$ ]] || return 1
  [ "$1" -ge 1 ] 2>/dev/null && [ "$1" -le 65535 ] 2>/dev/null
}

is_sha256() {
  [[ "$1" =~ ^[0-9a-fA-F]{64}$ ]]
}

is_url() {
  local u="$1"
  case "$u" in
    *[[:space:]\'\"\<\>\\]*) return 1 ;;
  esac
  if [ "$INSECURE" = '1' ]; then
    [[ "$u" == http://* || "$u" == https://* || "$u" == ftp://* ]]
  else
    [[ "$u" == https://* ]]
  fi
}

normalize_mask() {
  local m="$1"
  m="${m#/}"
  if [[ "$m" =~ ^[0-9]{1,2}$ ]] && [ "$m" -le 32 ]; then
    netmask "$m"
  else
    is_ipv4 "$m" && echo "$m"
  fi
}

netmask() {
  local n="${1:-32}" b='' m='' i s
  for ((i=0;i<32;i++)); do
    if [ "$i" -lt "$n" ]; then b="${b}1"; else b="${b}0"; fi
  done
  for ((i=0;i<4;i++)); do
    s="$(echo "$b" | cut -c$((i*8+1))-$(((i+1)*8)))"
    if [ -z "$m" ]; then
      m="$((2#$s))"
    else
      m="${m}.$((2#$s))"
    fi
  done
  echo "$m"
}

prefix6_to_mask() {
  local p="$1" i rem hex out=''
  for ((i=0;i<8;i++)); do
    if [ "$p" -ge $(((i+1)*16)) ]; then
      hex='ffff'
    elif [ "$p" -le $((i*16)) ]; then
      hex='0000'
    else
      rem=$((p - i*16))
      hex="$(printf '%04x' $(( (0xffff << (16-rem)) & 0xffff )))"
    fi
    if [ -z "$out" ]; then
      out="$hex"
    else
      out="$out:$hex"
    fi
  done
  echo "$out"
}

normalize_arch() {
  local a
  a="$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"
  case "$a" in
    amd64|x86_64|x64|64) echo 'amd64' ;;
    i386|i486|i586|i686|x86|32) echo 'i386' ;;
    arm64|aarch64) echo 'arm64' ;;
    riscv64) echo 'riscv64' ;;
    *) echo '' ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo 'amd64' ;;
    i386|i486|i586|i686|x86) echo 'i386' ;;
    aarch64|arm64) echo 'arm64' ;;
    riscv64) echo 'riscv64' ;;
    *) echo '' ;;
  esac
}

normalize_dist() {
  local d
  d="$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"
  case "$d" in
    6|6.*|squeeze) echo 'squeeze' ;;
    7|7.*|wheezy) echo 'wheezy' ;;
    8|8.*|jessie) echo 'jessie' ;;
    9|9.*|stretch) echo 'stretch' ;;
    10|10.*|buster) echo 'buster' ;;
    11|11.*|bullseye) echo 'bullseye' ;;
    12|12.*|bookworm) echo 'bookworm' ;;
    13|13.*|trixie) echo 'trixie' ;;
    14|14.*|forky) echo 'forky' ;;
    *) echo '' ;;
  esac
}

parse_swap_size() {
  local s="$1" num unit
  if [[ "$s" =~ ^([0-9]+)([MmGg]?)$ ]]; then
    num="${BASH_REMATCH[1]}"
    unit="$(echo "${BASH_REMATCH[2]}" | tr '[:upper:]' '[:lower:]')"
  else
    return 1
  fi
  num="$((10#$num))"
  [ "$num" -gt 0 ] 2>/dev/null || return 1
  case "$unit" in
    g) SWAP_MB=$((num * 1024)) ;;
    m|'') SWAP_MB="$num" ;;
    *) return 1 ;;
  esac
  [ "$SWAP_MB" -ge 64 ] || return 1
  return 0
}

is_uefi() {
  [ -d /sys/firmware/efi ]
}

# Dependencies ---------------------------------------------------------------

require_cmds() {
  local list="$1" c missing=0
  for c in $(echo "$list" | tr ',' ' '); do
    [ -n "$c" ] || continue
    if command -v "$c" >/dev/null 2>&1; then
      printf '[\033[32mok\033[0m]\t%s\n' "$c"
    else
      printf '[\033[31mMISSING\033[0m]\t%s\n' "$c"
      missing=1
    fi
  done
  [ "$missing" -eq 0 ] || die "Missing commands. Install them first (for example: apt-get install wget cpio gzip openssl)."
}

# Networking helpers ---------------------------------------------------------

getInterface() {
  local Interfaces defaultRoute item
  Interfaces="$(cat /proc/net/dev | grep ':' | cut -d':' -f1 | sed 's/[[:space:]]//g' | grep -ivE '^(lo|sit|stf|gif|dummy|vmnet|vir|gre|ipip|ppp|bond|tun|tap|ip6gre|ip6tnl|teql|ocserv|vpn)')"
  defaultRoute="$(ip route show default 2>/dev/null | grep '^default')"
  for item in $Interfaces; do
    [ -n "$item" ] || continue
    if echo "$defaultRoute" | grep -q "$item"; then
      echo "$item"
      return 0
    fi
  done
  echo ""
}

# Host and network detection -------------------------------------------------

detect_hostname() {
  local raw auto_host auto_domain
  raw="$(cat /proc/sys/kernel/hostname 2>/dev/null || hostname 2>/dev/null || true)"
  [ -n "$raw" ] || raw='debian'
  case "$raw" in
    *.*)
      auto_host="${raw%%.*}"
      auto_domain="${raw#*.}"
      ;;
    *)
      auto_host="$raw"
      auto_domain="$(dnsdomainname 2>/dev/null || true)"
      case "$auto_domain" in
        '(none)') auto_domain='' ;;
      esac
      ;;
  esac
  [ -n "$auto_host" ] || auto_host='debian'
  [ -n "$auto_domain" ] || auto_domain='localdomain'
  is_hostname "$auto_host" || auto_host='debian'
  is_domain "$auto_domain" || auto_domain='localdomain'
  [ -n "$SERVER_HOSTNAME" ] || SERVER_HOSTNAME="$auto_host"
  [ -n "$SERVER_DOMAIN" ] || SERVER_DOMAIN="$auto_domain"
}

detect_dns() {
  local d
  d="$(awk '$1 == "nameserver" {print $2}' /etc/resolv.conf 2>/dev/null | grep -vE '^(127\.|169\.254\.|::1$|fe80:)' | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
  [ -n "$d" ] || d='8.8.8.8'
  echo "$d"
}

detect_ipv6() {
  local i6
  if [ -z "$ip6Addr" ]; then
    i6="$(ip -6 addr show dev "$interface" scope global 2>/dev/null | grep 'inet6 ' | head -n1 | awk '{print $2}')"
    if [ -n "$i6" ]; then
      ip6Addr="${i6%/*}"
      [ -n "$ip6Mask" ] || ip6Mask="${i6##*/}"
    fi
  fi
  if [ -z "$ip6Gate" ]; then
    ip6Gate="$(ip -6 route show default 2>/dev/null | awk '/^default/{for(i=1;i<=NF;i++) if($i=="via"){print $(i+1); exit}}')"
  fi
}

# Validation -----------------------------------------------------------------

validate_hostname_settings() {
  [ -n "$SERVER_DOMAIN" ] || SERVER_DOMAIN='localdomain'
  is_hostname "$SERVER_HOSTNAME" || {
    printf 'Invalid hostname: %s\n' "$SERVER_HOSTNAME" >&2
    return 1
  }
  is_domain "$SERVER_DOMAIN" || {
    printf 'Invalid domain: %s\n' "$SERVER_DOMAIN" >&2
    return 1
  }
  return 0
}

validate_ipv4_settings() {
  local m
  if [ -n "$ipAddr" ] || [ -n "$ipMask" ] || [ -n "$ipGate" ]; then
    [ -n "$ipAddr" ] && [ -n "$ipMask" ] && [ -n "$ipGate" ] || {
      printf 'IPv4 address, netmask and gateway must be provided together.\n' >&2
      return 1
    }
    is_ipv4 "$ipAddr" || {
      printf 'Invalid IPv4 address: %s\n' "$ipAddr" >&2
      return 1
    }
    m="$(normalize_mask "$ipMask")" || {
      printf 'Invalid IPv4 netmask: %s\n' "$ipMask" >&2
      return 1
    }
    ipMask="$m"
    is_ipv4 "$ipGate" || {
      printf 'Invalid IPv4 gateway: %s\n' "$ipGate" >&2
      return 1
    }
  fi
  return 0
}

validate_ipv6_settings() {
  if [ "$setIPv6" = '1' ] && [ "$ip6AddrFromUser" = '1' ] && [ -n "$ip6Addr" ]; then
    printf -- '--noipv6 conflicts with --ip6-addr/--ip6-gate/--ip6-mask.\n' >&2
    return 1
  fi
  if [ "$setIPv6" = '1' ]; then
    ip6Addr=''
    ip6Mask=''
    ip6Gate=''
    ip6DNS=''
    return 0
  fi
  if [ -n "$ip6Addr" ]; then
    is_ipv6 "$ip6Addr" || {
      printf 'Invalid IPv6 address: %s\n' "$ip6Addr" >&2
      return 1
    }
    [ -n "$ip6Mask" ] || ip6Mask='64'
    is_ipv6_prefix "$ip6Mask" || {
      printf 'Invalid IPv6 prefix: %s (use 0-128)\n' "$ip6Mask" >&2
      return 1
    }
    if [ -n "$ip6Gate" ]; then
      is_ipv6 "$ip6Gate" || {
        printf 'Invalid IPv6 gateway: %s\n' "$ip6Gate" >&2
        return 1
      }
    fi
  elif [ -n "$ip6Mask" ] || [ -n "$ip6Gate" ]; then
    printf 'IPv6 prefix/gateway require an IPv6 address.\n' >&2
    return 1
  fi
  return 0
}

validate_dns_settings() {
  local d
  if [ -z "$ipDNS" ] && [ -z "$ip6DNS" ]; then
    ipDNS="$(detect_dns)"
  fi
  if [ -z "$ipDNS" ] && [ -z "$ip6DNS" ]; then
    if [ -z "$ipAddr" ] && [ -n "$ip6Addr" ]; then
      ipDNS='2606:4700:4700::1111'
    else
      ipDNS='8.8.8.8'
    fi
  fi
  ipDNSAll="$ipDNS"
  [ -n "$ip6DNS" ] && ipDNSAll="$ipDNSAll $ip6DNS"
  ipDNSAll="$(echo "$ipDNSAll" | sed 's/^ *//;s/  */ /g;s/ *$//')"
  is_dns_list "$ipDNSAll" || {
    printf 'Invalid DNS server list: %s\n' "$ipDNSAll" >&2
    return 1
  }
  ipDNSFirst=''
  for d in $ipDNSAll; do
    if is_ipv4 "$d"; then
      ipDNSFirst="$d"
      break
    fi
  done
  [ -n "$ipDNSFirst" ] || ipDNSFirst='8.8.8.8'
  return 0
}

validate_network_settings() {
  [ -n "$interfaceSelect" ] || interfaceSelect='auto'
  if [ "$interfaceSelect" != 'auto' ] && [[ ! "$interfaceSelect" =~ ^[A-Za-z0-9_.:-]+$ ]]; then
    printf 'Invalid interface name: %s\n' "$interfaceSelect" >&2
    return 1
  fi
  validate_hostname_settings || return 1

  if [ "$NET_MODE" = 'dhcp' ]; then
    ipDNSAll='auto (DHCP)'
    PRIMARY_FAMILY='auto'
    PRIMARY_IP=''
    PRIMARY_MASK=''
    PRIMARY_GATE=''
    return 0
  fi

  if [ "$ip6Auto" = '1' ]; then
    validate_ipv4_settings || return 1
    validate_dns_settings || return 1
    [ -n "$ipAddr" ] || {
      printf 'IPv6 auto mode requires a static IPv4 address for the installer.\n' >&2
      return 1
    }
    PRIMARY_FAMILY='4'
    PRIMARY_IP="$ipAddr"
    PRIMARY_MASK="$ipMask"
    PRIMARY_GATE="$ipGate"
    return 0
  fi

  validate_ipv4_settings || return 1
  validate_ipv6_settings || return 1
  validate_dns_settings || return 1

  if [ -n "$ipAddr" ]; then
    PRIMARY_FAMILY='4'
    PRIMARY_IP="$ipAddr"
    PRIMARY_MASK="$ipMask"
    PRIMARY_GATE="$ipGate"
  elif [ -n "$ip6Addr" ]; then
    PRIMARY_FAMILY='6'
    PRIMARY_IP="$ip6Addr"
    PRIMARY_MASK="$(prefix6_to_mask "$ip6Mask")"
    PRIMARY_GATE="$ip6Gate"
    [ -n "$PRIMARY_GATE" ] || {
      printf 'IPv6-only installation requires an IPv6 gateway.\n' >&2
      return 1
    }
  else
    printf 'No usable IPv4 or IPv6 address was found or configured.\n' >&2
    return 1
  fi
  return 0
}

validate_disk_settings() {
  [ -b "$IncDisk" ] || {
    printf 'Target is not a block device: %s\n' "$IncDisk" >&2
    return 1
  }
  [[ "$IncDisk" =~ ^/dev/[A-Za-z0-9._/-]+$ ]] || {
    printf 'Invalid disk path: %s\n' "$IncDisk" >&2
    return 1
  }
  DiskType="$(lsblk -d -n -r -o TYPE "$IncDisk" 2>/dev/null | head -n1)"
  if [ -n "$DiskType" ] && [ "$DiskType" != 'disk' ]; then
    printf '%s is not a whole disk (type: %s).\n' "$IncDisk" "$DiskType" >&2
    return 1
  fi
  DiskMB="$(disk_size_mb "$IncDisk")"
  [ -n "$DiskMB" ] && [ "$DiskMB" -gt 0 ] || {
    printf 'Unable to read disk size for %s.\n' "$IncDisk" >&2
    return 1
  }
  if [ "$SWAP_MB" -gt 0 ]; then
    NeedMB=$((SWAP_MB + 2048 + 512 + 256))
    is_uefi && NeedMB=$((NeedMB + 512))
    [ "$DiskMB" -ge "$NeedMB" ] || {
      printf 'Disk %s is too small: %sMB available, %sMB required for swap %sMB + system.\n' "$IncDisk" "$DiskMB" "$NeedMB" "$SWAP_MB" >&2
      return 1
    }
  fi
  return 0
}

# Interactive review ---------------------------------------------------------

print_summary() {
  local swap_desc
  printf '\n\033[36m# Installation summary\033[0m\n'
  printf '  Debian:        %s (%s)\n' "$DIST" "$ARCH"
  printf '  Target disk:   %s (%s MB)\n' "$IncDisk" "$DiskMB"
  printf '  Hostname:      %s\n' "$SERVER_HOSTNAME"
  printf '  Domain:        %s\n' "$SERVER_DOMAIN"
  if [ "$interfaceSelect" = 'auto' ] && [ -n "$interface" ]; then
    printf '  Interface:     auto (detected: %s)\n' "$interface"
  else
    printf '  Interface:     %s\n' "$interfaceSelect"
  fi
  if [ "$NET_MODE" = 'dhcp' ]; then
    printf '  IPv4:          auto (DHCP)\n'
    if [ "$setIPv6" = '1' ]; then
      printf '  IPv6:          disabled\n'
    else
      printf '  IPv6:          auto (SLAAC/DHCPv6)\n'
    fi
    printf '  DNS:           auto (DHCP)\n'
    printf '  Primary net:   auto\n'
  else
    if [ -n "$ipAddr" ]; then
      printf '  IPv4:          %s\n' "$ipAddr"
      printf '  IPv4 netmask:  %s\n' "$ipMask"
      printf '  IPv4 gateway:  %s\n' "$ipGate"
    else
      printf '  IPv4:          disabled\n'
    fi
    if [ "$ip6Auto" = '1' ]; then
      printf '  IPv6:          auto (SLAAC/DHCPv6)\n'
    elif [ -n "$ip6Addr" ]; then
      printf '  IPv6:          %s/%s\n' "$ip6Addr" "$ip6Mask"
      printf '  IPv6 gateway:  %s\n' "${ip6Gate:-n/a}"
    else
      printf '  IPv6:          disabled\n'
    fi
    printf '  DNS:           %s\n' "${ipDNSAll:-n/a}"
    printf '  Primary net:   IPv%s\n' "$PRIMARY_FAMILY"
    if [ "$loaderMode" = '1' ] && [ "$setNet" = '0' ]; then
      printf '  Network mode:  DHCP (loader mode, detected values are not forced)\n'
    fi
  fi
  printf '  Root password: %s\n' "$([ -n "$tmpWORD" ] && echo custom || echo "default ($DEFAULT_PASSWORD)")"
  if [ "$SWAP_MB" -gt 0 ]; then
    swap_desc="${SWAP_MB} MB (exact partition)"
  else
    swap_desc='Debian atomic default'
  fi
  printf '  Swap:          %s\n' "$swap_desc"
  printf '  Mirror:        %s\n' "${tmpMirror:-auto}"
  printf '  Firmware:      %s\n' "$([ "$IncFirmware" = '1' ] && echo yes || echo no)"
  printf '  DD image:      %s\n' "$([ "$ddMode" = '1' ] && echo yes || echo no)"
  printf '  Loader mode:   %s\n' "$([ "$loaderMode" = '1' ] && echo yes || echo no)"
  printf '  Insecure:      %s\n' "$([ "$INSECURE" = '1' ] && echo yes || echo no)"
  printf '  Post-install:  %s\n' "$([ -n "$POST_INSTALL_CMD" ] && echo yes || echo no)"
  printf '\n\033[31mALL DATA ON %s WILL BE DESTROYED.\033[0m\n' "$IncDisk"
}

read_password() {
  local p1 p2
  while :; do
    printf 'New root password: '
    IFS= read -r -s p1
    printf '\n'
    printf 'Repeat root password: '
    IFS= read -r -s p2
    printf '\n'
    if [ -z "$p1" ]; then
      printf 'Password cannot be empty.\n'
      continue
    fi
    if [ "$p1" != "$p2" ]; then
      printf 'Passwords do not match.\n'
      continue
    fi
    tmpWORD="$p1"
    return 0
  done
}

prompt_password() {
  local ans
  [ "$ASSUME_YES" = '1' ] && return 0
  [ -n "$tmpWORD" ] && return 0
  [ -t 0 ] || return 0
  printf '\nDefault root password: \033[33m%s\033[0m\n' "$DEFAULT_PASSWORD"
  printf 'Change the root password before installation? [y/N] '
  read -r ans
  case "$ans" in
    y|Y|yes|YES) read_password ;;
  esac
}

prompt_settings() {
  local ans v
  if [ "$ASSUME_YES" = '1' ]; then
    print_summary
    return 0
  fi
  if [ ! -t 0 ]; then
    print_summary
    warn "No interactive terminal detected; proceeding with auto-detected/default settings."
    [ "$DRY_RUN" = '1' ] || sleep 5
    return 0
  fi

  print_summary
  printf '\nProceed with these settings? [Y/n] '
  read -r ans
  case "$ans" in
    n|N|no|NO) ;;
    *) return 0 ;;
  esac

  while :; do
    if [ "$NET_MODE" = 'dhcp' ] || [ "$ip6Auto" = '1' ]; then
      printf '\n\033[36m# Edit settings (Enter keeps current value)\033[0m\n'
    else
      printf '\n\033[36m# Edit settings (Enter keeps current value, "-" disables IPv4/IPv6)\033[0m\n'
    fi
    printf 'Hostname [%s]: ' "$SERVER_HOSTNAME"
    read -r v
    [ -n "$v" ] && SERVER_HOSTNAME="$v"

    printf 'Domain [%s]: ' "$SERVER_DOMAIN"
    read -r v
    [ -n "$v" ] && SERVER_DOMAIN="$v"

    printf 'Interface [%s]: ' "$interfaceSelect"
    read -r v
    if [ -n "$v" ]; then
      interfaceSelect="$v"
      [ "$v" != 'auto' ] && interface="$v"
    fi

    if [ "$NET_MODE" = 'dhcp' ]; then
      printf 'Network mode: auto (DHCP/SLAAC); rerun without --dhcp for static IPs\n'
    else
    printf 'IPv4 address [%s]: ' "${ipAddr:-disabled}"
    read -r v
    case "$v" in
      -) ipAddr=''; ipMask=''; ipGate='' ;;
      '') ;;
      *) ipAddr="$v"; setNet='1' ;;
    esac
    if [ -n "$ipAddr" ]; then
      printf 'IPv4 netmask/prefix [%s]: ' "${ipMask:-255.255.255.0}"
      read -r v
      [ -n "$v" ] && { ipMask="$v"; setNet='1'; }
      printf 'IPv4 gateway [%s]: ' "${ipGate:-none}"
      read -r v
      [ -n "$v" ] && { ipGate="$v"; setNet='1'; }
    fi

    if [ "$ip6Auto" = '1' ]; then
      printf 'IPv6: auto (SLAAC/DHCPv6)\n'
    elif [ "$setIPv6" != '1' ]; then
      printf 'IPv6 address [%s]: ' "${ip6Addr:-disabled}"
      read -r v
      case "$v" in
        -) ip6Addr=''; ip6Mask=''; ip6Gate='' ;;
        '') ;;
        *) ip6Addr="$v"; setNet='1' ;;
      esac
      if [ -n "$ip6Addr" ]; then
        printf 'IPv6 prefix [%s]: ' "${ip6Mask:-64}"
        read -r v
        [ -n "$v" ] && { ip6Mask="$v"; setNet='1'; }
        printf 'IPv6 gateway [%s]: ' "${ip6Gate:-none}"
        read -r v
        [ -n "$v" ] && { ip6Gate="$v"; setNet='1'; }
      fi
    fi

    printf 'DNS servers (space separated) [%s]: ' "${ipDNSAll:-auto}"
    read -r v
    case "$v" in
      -) ipDNS=''; ip6DNS='' ;;
      '') ;;
      *) ipDNS="$v"; ip6DNS='' ;;
    esac

    fi

    printf 'Swap size (e.g. 2G, 0/none = default) [%s]: ' "$([ "$SWAP_MB" -gt 0 ] && echo "${SWAP_MB}M" || echo default)"
    read -r v
    if [ -n "$v" ]; then
      if [ "$v" = '0' ] || [ "$v" = 'none' ]; then
        SWAP_MB='0'
      else
        parse_swap_size "$v" || {
          printf 'Invalid swap size: %s\n' "$v"
          continue
        }
      fi
    fi

    printf 'Target disk [%s]: ' "$IncDisk"
    read -r v
    if [ -n "$v" ]; then
      IncDisk="$v"
      DISK_OVERRIDE="$v"
    fi

    if ! validate_network_settings; then
      continue
    fi
    if ! validate_disk_settings; then
      continue
    fi

    if [ -z "$tmpWORD" ]; then
      printf 'Change root password? [y/N] '
      read -r ans
      case "$ans" in y|Y|yes|YES) read_password ;; esac
    fi

    print_summary
    printf '\nProceed with these settings? [Y/n] '
    read -r ans
    case "$ans" in
      n|N|no|NO) continue ;;
      *) return 0 ;;
    esac
  done
}

# Disk helpers ---------------------------------------------------------------

getDisk() {
  local d
  d="$(lsblk -d -p -n -o NAME,TYPE,RM 2>/dev/null | awk '$2=="disk" && $3==0 {print $1; exit}')"
  [ -n "$d" ] || d="$(lsblk -d -p -n -o NAME,TYPE 2>/dev/null | awk '$2=="disk" {print $1; exit}')"
  [ -n "$d" ] || d="$(lsblk 2>/dev/null | sed 's/[[:space:]]*$//g' | grep 'disk$' | cut -d' ' -f1 | grep -v 'fd[0-9]*\|sr[0-9]*' | head -n1)"
  case "$d" in
    /dev/*) echo "$d" ;;
    '') echo "" ;;
    *) echo "/dev/$d" ;;
  esac
}

disk_size_mb() {
  local b
  b="$(lsblk -b -d -n -o SIZE "$1" 2>/dev/null | awk 'NR==1{print $1}')"
  if [ -z "$b" ] && command -v blockdev >/dev/null 2>&1; then
    b="$(blockdev --getsize64 "$1" 2>/dev/null)"
  fi
  [ -n "$b" ] || return 1
  awk -v bytes="$b" 'BEGIN{printf "%d", bytes/1048576}'
}

# GRUB helpers ---------------------------------------------------------------

getGrub() {
  local Boot="${1:-/boot}" folder fileName ver
  folder="$(find "$Boot" -type d -name "grub*" 2>/dev/null | head -n1)"
  [ -n "$folder" ] || return
  fileName="$(ls -1 "$folder" 2>/dev/null | grep -E '^grub\.conf$|^grub\.cfg$')"
  if [ -z "$fileName" ]; then
    ls -1 "$folder" 2>/dev/null | grep -q '^grubenv$'
    [ $? -eq 0 ] || return
    folder="$(find "$Boot" -type f -name "grubenv" 2>/dev/null | while IFS= read -r f; do dirname "$f"; done | grep -v "^$folder" | head -n1)"
    [ -n "$folder" ] || return
    fileName="$(ls -1 "$folder" 2>/dev/null | grep -E '^grub\.conf$|^grub\.cfg$')"
  fi
  [ -n "$fileName" ] || return
  [ "$fileName" = "grub.cfg" ] && ver="0" || ver="1"
  echo "${folder}:${fileName}:${ver}"
}

lowMem() {
  local mem
  mem="$(grep "^MemTotal:" /proc/meminfo 2>/dev/null | grep -o "[0-9]*")"
  [ -n "$mem" ] || return 0
  [ "$mem" -le 524288 ] && return 1 || return 0
}

# Mirror selection -----------------------------------------------------------

selectMirror() {
  local dist="$1" arch="$2" custom="$3" m url
  local -a mirrors
  mirrors=()
  [ -n "$custom" ] && mirrors+=("${custom%/}")
  mirrors+=("https://deb.debian.org/debian" "https://archive.debian.org/debian")
  if [ "$INSECURE" = '1' ]; then
    mirrors+=("http://deb.debian.org/debian" "http://archive.debian.org/debian")
  fi
  for m in "${mirrors[@]}"; do
    [ -n "$m" ] || continue
    url="$m/dists/$dist/main/installer-$arch/current/images/netboot/debian-installer/$arch/initrd.gz"
    if wget "${WGET_OPTS[@]}" --spider -o /dev/null "$url" >/dev/null 2>&1; then
      echo "$m"
      return 0
    fi
  done
  return 1
}

# Preseed helpers ------------------------------------------------------------

emit_swap_recipe() {
  local pri
  if is_uefi; then
    pri='768 788 1024 free $primary{ } $iflabel{ msdos gpt } $reusemethod{ } method{ efi } format{ } .'
  else
    pri='1 1 1 free $iflabel{ gpt } $reusemethod{ } method{ biosgrub } .'
  fi
  cat <<EOF
d-i partman-auto/init_automatically_partition select regular
d-i partman-auto/choose_recipe select atomic
d-i partman-auto/expert_recipe string \\
      custom :: \\
              ${pri} \\
              512 512 1024 ext4 \\
                      \$defaultignore{ } \\
                      method{ format } format{ } \\
                      use_filesystem{ } filesystem{ ext4 } \\
                      mountpoint{ /boot } \\
              . \\
              ${SWAP_MB} ${SWAP_MB} ${SWAP_MB} linux-swap \\
                      method{ swap } format{ } \\
              . \\
              2048 3000 -1 ext4 \\
                      method{ format } format{ } \\
                      use_filesystem{ } filesystem{ ext4 } \\
                      mountpoint{ / } \\
              .
EOF
}

# Windows post-install configuration ----------------------------------------

generate_net_bat() {
  local tmpfile='/tmp/boot/net.tmp' netfile='/tmp/boot/net.bat'
  : > "$tmpfile"

  cat >> "$tmpfile" <<'EOF'
@ECHO OFF

cd.>%WINDIR%\GetAdmin
if exist %WINDIR%\GetAdmin (del /f /q "%WINDIR%\GetAdmin") else (
echo CreateObject^("Shell.Application"^).ShellExecute "%~s0", "%*", "", "runas", 1 >> "%temp%\Admin.vbs"
"%temp%\Admin.vbs"
del /f /q "%temp%\Admin.vbs"
exit /b 2)

EOF

  if [ "$setNet" = '1' ] && [ -n "$ipAddr" ]; then
    cat >> "$tmpfile" <<EOF
for /f "tokens=3*" %%i in ('netsh interface show interface ^|more +3 ^|findstr /I /R "本地.* 以太.* Local.* Ethernet"') do (set EthName=%%j)
netsh -c interface ip set address name="%EthName%" source=static address=$ipAddr mask=$ipMask gateway=$ipGate
netsh -c interface ip add dnsservers name="%EthName%" address=$ipDNSFirst index=1 validate=no

EOF
  fi

  if [ "$setRDP" = '1' ] && [ -n "$WinRemote" ]; then
    cat >> "$tmpfile" <<EOF
netsh advfirewall firewall add rule name="RDP" dir=in action=allow protocol=TCP localport=$WinRemote 2>nul || netsh firewall set portopening protocol=TCP port=$WinRemote name=RDP mode=ENABLE
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t reg_dword /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd\Tds\tcp" /v PortNumber /t reg_dword /d $WinRemote /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v PortNumber /t reg_dword /d $WinRemote /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t reg_dword /d 1 /f
for /f "tokens=2 delims=:" %%i in ('SC QUERYEX TermService ^|FINDSTR /I "PID"') do TASKKILL /F /PID %%i
for /f "tokens=2 delims=:" %%i in ('SC QUERYEX UmRdpService ^|FINDSTR /I "PID"') do TASKKILL /F /PID %%i
SC START TermService

EOF
  fi

  cat >> "$tmpfile" <<'EOF'
ECHO SELECT VOLUME=%%SystemDrive%% > "%SystemDrive%\diskpart.extend"
ECHO EXTEND >> "%SystemDrive%\diskpart.extend"
START /WAIT DISKPART /S "%SystemDrive%\diskpart.extend"
DEL /f /q "%SystemDrive%\diskpart.extend"

cd /d "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup"
del /f /q net.bat
EOF

  awk '{printf "%s\r\n", $0}' "$tmpfile" | iconv -f 'UTF-8' -t 'GBK' > "$netfile" 2>/dev/null
  rm -f "$tmpfile"
  [ -s "$netfile" ] || die "Failed to generate net.bat"
}

# Main -----------------------------------------------------------------------

clear 2>/dev/null || true

# Normalize version and architecture.
[ -n "$tmpVER" ] || tmpVER='13'
DIST="$(normalize_dist "$tmpVER")"
[ -n "$DIST" ] || die "Unsupported Debian version: $tmpVER (use 6-14 or a codename such as trixie)"

if [ -n "$ARCH" ]; then
  ARCH="$(normalize_arch "$ARCH")"
else
  ARCH="$(detect_arch)"
fi
[ -n "$ARCH" ] || die "Unable to detect architecture. Use --arch amd64|arm64|i386|riscv64."

case "$DIST" in
  trixie|forky)
    if [ "$ARCH" = 'i386' ]; then
      die "Debian $DIST does not provide an i386 installer. Use --arch amd64."
    fi
    ;;
esac

# Validate swap and other options.
if [ -n "$SWAP_SPEC" ]; then
  parse_swap_size "$SWAP_SPEC" || die "Invalid --swap value: $SWAP_SPEC (examples: 512M, 2G, 2048)"
fi
if [ "$ddMode" = '1' ] && [ "$SWAP_MB" -gt 0 ]; then
  die "--swap cannot be used with -dd/--image (the raw image overwrites the partition table)."
fi

if [ "$ddMode" = '1' ] && [ -n "$IMAGE_SHA256" ]; then
  is_sha256 "$IMAGE_SHA256" || die "Invalid --image-sha256 value."
fi
if [ "$ddMode" != '1' ] && [ -n "$IMAGE_SHA256" ]; then
  warn "--image-sha256 is only used with -dd/--image; ignoring."
fi
if [ "$ddMode" != '1' ] && [ "$setRDP" = '1' ]; then
  warn "-rdp is only used with -dd/--image; ignoring."
fi

is_port "$sshPORT" || die "Invalid SSH port: $sshPORT"
sshPORT="$((10#$sshPORT))"
if [ -n "$WinRemote" ] && ! is_port "$WinRemote"; then
  die "Invalid RDP port: $WinRemote"
fi
[ -n "$WinRemote" ] && WinRemote="$((10#$WinRemote))"
if [ -n "$setConsole" ] && [[ ! "$setConsole" =~ ^[A-Za-z0-9_,.:=+-]+$ ]]; then
  die "Invalid console value: $setConsole"
fi
if [ -n "$interfaceSelect" ] && [ "$interfaceSelect" != 'auto' ] && [[ ! "$interfaceSelect" =~ ^[A-Za-z0-9_.:-]+$ ]]; then
  die "Invalid interface name: $interfaceSelect"
fi

if [ -n "$ipAddr" ] || [ -n "$ipMask" ] || [ -n "$ipGate" ] || [ -n "$ip6Addr" ] || [ -n "$ip6Mask" ] || [ -n "$ip6Gate" ]; then
  setNet='1'
fi

if [ "$NET_MODE" = 'dhcp' ]; then
  if [ -n "$ipAddr" ] || [ -n "$ipMask" ] || [ -n "$ipGate" ] || [ -n "$ip6Addr" ] || [ -n "$ip6Mask" ] || [ -n "$ip6Gate" ] || [ -n "$ipDNS" ] || [ -n "$ip6DNS" ]; then
    die "--dhcp cannot be combined with static IP/DNS options."
  fi
  setNet='0'
fi

if [ "$ip6Auto" = '1' ] && [ "$setIPv6" = '1' ]; then
  die "--ip6-auto cannot be combined with --noipv6."
fi
if [ "$ip6Auto" = '1' ] && { [ -n "$ip6Addr" ] || [ -n "$ip6Mask" ] || [ -n "$ip6Gate" ]; }; then
  die "--ip6-auto cannot be combined with --ip6-addr/--ip6-mask/--ip6-gate."
fi

if [ -n "$tmpMirror" ]; then
  is_url "$tmpMirror" || die "Invalid mirror URL (HTTPS required unless --insecure): $tmpMirror"
fi
if [ -n "$tmpURL" ]; then
  is_url "$tmpURL" || die "Invalid image URL (HTTPS required unless --insecure): $tmpURL"
fi

# Wget options.
WGET_OPTS=(--timeout=20 --tries=2 -q)
if [ "$INSECURE" = '1' ]; then
  WGET_OPTS+=(--no-check-certificate)
fi

printf '\n\033[36m# Check Dependence\033[0m\n\n'
if [ "$ddMode" = '1' ]; then
  require_cmds 'wget,awk,grep,sed,cut,cat,lsblk,cpio,gzip,find,dirname,basename,openssl,iconv,ip'
else
  require_cmds 'wget,awk,grep,sed,cut,cat,lsblk,cpio,gzip,find,dirname,basename,openssl,ip'
fi

# Detect hostname, IPv4, IPv6 and DNS defaults.
detect_hostname

if [ -z "$interface" ] && [ -n "$interfaceSelect" ] && [ "$interfaceSelect" != 'auto' ]; then
  interface="$interfaceSelect"
fi
[ -n "$interface" ] || interface="$(getInterface)"
[ -n "$interface" ] || die "Unable to detect the network interface. Use -i/--interface."

if [ "$NET_MODE" != 'dhcp' ] && [ -z "$ipAddr" ] && [ -z "$ipMask" ] && [ -z "$ipGate" ]; then
  iAddr="$(ip -4 addr show dev "$interface" 2>/dev/null | grep 'inet ' | head -n1 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/[0-9]\{1,2\}')"
  if [ -n "$iAddr" ]; then
    ipAddr="${iAddr%%/*}"
    ipMask="$(netmask "${iAddr##*/}")"
    ipGate="$(ip route show default 2>/dev/null | grep '^default' | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -n1)"
  fi
fi

if [ "$NET_MODE" != 'dhcp' ] && [ "$ip6Auto" != '1' ] && [ "$setIPv6" != '1' ]; then
  detect_ipv6
fi

if [ -z "$interfaceSelect" ]; then
  interfaceSelect='auto'
fi

validate_network_settings || exit 1

# Disk selection.
if [ -n "$DISK_OVERRIDE" ]; then
  IncDisk="$DISK_OVERRIDE"
else
  IncDisk="$(getDisk)"
  [ -n "$IncDisk" ] || die "No disk detected. Use --disk /dev/xxx."
fi
validate_disk_settings || exit 1

# GRUB discovery.
if [ "$loaderMode" = '0' ]; then
  Grub="$(getGrub /boot)"
  [ -n "$Grub" ] || die "GRUB configuration not found under /boot."
  GRUBDIR="${Grub%%:*}"
  GrubRest="${Grub#*:}"
  GRUBFILE="${GrubRest%%:*}"
  GRUBVER="${GrubRest##*:}"
fi

# Review everything before any destructive action or reboot.
prompt_password
prompt_settings
if [ -z "$tmpWORD" ]; then
  warn "Using the built-in default root password '$DEFAULT_PASSWORD'. Change it immediately after installation."
fi

# Root password hash.
password="$DEFAULT_PASSWORD"
[ -n "$tmpWORD" ] && password="$tmpWORD"
myPASSWORD="$(openssl passwd -6 "$password" 2>/dev/null || true)"
if [ -z "$myPASSWORD" ]; then
  myPASSWORD="$(openssl passwd -1 "$password" 2>/dev/null || true)"
  [ -n "$myPASSWORD" ] && warn "This openssl does not support SHA-512; using MD5 crypt fallback."
fi
[ -n "$myPASSWORD" ] || die "Failed to hash the root password."

# Select mirror and verify the exact netboot path.
LinuxMirror="$(selectMirror "$DIST" "$ARCH" "$tmpMirror")"
[ -n "$LinuxMirror" ] || die "No usable Debian mirror found for $DIST/$ARCH. Try --mirror or --insecure for EOL releases."

case "$DIST" in
  squeeze|wheezy|jessie|stretch|buster)
    [ "$INSECURE" = '1' ] || warn "$DIST is EOL. If package signature verification fails, retry with --insecure."
    ;;
esac

printf '\n[\033[33mDebian\033[0m] [\033[33m%s\033[0m] [\033[33m%s\033[0m] Downloading...\n' "$DIST" "$ARCH"

rm -f /tmp/initrd.img.gz /tmp/initrd.img /tmp/vmlinuz /tmp/firmware.cpio.gz
wget "${WGET_OPTS[@]}" -O /tmp/initrd.img.gz "${LinuxMirror}/dists/${DIST}/main/installer-${ARCH}/current/images/netboot/debian-installer/${ARCH}/initrd.gz" || die "Failed to download initrd.gz."
[ -s /tmp/initrd.img.gz ] || die "Downloaded initrd.gz is empty."
wget "${WGET_OPTS[@]}" -O /tmp/vmlinuz "${LinuxMirror}/dists/${DIST}/main/installer-${ARCH}/current/images/netboot/debian-installer/${ARCH}/linux" || die "Failed to download linux kernel."
[ -s /tmp/vmlinuz ] || die "Downloaded kernel is empty."

if [ "$IncFirmware" = '1' ]; then
  wget "${WGET_OPTS[@]}" -O /tmp/firmware.cpio.gz "https://cdimage.debian.org/cdimage/unofficial/non-free/firmware/${DIST}/current/firmware.cpio.gz" || die "Failed to download firmware."
  [ -s /tmp/firmware.cpio.gz ] || die "Downloaded firmware is empty."
fi

MirrorHost="$(echo "$LinuxMirror" | awk -F'://|/' '{print $2}')"
MirrorFolder="$(echo "$LinuxMirror" | sed 's#^[a-zA-Z][a-zA-Z0-9+.-]*://[^/]*##')"
[ -n "$MirrorFolder" ] || MirrorFolder='/'

# Build the GRUB entry in /tmp/grub.new.
rm -f /tmp/grub.new /tmp/grub.read /tmp/grub.source
if [ "$loaderMode" = '0' ]; then
  [ -f "$GRUBDIR/$GRUBFILE" ] || die "GRUB file not found: $GRUBDIR/$GRUBFILE"
  if [ ! -f "$GRUBDIR/$GRUBFILE.old" ] && [ -f "$GRUBDIR/$GRUBFILE.bak" ]; then
    mv -f "$GRUBDIR/$GRUBFILE.bak" "$GRUBDIR/$GRUBFILE.old"
  fi
  baseline="$GRUBDIR/$GRUBFILE"
  [ -f "$GRUBDIR/$GRUBFILE.old" ] && baseline="$GRUBDIR/$GRUBFILE.old"
  cp -f "$baseline" /tmp/grub.source || die "Failed to copy GRUB configuration."
  if [ "$DRY_RUN" != '1' ]; then
    cp -f "$GRUBDIR/$GRUBFILE" "$GRUBDIR/$GRUBFILE.bak" || die "Failed to back up GRUB configuration."
    if [ "$baseline" != "$GRUBDIR/$GRUBFILE" ]; then
      cp -f "$baseline" "$GRUBDIR/$GRUBFILE" || die "Failed to prepare GRUB configuration."
    fi
  fi

  if [ "$GRUBVER" = '0' ]; then
    READGRUB='/tmp/grub.read'
    cat /tmp/grub.source | sed -n '1h;1!H;$g;s/\n/%%%%%%%/g;$p' | grep -om 1 'menuentry\ [^{]*{[^}]*}%%%%%%%' | sed 's/%%%%%%%/\n/g' > "$READGRUB"
    LoadNum="$(grep -c 'menuentry ' "$READGRUB" 2>/dev/null || true)"
    if [ "$LoadNum" -eq 1 ]; then
      sed '/^$/d' "$READGRUB" > /tmp/grub.new
    elif [ "$LoadNum" -gt 1 ]; then
      CFG0="$(awk '/menuentry /{print NR}' "$READGRUB" | head -n 1)"
      CFG2="$(awk '/menuentry /{print NR}' "$READGRUB" | head -n 2 | tail -n 1)"
      CFG1=''
      for tmpCFG in $(awk '/}/{print NR}' "$READGRUB"); do
        [ "$tmpCFG" -gt "$CFG0" ] && [ "$tmpCFG" -lt "$CFG2" ] && CFG1="$tmpCFG"
      done
      [ -n "$CFG1" ] || die "Failed to read $GRUBFILE."
      sed -n "${CFG0},${CFG1}p" "$READGRUB" > /tmp/grub.new
      [ -f /tmp/grub.new ] && [ "$(grep -c '{' /tmp/grub.new)" -eq "$(grep -c '}' /tmp/grub.new)" ] || die "Failed to configure $GRUBFILE."
    fi
    [ -f /tmp/grub.new ] || die "Failed to parse $GRUBFILE."
    sed -i "/menuentry.*/c\menuentry\ \'Install Debian [$DIST $ARCH]\'\ --class debian\ --class\ gnu-linux\ --class\ gnu\ --class\ os\ \{" /tmp/grub.new
    sed -i "/echo.*Loading/d" /tmp/grub.new
    INSERTGRUB="$(awk '/menuentry /{print NR}' /tmp/grub.source | head -n 1)"
  fi

  if [ "$GRUBVER" = '1' ]; then
    CFG0="$(awk '/title[ ]|title[\t]/{print NR}' /tmp/grub.source | head -n 1)"
    CFG1="$(awk '/title[ ]|title[\t]/{print NR}' /tmp/grub.source | head -n 2 | tail -n 1)"
    if [ -n "$CFG0" ] && { [ -z "$CFG1" ] || [ "$CFG1" = "$CFG0" ]; }; then
      sed -n "${CFG0},\$p" /tmp/grub.source > /tmp/grub.new
    elif [ -n "$CFG0" ]; then
      sed -n "${CFG0},$((CFG1-1))p" /tmp/grub.source > /tmp/grub.new
    fi
    [ -f /tmp/grub.new ] || die "Failed to configure $GRUBFILE."
    sed -i "/title.*/c\title\ \'Install Debian [$DIST $ARCH]\'" /tmp/grub.new
    sed -i '/^#/d' /tmp/grub.new
    INSERTGRUB="$(awk '/title[ ]|title[\t]/{print NR}' /tmp/grub.source | head -n 1)"
  fi

  LinuxKernel="$(grep 'linux.*/\|kernel.*/' /tmp/grub.new | awk '{print $1}' | head -n 1)"
  [ -n "$LinuxKernel" ] || die "Failed to read kernel line from GRUB configuration."
  LinuxIMG="$(grep 'initrd.*/' /tmp/grub.new | awk '{print $1}' | tail -n 1)"
  if [ -z "$LinuxIMG" ]; then
    sed -i "/$LinuxKernel.*\//a\\\tinitrd\ \/" /tmp/grub.new
    LinuxIMG='initrd'
  fi

  Add_OPTION=''
  [ "$setInterfaceName" = '1' ] && Add_OPTION='net.ifnames=0 biosdevname=0'
  [ "$setIPv6" = '1' ] && Add_OPTION="$Add_OPTION ipv6.disable=1"
  lowMem || Add_OPTION="$Add_OPTION lowmem=+2"

  BOOT_OPTION="auto=true $Add_OPTION hostname=$SERVER_HOSTNAME domain=$SERVER_DOMAIN quiet"
  [ -n "$setConsole" ] && BOOT_OPTION="$BOOT_OPTION --- console=$setConsole"

  if [ -n "$(grep 'linux.*/\|kernel.*/' /tmp/grub.new | awk '{print $2}' | tail -n 1 | grep '^/boot/')" ]; then
    Type='InBoot'
  else
    Type='NoBoot'
  fi

  if [ "$Type" = 'InBoot' ]; then
    sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/boot\/vmlinuz $BOOT_OPTION" /tmp/grub.new
    sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/boot\/initrd.img" /tmp/grub.new
  else
    sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/vmlinuz $BOOT_OPTION" /tmp/grub.new
    sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/initrd.img" /tmp/grub.new
  fi

  sed -i '$a\\n' /tmp/grub.new

  if [ "$DRY_RUN" != '1' ]; then
    sed -i "${INSERTGRUB}i\\n" "$GRUBDIR/$GRUBFILE"
    sed -i "${INSERTGRUB}r /tmp/grub.new" "$GRUBDIR/$GRUBFILE"
    [ -f "$GRUBDIR/grubenv" ] && sed -i 's/saved_entry/#saved_entry/g' "$GRUBDIR/grubenv"
  fi
fi

# Extract initrd.
gzip -t /tmp/initrd.img.gz 2>/dev/null || die "Downloaded initrd.gz is not a valid gzip file."
rm -rf /tmp/boot
mkdir -p /tmp/boot
( set -o pipefail; gzip -dc /tmp/initrd.img.gz | (cd /tmp/boot && cpio --extract --verbose --make-directories --no-absolute-filenames) ) >>/dev/null 2>&1 || die "Failed to extract initrd."

# Optional post-install files.
POST_INSTALL_PRESEED=':'
if [ -n "$POST_INSTALL_CMD" ]; then
  {
    echo '#!/bin/bash'
    printf '%s\n' "$POST_INSTALL_CMD"
  } > /tmp/boot/post-install.sh
  chmod 700 /tmp/boot/post-install.sh
  cat > /tmp/boot/post-install.service <<'EOF'
[Unit]
Description=One-time post install commands
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '/root/post-install.sh >> /var/log/post-install.log 2>&1'
ExecStartPost=-/bin/systemctl disable post-install.service
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
  POST_INSTALL_PRESEED='cp -f /post-install.sh /target/root/post-install.sh; chmod 700 /target/root/post-install.sh; cp -f /post-install.service /target/etc/systemd/system/post-install.service; mkdir -p /target/etc/systemd/system/multi-user.target.wants; ln -sf /etc/systemd/system/post-install.service /target/etc/systemd/system/multi-user.target.wants/post-install.service;'
fi

# Network configuration for the installed system.
NETWORK_PRESEED=':'
if [ "$ddMode" != '1' ] && [ "$PRIMARY_FAMILY" = '4' ] && [ -n "$ip6Addr" ] && [ "$setIPv6" != '1' ]; then
  cat > /tmp/boot/ipv6-setup.sh <<'EOF'
#!/bin/sh
IFACE=$(awk '/^iface .* inet /{print $2; exit}' /target/etc/network/interfaces 2>/dev/null)
[ -n "$IFACE" ] || exit 0
grep -q "^iface $IFACE inet6" /target/etc/network/interfaces 2>/dev/null && exit 0
{
  echo "iface $IFACE inet6 static"
EOF
  {
    echo "  echo \"    address $ip6Addr/$ip6Mask\""
    [ -n "$ip6Gate" ] && echo "  echo \"    gateway $ip6Gate\""
    [ -n "$ipDNSAll" ] && echo "  echo \"    dns-nameservers $ipDNSAll\""
  } >> /tmp/boot/ipv6-setup.sh
  cat >> /tmp/boot/ipv6-setup.sh <<'EOF'
} >> /target/etc/network/interfaces
EOF
  chmod 700 /tmp/boot/ipv6-setup.sh
  NETWORK_PRESEED='sh /ipv6-setup.sh;'
fi

# IPv6 auto (SLAAC/DHCPv6) configuration for the installed system.
if [ "$ip6Auto" = '1' ] && [ "$NET_MODE" != 'dhcp' ] && [ "$ddMode" != '1' ]; then
  cat > /tmp/boot/ip6auto-setup.sh <<EOF
#!/bin/sh
IFACE=\$(awk '/^iface .* inet /{print \$2; exit}' /target/etc/network/interfaces 2>/dev/null)
[ -n "\$IFACE" ] || IFACE='$interface'
[ -n "\$IFACE" ] || exit 0
grep -q "^auto \$IFACE" /target/etc/network/interfaces 2>/dev/null || echo "auto \$IFACE" >> /target/etc/network/interfaces
grep -q "^iface \$IFACE inet6 " /target/etc/network/interfaces 2>/dev/null || echo "iface \$IFACE inet6 auto" >> /target/etc/network/interfaces
EOF
  chmod 700 /tmp/boot/ip6auto-setup.sh
  NETWORK_PRESEED='sh /ip6auto-setup.sh;'
fi

# DHCP/SLAAC configuration for the installed system.
if [ "$NET_MODE" = 'dhcp' ] && [ "$ddMode" != '1' ]; then
  cat > /tmp/boot/dhcp-setup.sh <<EOF
#!/bin/sh
IFACE=\$(awk '/^iface .* inet /{print \$2; exit}' /target/etc/network/interfaces 2>/dev/null)
[ -n "\$IFACE" ] || IFACE='$interface'
[ -n "\$IFACE" ] || exit 0
grep -q "^auto \$IFACE" /target/etc/network/interfaces 2>/dev/null || echo "auto \$IFACE" >> /target/etc/network/interfaces
grep -q "^iface \$IFACE inet " /target/etc/network/interfaces 2>/dev/null || echo "iface \$IFACE inet dhcp" >> /target/etc/network/interfaces
EOF
  if [ "$setIPv6" != '1' ]; then
    cat >> /tmp/boot/dhcp-setup.sh <<'EOF'
grep -q "^iface $IFACE inet6 " /target/etc/network/interfaces 2>/dev/null || echo "iface $IFACE inet6 auto" >> /target/etc/network/interfaces
EOF
  fi
  chmod 700 /tmp/boot/dhcp-setup.sh
  NETWORK_PRESEED='sh /dhcp-setup.sh;'
fi

# DD mode net.bat.
if [ "$ddMode" = '1' ]; then
  generate_net_bat
fi

# Preseed.
PRESEED='/tmp/boot/preseed.cfg'
ALLOW_UNAUTH='false'
[ "$INSECURE" = '1' ] && ALLOW_UNAUTH='true'

cat > "$PRESEED" <<EOF
d-i debian-installer/locale string en_US
d-i debian-installer/country string US
d-i debian-installer/language string en

d-i console-setup/layoutcode string us
d-i keyboard-configuration/xkb-keymap string us
d-i lowmem/low note

d-i netcfg/choose_interface select $interfaceSelect
d-i netcfg/get_hostname string $SERVER_HOSTNAME
d-i netcfg/get_domain string $SERVER_DOMAIN
d-i netcfg/hostname string $SERVER_HOSTNAME
EOF

if [ "$NET_MODE" = 'dhcp' ] || { [ "$loaderMode" != '0' ] && [ "$setNet" = '0' ]; }; then
  cat >> "$PRESEED" <<'EOF'
d-i netcfg/disable_autoconfig boolean false
EOF
else
  cat >> "$PRESEED" <<EOF
d-i netcfg/disable_autoconfig boolean true
d-i netcfg/dhcp_failed note
d-i netcfg/dhcp_options select Configure network manually
d-i netcfg/get_ipaddress string $PRIMARY_IP
d-i netcfg/get_netmask string $PRIMARY_MASK
d-i netcfg/get_gateway string $PRIMARY_GATE
d-i netcfg/get_nameservers string $ipDNSAll
d-i netcfg/confirm_static boolean true
EOF
fi

cat >> "$PRESEED" <<EOF

d-i hw-detect/load_firmware boolean true

d-i mirror/country string manual
d-i mirror/http/hostname string $MirrorHost
d-i mirror/http/directory string $MirrorFolder
d-i mirror/http/proxy string

d-i passwd/root-login boolean true
d-i passwd/make-user boolean false
d-i passwd/root-password-crypted password $myPASSWORD

d-i clock-setup/utc boolean true
d-i time/zone string US/Eastern
d-i clock-setup/ntp boolean false

d-i partman-auto/disk string $IncDisk
d-i partman-auto/method string regular
EOF

if [ "$SWAP_MB" -gt 0 ]; then
  emit_swap_recipe >> "$PRESEED"
else
  cat >> "$PRESEED" <<'EOF'
d-i partman-auto/init_automatically_partition select regular
d-i partman-auto/choose_recipe select atomic
EOF
fi

cat >> "$PRESEED" <<EOF
d-i partman-md/device_remove_md boolean true
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

d-i debian-installer/allow_unauthenticated boolean $ALLOW_UNAUTH

tasksel tasksel/first multiselect minimal
d-i pkgsel/update-policy select none
d-i pkgsel/include string openssh-server
d-i pkgsel/upgrade select none

popularity-contest popularity-contest/participate boolean false

d-i grub-installer/only_debian boolean true
d-i grub-installer/bootdev string $IncDisk
d-i grub-installer/force-efi-extra-removable boolean true
d-i finish-install/reboot_in_progress note
d-i debian-installer/exit/reboot boolean true
d-i preseed/late_command string \
    sed -ri 's/^#?Port.*/Port ${sshPORT}/g' /target/etc/ssh/sshd_config; \
    sed -ri 's/^#?PermitRootLogin.*/PermitRootLogin yes/g' /target/etc/ssh/sshd_config; \
    sed -ri 's/^#?PasswordAuthentication.*/PasswordAuthentication yes/g' /target/etc/ssh/sshd_config; \
    mkdir -p /target/etc/ssh/sshd_config.d; \
    printf 'Port %s\nPermitRootLogin yes\nPasswordAuthentication yes\n' '${sshPORT}' > /target/etc/ssh/sshd_config.d/99-installnet.conf; \
    $NETWORK_PRESEED \
    $POST_INSTALL_PRESEED
EOF

if [ "$ddMode" = '1' ]; then
  case "$DIST" in
    trixie|forky)
      ANNA_PKGS='libfuse3-4-udeb fuse3-udeb ntfs-3g-udeb libcrypto3-udeb libssl3-udeb libuuid1-udeb zlib1g-udeb wget-udeb'
      ;;
    bookworm)
      ANNA_PKGS='libfuse2-udeb fuse-udeb ntfs-3g-udeb libcrypto3-udeb libssl3-udeb libuuid1-udeb zlib1g-udeb wget-udeb'
      ;;
    *)
      ANNA_PKGS='libfuse2-udeb fuse-udeb ntfs-3g-udeb libcrypto1.1-udeb libssl1.1-udeb libuuid1-udeb zlib1g-udeb wget-udeb'
      ;;
  esac

  DD_WGET_OPTS='-q'
  [ "$INSECURE" = '1' ] && DD_WGET_OPTS="$DD_WGET_OPTS --no-check-certificate"

  if [ -n "$DISK_OVERRIDE" ]; then
    DISK_LINE="DISK=\"$IncDisk\";"
  else
    DISK_LINE='DISK="$(list-devices disk | head -n1)";'
  fi

  cat >> "$PRESEED" <<EOF

d-i preseed/early_command string anna-install $ANNA_PKGS
d-i partman/early_command string \\
    V="\$(blkid -t TYPE='vfat' -o device)"; \\
    [ -n "\$V" ] && umount "\$V"; \\
    $DISK_LINE \\
    debconf-set partman-auto/disk "\$DISK"; \\
EOF

  if [ -n "$IMAGE_SHA256" ]; then
    cat >> "$PRESEED" <<EOF
    wget $DD_WGET_OPTS -O /tmp/dd.img.gz '$tmpURL' && \\
    echo '$IMAGE_SHA256  /tmp/dd.img.gz' | sha256sum -c - && \\
    gunzip -dc /tmp/dd.img.gz | dd of="\$DISK" bs=4M || \\
    { echo 'DD image download or verification failed'; sleep 10; /sbin/reboot; }; \\
EOF
  else
    cat >> "$PRESEED" <<EOF
    ( set -o pipefail 2>/dev/null; wget $DD_WGET_OPTS -O - '$tmpURL' | gunzip -dc | dd of="\$DISK" bs=4M ) || \\
    { echo 'DD image download failed'; sleep 10; /sbin/reboot; }; \\
EOF
  fi

  cat >> "$PRESEED" <<'EOF'
    mount.ntfs-3g "$(list-devices partition | head -n1)" /mnt; \
    cd '/mnt/ProgramData/Microsoft/Windows/Start Menu/Programs'; \
    cd Start* || cd start*; \
    cp -f '/net.bat' './net.bat'; \
    sync; /sbin/reboot
EOF
fi

if [ "$IncFirmware" = '1' ]; then
  ( set -o pipefail; gzip -dc /tmp/firmware.cpio.gz | (cd /tmp/boot && cpio --extract --verbose --make-directories --no-absolute-filenames) ) >>/dev/null 2>&1 || die "Failed to extract firmware."
fi

if [ "$DRY_RUN" = '1' ]; then
  printf '\n\033[36m# Dry run\033[0m\n'
  printf '\n--- preseed: %s ---\n' "$PRESEED"
  cat "$PRESEED"
  if [ -f /tmp/grub.new ]; then
    printf '\n--- grub entry: /tmp/grub.new ---\n'
    cat /tmp/grub.new
  fi
  printf '\nDry run complete. /boot, GRUB and the disk were not modified.\n'
  exit 0
fi

# Repack and install the new initrd.
( set -o pipefail; cd /tmp/boot && find . | cpio -H newc --create --verbose | gzip -9 > /tmp/initrd.img ) || die "Failed to repack initrd."
[ -s /tmp/initrd.img ] || die "Repacked initrd is empty."

cp -f /tmp/initrd.img /boot/initrd.img || die "Failed to copy initrd to /boot."
cp -f /tmp/vmlinuz /boot/vmlinuz || die "Failed to copy kernel to /boot."

if [ "$loaderMode" = '0' ]; then
  chown root:root "$GRUBDIR/$GRUBFILE" 2>/dev/null || true
  chmod 444 "$GRUBDIR/$GRUBFILE" 2>/dev/null || true
  sync
  printf '\nInstallation environment is ready. Rebooting in 3 seconds...\n'
  sleep 3
  reboot
else
  rm -rf "$HOME/loader"
  mkdir -p "$HOME/loader"
  cp -f /boot/initrd.img "$HOME/loader/initrd.img" || die "Failed to copy initrd to loader directory."
  cp -f /boot/vmlinuz "$HOME/loader/vmlinuz" || die "Failed to copy kernel to loader directory."
  rm -f /boot/initrd.img /boot/vmlinuz
  printf '\nLoader files are in: %s\n' "$HOME/loader"
  ls -AR1 "$HOME/loader"
fi
