# InstallNET.sh 使用文档

`InstallNET.sh` 是一个在 Linux 上通过网络重装 Debian 的脚本。

当前版本只支持 **Debian**，已移除 Ubuntu / CentOS 安装支持。

---

## 重要警告

- 脚本会 **擦除目标磁盘上的所有数据**。
- 执行前必须确认目标磁盘，并做好备份。
- 默认 root 密码是 `a59~12`，安装完成后应立即修改。
- 只应在你有权限管理的服务器上使用。
- 安装过程依赖网络，请确保当前网络可以访问 Debian 镜像。

---

## 支持范围

### 发行版

| Debian 版本 | Codename | 说明 |
|---|---|---|
| 6 | squeeze | EOL，通常需要 `--insecure` |
| 7 | wheezy | EOL，通常需要 `--insecure` |
| 8 | jessie | EOL，通常需要 `--insecure` |
| 9 | stretch | EOL，通常需要 `--insecure` |
| 10 | buster | EOL，通常需要 `--insecure` |
| 11 | bullseye | 旧稳定版 |
| 12 | bookworm | 旧稳定版 |
| 13 | trixie | 当前默认版本 |
| 14 | forky | testing，非稳定版 |

### 架构

- `amd64`
- `arm64`
- `i386`：仅 Debian 12 及以前；Debian 13/14 已不提供 i386 安装器
- `riscv64`：视 Debian 版本和镜像是否提供而定

---

## 依赖

脚本运行在 **即将被重装的旧系统** 上，需要以下命令：

```text
wget awk grep sed cut cat lsblk cpio gzip find dirname basename openssl
```

网络检测（网卡、IPv4、IPv6）需要：

```text
ip
```

DD Windows 模式还需要：

```text
iconv
```

Debian / Ubuntu 主机可执行：

```bash
apt-get update
apt-get install -y wget cpio gzip openssl iproute2 util-linux
```

---

## 快速开始

所有命令都必须以 **root** 身份运行。

### 安装 Debian 13，默认密码

```bash
bash InstallNET.sh -v 13
```

### 安装 Debian 13，自定义密码

```bash
bash InstallNET.sh -v 13 -p 'MyStrongPassword'
```

### 安装 Debian 12，并创建 2GB swap 分区

```bash
bash InstallNET.sh -v 12 -p 'MyStrongPassword' --swap 2G
```

### IPv4/IPv6 都自动获取

```bash
bash InstallNET.sh -v 13 --dhcp -p 'MyStrongPassword'
```

### 明确指定磁盘，跳过确认

```bash
bash InstallNET.sh -v 13 -p 'MyStrongPassword' --disk /dev/vda --yes
```

### 只生成配置，不修改系统

```bash
bash InstallNET.sh -v 13 --swap 2G --dry-run
```

`--dry-run` 会下载并解析安装器文件，然后打印将生成的 preseed 和 GRUB 菜单项，但不会修改 `/boot`、GRUB 或磁盘。

注意：dry-run 输出中会包含 root 密码哈希，请避免把输出直接公开到日志或聊天工具中。

---

## 参数说明

### 参数总览

| 参数 | 别名/说明 | 作用 |
|---|---|---|
| `-h, --help` |  | 显示帮助 |
| `-v, --ver <version>` |  | Debian 版本或 codename，默认 `13` |
| `--arch <arch>` |  | 架构：`amd64`、`arm64`、`i386`、`riscv64` |
| `-p, --password <password>` |  | 覆盖默认 root 密码 |
| `--password-stdin` |  | 从标准输入读取 root 密码 |
| `-i, --interface <name>` |  | 指定网卡 |
| `--hostname <name>` |  | 新系统主机名 |
| `--domain <domain>` |  | 新系统域名 |
| `--ip-addr <ipv4>` |  | 静态 IPv4 地址 |
| `--ip-mask <mask\|prefix>` |  | IPv4 掩码或前缀 |
| `--ip-gate <ipv4>` |  | IPv4 网关 |
| `--ip6-addr <ipv6>` |  | 静态 IPv6 地址 |
| `--ip6-mask <prefix>` |  | IPv6 前缀长度，默认 `64` |
| `--ip6-gate <ipv6>` |  | IPv6 网关 |
| `--ip-dns <ip>` |  | DNS，支持 IPv4/IPv6 |
| `--ip6-dns <ipv6>` |  | 额外 IPv6 DNS |
| `--dhcp` | `--auto-net` | IPv4 DHCP + IPv6 自动获取 |
| `--ip6-auto` | `--dhcp6`、`--ipv6-auto` | IPv4 固定 + IPv6 自动获取 |
| `--dev-net` |  | 安装器禁用可预测网卡名 |
| `--noipv6` |  | 安装器和目标系统禁用 IPv6 |
| `--mirror <url>` | `-apt`、`-yum` | 自定义 Debian 镜像 |
| `-firmware` |  | 加载非自由固件 |
| `-port <port>` |  | 新系统 SSH 端口 |
| `-console <console>` |  | 安装器内核 console 参数 |
| `--swap <size>` |  | 创建指定大小的真实 swap 分区 |
| `--disk <device>` |  | 指定目标磁盘 |
| `--yes` |  | 跳过所有交互提示和磁盘确认 |
| `--insecure` |  | 允许 HTTP/FTP，关闭 TLS/签名校验 |
| `-dd, --image <url>` |  | 下载 gzip 镜像并直接写盘 |
| `--image-sha256 <hash>` |  | 校验 DD 镜像 SHA-256 |
| `-rdp <port>` |  | Windows 镜像启用 RDP |
| `--loader` |  | 不修改 GRUB，输出到 `~/loader` |
| `--post-install-cmd <cmd>` |  | 首次开机执行一次命令 |
| `--dry-run` |  | 只生成并打印配置，不修改系统 |
| `-a, --auto` | `-m, --manual`、`-ssl` | 兼容旧参数，接受但忽略 |
| `-d, --debian` | `-u, --ubuntu`、`-c, --centos` | 已移除，使用会报错 |

### 帮助

```bash
bash InstallNET.sh -h
bash InstallNET.sh --help
```

显示完整参数说明并退出。

### Debian 版本与架构

```bash
-v, --ver <version>
```

指定 Debian 版本或 codename，默认 `13`。

示例：

```bash
-v 13
-v trixie
-v 12
-v bookworm
-v 14
```

```bash
--arch <arch>
```

指定架构，默认根据 `uname -m` 自动识别。

示例：

```bash
--arch amd64
--arch arm64
--arch i386
--arch riscv64
```

注意：

- Debian 13/14 不再提供 i386 安装器。
- 旧版本 Debian 的 arm64/riscv64 可能没有安装器，脚本会提示找不到镜像。

---

### 密码

```bash
-p, --password <password>
```

覆盖默认 root 密码 `a59~12`。

在交互终端中，如果没有传 `-p`，脚本会在重启前显示默认密码，并询问是否修改。所有密码提示都在进入安装器之前完成。

```bash
--password-stdin
```

从标准输入读取密码，避免密码直接出现在 shell 历史或进程列表：

```bash
printf '%s\n' 'MyStrongPassword' | bash InstallNET.sh -v 13 --password-stdin
```

密码会使用 `openssl passwd -6` 生成 SHA-512 crypt 哈希。若旧系统的 openssl 不支持 `-6`，会回退到 MD5 crypt 并打印警告。

---

### 网络配置

脚本会在启动安装前自动读取当前机器的环境信息：

- 主机名和域名
- 网卡名
- IPv4 地址、掩码、网关
- IPv6 地址、前缀、网关
- DNS 服务器

读取完成后，脚本会显示一份安装摘要，并在 **重启进入安装器之前** 询问是否使用这些配置。你也可以选择手动修改主机名、IPv4、IPv6、DNS、swap 大小和目标磁盘。

> 重要：所有确认和默认密码提示都在重启前完成。重启后进入 Debian 安装器，用户不会再看到交互界面。

如果脚本以非交互方式运行（例如没有 TTY），或传入了 `--yes`，脚本会直接使用自动检测到的值和默认值，并打印摘要。

#### 手动指定网络参数

```bash
-i, --interface <name>
--hostname <name>
--domain <domain>
--ip-addr <ipv4>
--ip-mask <mask|prefix>
--ip-gate <ipv4>
--ip6-addr <ipv6>
--ip6-mask <prefix>
--ip6-gate <ipv6>
--ip-dns <ip>
--ip6-dns <ipv6>
--dhcp
--ip6-auto
```

IPv4 示例：

```bash
bash InstallNET.sh -v 13 \
  --ip-addr 203.0.113.10 \
  --ip-mask 255.255.255.0 \
  --ip-gate 203.0.113.1 \
  --ip-dns 8.8.8.8
```

`--ip-mask` 同时支持点分格式和前缀长度：

```bash
--ip-mask 255.255.255.0
--ip-mask 24
--ip-mask /24
```

双栈示例：

```bash
bash InstallNET.sh -v 13 \
  --hostname myhost \
  --domain example.com \
  --ip-addr 203.0.113.10 \
  --ip-mask 24 \
  --ip-gate 203.0.113.1 \
  --ip6-addr 2001:db8::10 \
  --ip6-mask 64 \
  --ip6-gate 2001:db8::1 \
  --ip-dns 1.1.1.1 \
  --ip6-dns 2606:4700:4700::1111
```

IPv6 说明：

- `--ip6-mask` 使用前缀长度，例如 `64`；不填时默认 `64`。
- IPv4 和 IPv6 可以同时配置。
- 如果机器只有 IPv6，没有 IPv4，脚本会把 IPv6 作为安装器的主网络；此时必须提供 IPv6 网关。
- 如果 IPv4 作为主网络，IPv6 会在安装完成后写入新系统的 `/etc/network/interfaces`（ifupdown 格式）。
- 如果 IPv4 固定、IPv6 自动获取，使用 `--ip6-auto`，详见下面的 DHCP/SLAAC 与 IPv4 固定 + IPv6 自动章节。
- IPv6 的写入依赖目标系统使用 ifupdown；如果目标系统使用 systemd-networkd/NetworkManager，需要登录后自行调整。
- 多个 DNS 可以用空格分隔。

多个 DNS 示例：

```bash
--ip-dns "1.1.1.1 8.8.8.8"
--ip6-dns "2606:4700:4700::1111 2001:4860:4860::8888"
```

#### 自动获取网络（DHCP/SLAAC）

如果 IPv4 和 IPv6 都希望自动获取，使用：

```bash
--dhcp
```

别名：`--auto-net`

行为：

- 安装器使用 DHCP 获取网络。
- 安装完成后，脚本会确保目标系统的 `/etc/network/interfaces` 包含：

```text
auto <iface>
iface <iface> inet dhcp
iface <iface> inet6 auto
```

- `inet6 auto` 使用路由通告（SLAAC）自动获取 IPv6；如果网络使用 DHCPv6，可将该行改为 `iface <iface> inet6 dhcp`。
- 加 `--noipv6` 时只保留 IPv4 DHCP。
- `--dhcp` 不能和 `--ip-addr`、`--ip6-addr`、`--ip-dns` 等静态参数同时使用。
- 与静态 IPv6 配置一样，DHCP 模式也通过 ifupdown 的 `/etc/network/interfaces` 写入；使用 systemd-networkd/NetworkManager 的系统需要登录后调整。

示例：

```bash
bash InstallNET.sh -v 13 --dhcp -p 'MyStrongPassword' --swap 2G
```

#### IPv4 固定 + IPv6 自动获取

如果 IPv4 使用固定地址，IPv6 使用 SLAAC/DHCPv6 自动获取，使用：

```bash
--ip6-auto
```

别名：`--dhcp6`、`--ipv6-auto`

示例：

```bash
bash InstallNET.sh -v 13 -p 'MyStrongPassword' \
  --ip-addr 203.0.113.10 \
  --ip-mask 24 \
  --ip-gate 203.0.113.1 \
  --ip-dns 1.1.1.1 \
  --ip6-auto \
  --swap 2G
```

行为：

- 安装器使用固定 IPv4 网络完成安装。
- 安装完成后，目标系统的 `/etc/network/interfaces` 会包含固定 IPv4 配置，并追加：

```text
iface <iface> inet6 auto
```

- `inet6 auto` 使用 SLAAC；如果网络使用 DHCPv6，可改为 `inet6 dhcp`。
- `--ip6-auto` 不能和 `--ip6-addr`、`--ip6-mask`、`--ip6-gate`、`--noipv6` 同时使用。
- 如果当前机器没有可用的固定 IPv4，脚本会提示必须提供 IPv4，因为安装器需要 IPv4 才能继续。

其他网络参数：

```bash
--dev-net        # 安装器内核禁用可预测网卡名，使用 eth0 这类名称
--noipv6         # 安装器和目标系统都不配置 IPv6
```

---

### SSH 端口与串口控制台

```bash
-port <port>
```

修改新系统的 SSH 端口，默认是 `22`。

```bash
bash InstallNET.sh -v 13 -p 'MyStrongPassword' -port 2222
```

```bash
-console <console>
```

给安装器内核追加串口控制台参数，适合 KVM/IPMI 串口安装。

```bash
bash InstallNET.sh -v 13 -console 'ttyS0,115200n8'
```

### 镜像

```bash
--mirror <url>
```

兼容别名：

```bash
-apt <url>
-yum <url>
```

指定 Debian 镜像。默认使用：

```text
https://deb.debian.org/debian
```

旧版本会自动尝试：

```text
https://archive.debian.org/debian
```

示例：

```bash
bash InstallNET.sh -v 13 --mirror https://deb.debian.org/debian
```

默认要求 HTTPS。使用 HTTP 或 FTP 镜像时必须加 `--insecure`。

---

### 固件

```bash
-firmware
```

下载并加载 Debian 非自由固件，适用于需要闭源网卡/无线网卡驱动的机器。

```bash
bash InstallNET.sh -v 13 -firmware
```

---

### swap 分区

```bash
--swap <size>
```

创建指定大小的独立 swap 分区。

支持单位：

```bash
--swap 512M
--swap 2G
--swap 2048
```

不带单位时按 MB 计算。

示例：

```bash
bash InstallNET.sh -v 13 -p 'MyStrongPassword' --swap 2G
```

说明：

- `--swap` 使用 `partman-auto/expert_recipe` 创建真实分区。
- BIOS + GPT 会创建 `biosgrub` 分区。
- UEFI 会创建 EFI 分区。
- 会创建约 512MB 的 `/boot`、指定大小的 swap、以及占满剩余空间的 `/`。
- 脚本会检查磁盘容量，空间不足时在安装前报错。
- 不传 `--swap` 时，使用 Debian 默认的 `atomic` 自动分区方案，该方案本身可能自动创建 swap。
- `--swap` 不能与 `-dd/--image` 一起使用，因为 raw 镜像会覆盖分区表。
- 使用 `--loader` 时，UEFI/BIOS 判断基于当前主机；如果要在另一台机器上启动，请确认目标机器固件模式一致。

---

### 磁盘选择

脚本默认选择第一块非移动磁盘。强烈建议明确指定：

```bash
--disk /dev/vda
--disk /dev/sda
--disk /dev/nvme0n1
```

如果不加 `--yes`，脚本会在重启前显示完整安装摘要，并询问是否继续。你可以在提示中确认磁盘、主机名、IPv4、IPv6、DNS、swap 和密码等设置。

```bash
--yes
```

跳过所有交互提示和磁盘确认。非交互环境下（没有 TTY）脚本也会自动跳过提示，但会打印安装摘要。

---

### 只生成配置

```bash
--dry-run
```

只下载/解压安装器文件并生成配置，然后打印：

- 生成的 preseed
- 生成的 GRUB 菜单项
- 其他关键配置

不会修改 `/boot`、GRUB 或磁盘。

示例：

```bash
bash InstallNET.sh -v 13 --swap 2G --dry-run --yes
```

注意：

- dry-run 仍会访问网络下载安装器文件。
- 输出中包含 root 密码哈希，请避免公开日志。
- 非交互环境下建议加 `--yes`，避免等待确认。

---

### 安装后执行命令

```bash
--post-install-cmd '<command>'
```

在新系统第一次开机后，以 root 权限执行一次指定命令。

示例：

```bash
bash InstallNET.sh -v 13 -p 'MyStrongPassword' \
  --post-install-cmd 'apt update && apt install -y curl'
```

实现方式：

- 命令写入新系统的 `/root/post-install.sh`。
- 创建 `/etc/systemd/system/post-install.service`。
- 首次开机执行一次。
- 输出写入 `/var/log/post-install.log`。
- 执行后禁用该 systemd 服务。
- 不使用 base64，不隐藏，不自动删除脚本。

如果不传这个参数，不会写入任何安装后命令。

注意：该功能依赖目标系统使用 systemd。Debian 6/7 等老系统如果使用 sysvinit，安装后命令不会自动执行，可以登录后手动运行 `/root/post-install.sh`。

---

### 安全模式

```bash
--insecure
```

默认情况下脚本会：

- 只接受 HTTPS 镜像；
- 校验证书；
- 要求 Debian 包签名校验。

使用 `--insecure` 后会：

- 允许 HTTP / FTP 镜像；
- 下载时加 `--no-check-certificate`；
- 在 preseed 中设置 `debian-installer/allow_unauthenticated true`。

仅建议用于：

- Debian 6-10 等 EOL 版本；
- 自建 HTTP 镜像；
- 证书或旧签名导致默认安全模式失败的环境。

示例：

```bash
bash InstallNET.sh -v 10 --insecure
```

---

### DD 镜像模式

```bash
-dd, --image <url>
```

下载一个 **gzip 压缩的镜像**，写入目标磁盘。

```bash
--image-sha256 <hash>
```

校验下载的镜像文件 SHA-256。

```bash
-rdp <port>
```

在安装的 Windows 镜像中启用 RDP。

示例：

```bash
bash InstallNET.sh -dd 'https://example.com/windows.img.gz' \
  --image-sha256 '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
```

说明：

- 镜像必须是 gzip 压缩格式，脚本会 `gunzip -dc` 后写入磁盘。
- 默认要求 HTTPS 镜像地址，HTTP 需要 `--insecure`。
- 使用 `--image-sha256` 时，镜像会先下载到安装器环境的 `/tmp`，需要足够的内存/临时空间。
- 校验依赖安装器环境中的 `sha256sum`（通常由 busybox 提供）。如果环境缺少该命令，建议不要使用 `--image-sha256`，改用不带校验的流式写入。
- RDP 加固行为：
  - 仅开放 TCP 端口；
  - 保持 NLA 开启；
  - 使用 `netsh advfirewall`；
  - 只有传 `-rdp` 才启用。
- 如果不使用 `-rdp`，不会自动开启 Windows 远程桌面和防火墙端口。

---

### Loader 模式

```bash
--loader
```

不修改当前系统的 GRUB，而是把生成的 `initrd.img` 和 `vmlinuz` 放到：

```text
~/loader/
```

适用于你需要手动把文件复制到另一台机器、自行配置引导的场景。

示例：

```bash
bash InstallNET.sh -v 13 --loader --swap 1G
```

注意：loader 模式仍然会在当前主机检测磁盘，并把磁盘名写入 preseed。如果目标机器的磁盘名不同，请确认设备名一致，或在目标机器上重新生成配置。

---

### 兼容旧参数

以下参数为了兼容旧脚本保留，会被接受但忽略：

```bash
-a, --auto
-m, --manual
-ssl
```

---

## 常用组合命令

### 1. 最简安装：自动检测 + 重启前确认

```bash
bash InstallNET.sh -v 13
```

### 2. 自定义 root 密码

```bash
bash InstallNET.sh -v 13 -p 'MyStrongPassword'
```

### 3. 自定义密码 + 2GB swap

```bash
bash InstallNET.sh -v 13 -p 'MyStrongPassword' --swap 2G
```

### 4. 指定磁盘并跳过所有提示

```bash
bash InstallNET.sh -v 13 -p 'MyStrongPassword' \
  --disk /dev/vda --yes
```

### 5. 指定磁盘 + swap + 静态 IPv4

```bash
bash InstallNET.sh -v 13 -p 'MyStrongPassword' \
  --disk /dev/vda --yes \
  --swap 2G \
  --ip-addr 203.0.113.10 \
  --ip-mask 24 \
  --ip-gate 203.0.113.1 \
  --ip-dns '1.1.1.1 8.8.8.8'
```

### 6. 静态 IPv4 + 静态 IPv6

```bash
bash InstallNET.sh -v 13 -p 'MyStrongPassword' \
  --ip-addr 203.0.113.10 \
  --ip-mask 24 \
  --ip-gate 203.0.113.1 \
  --ip6-addr 2001:db8::10 \
  --ip6-mask 64 \
  --ip6-gate 2001:db8::1 \
  --ip-dns 1.1.1.1 \
  --ip6-dns 2606:4700:4700::1111
```

### 7. 静态 IPv4 + IPv6 自动获取

```bash
bash InstallNET.sh -v 13 -p 'MyStrongPassword' \
  --ip-addr 203.0.113.10 \
  --ip-mask 24 \
  --ip-gate 203.0.113.1 \
  --ip-dns 1.1.1.1 \
  --ip6-auto \
  --swap 2G
```

### 8. IPv4 和 IPv6 都自动获取

```bash
bash InstallNET.sh -v 13 -p 'MyStrongPassword' \
  --dhcp \
  --swap 2G
```

### 9. IPv4 自动获取，不配置 IPv6

```bash
bash InstallNET.sh -v 13 -p 'MyStrongPassword' \
  --dhcp --noipv6 \
  --swap 1G
```

### 10. 指定网卡、主机名、域名和多个 DNS

```bash
bash InstallNET.sh -v 13 -p 'MyStrongPassword' \
  --interface eth0 \
  --hostname vps1 \
  --domain example.com \
  --ip-addr 203.0.113.10 \
  --ip-mask 24 \
  --ip-gate 203.0.113.1 \
  --ip-dns '1.1.1.1 8.8.8.8'
```

### 11. 修改 SSH 端口 + 串口控制台

```bash
bash InstallNET.sh -v 13 -p 'MyStrongPassword' \
  -port 2222 \
  -console 'ttyS0,115200n8'
```

### 12. Debian 12 + 固件 + 自定义镜像

```bash
bash InstallNET.sh -v 12 -p 'MyStrongPassword' \
  -firmware \
  --mirror https://deb.debian.org/debian
```

### 13. EOL 版本 Debian 10

```bash
bash InstallNET.sh -v 10 --insecure -p 'MyStrongPassword'
```

### 14. 安装后自动执行命令

```bash
bash InstallNET.sh -v 13 -p 'MyStrongPassword' \
  --post-install-cmd 'apt update && apt install -y curl'
```

### 15. 只生成并检查配置，不改系统

```bash
bash InstallNET.sh -v 13 --swap 2G --dry-run --yes
```

### 16. 从 stdin 读取密码

```bash
printf '%s\n' 'MyStrongPassword' | \
  bash InstallNET.sh -v 13 --password-stdin --swap 2G
```

### 17. 指定架构

```bash
bash InstallNET.sh -v 13 --arch amd64 -p 'MyStrongPassword'
```

### 18. DD Windows 镜像 + SHA-256 校验 + RDP

```bash
bash InstallNET.sh -dd 'https://example.com/windows.img.gz' \
  --image-sha256 '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef' \
  -rdp 13389
```

### 19. Loader 模式

```bash
bash InstallNET.sh -v 13 --loader --swap 1G
```

### 20. 使用镜像兼容别名

```bash
bash InstallNET.sh -v 13 -apt https://deb.debian.org/debian
bash InstallNET.sh -v 13 -yum https://deb.debian.org/debian
```

### 21. 使用兼容旧参数

```bash
bash InstallNET.sh -v 13 -a -m -ssl
```

> `-a`、`-m`、`-ssl` 不会改变脚本行为，仅用于兼容旧调用方式。

---

## 工作原理简述

1. 检测当前系统的主机名、IPv4、IPv6、DNS、磁盘和 GRUB。
2. 在重启前显示安装摘要，允许用户确认或修改配置。
3. 从 Debian 镜像下载 netboot 的 `linux` 和 `initrd.gz`。
4. 解压 initrd。
5. 生成 `preseed.cfg`，写入：
   - 网络配置（静态 IPv4/IPv6 或 DHCP/SLAAC）；
   - root 密码；
   - 镜像地址；
   - 分区方案（普通分区或自定义 swap 分区）；
   - SSH 配置；
   - 可选安装后命令。
6. 把 preseed 和新文件重新打包进 initrd。
7. 把新内核和 initrd 复制到 `/boot`。
8. 在 GRUB 中插入一个一次性的安装菜单项。
9. 重启后进入 Debian 安装器完成安装。

---

## 故障排查

### 找不到 GRUB

脚本会检查 `/boot` 下的 `grub.cfg` 或 `grub.conf`。如果系统使用 systemd-boot、EFI stub 或其他引导方式，可能无法使用本脚本。

### 找不到镜像

- 检查网络。
- 检查 `--mirror` 地址。
- EOL 版本尝试加 `--insecure`。
- 确认该 Debian 版本和架构确实提供 netboot 安装器。

### 安装器卡在网络配置

- 手动指定 `--ip-addr`、`--ip-mask`、`--ip-gate`、`--ip-dns`。
- IPv6 环境检查 `--ip6-addr`、`--ip6-mask`、`--ip6-gate`、`--ip6-dns`。
- 确认网关和 DNS 可达。
- 多网卡环境使用 `-i` 指定网卡。
- IPv6-only 安装必须提供 IPv6 网关。

### IPv6 没有写入新系统

- 脚本通过 ifupdown 的 `/etc/network/interfaces` 写入 IPv6 配置。
- 如果新系统使用 systemd-networkd、NetworkManager 或其他网络管理方式，需要登录后手动配置。
- 如果目标系统已经在安装阶段配置了 `iface ... inet6`，脚本会跳过追加，避免重复。

### 磁盘空间不足

使用 `--swap` 时，脚本会要求至少：

```text
swap 大小 + 512MB /boot + 2048MB / + 余量
```

UEFI 还会额外需要 EFI 分区空间。

### 旧版本安装失败

Debian 6-10 已 EOL，镜像可能迁移到 `archive.debian.org`，签名也可能过期。尝试：

```bash
--insecure
```

### DD 模式失败

- 确认镜像是 gzip 格式。
- 确认镜像地址可访问。
- 使用 `--image-sha256` 时，确认哈希是压缩文件的 SHA-256。
- 检查安装器环境的 `/tmp` 空间。

---

## 安全说明

本次重构修复了原脚本中的以下高风险问题：

| 原问题 | 处理 |
|---|---|
| 默认 root 密码公开 | 保留默认值 `a59~12`，但支持 `-p` 覆盖；安装后应立即修改 |
| MD5 crypt 密码哈希 | 优先使用 SHA-512 crypt |
| 默认关闭包签名校验 | 默认开启，仅 `--insecure` 关闭 |
| 默认关闭 TLS 证书校验 | 默认开启，仅 `--insecure` 关闭 |
| 隐藏式 root 持久化 | 移除 `@reboot` + base64 + 自删逻辑，改为透明 systemd 服务 |
| RDP 弱化 | 仅开放 TCP、保持 NLA、使用 `netsh advfirewall`、仅 `-rdp` 时启用 |
| DD 镜像无校验 | 支持 `--image-sha256`，默认要求 HTTPS |
| 自动选盘无确认 | 支持 `--disk`，默认显示磁盘并等待确认 |

仍然需要注意：

- 默认密码是公开的，公网机器必须修改。
- `--insecure` 会降低安全性，只在明确需要时使用。
- `--post-install-cmd` 会以 root 执行命令，请只使用可信内容。
- 脚本会擦除磁盘，执行前必须确认 `--disk`。

---

## 已移除的参数

以下参数已移除，因为脚本现在只支持 Debian：

```text
-d, --debian
-u, --ubuntu
-c, --centos
```

使用旧参数会直接报错并提示新的写法。

---

## 版本变更摘要

- 默认 Debian 版本更新为 13（trixie）。
- 新增 Debian 14（forky）支持。
- 移除 Ubuntu / CentOS 安装逻辑。
- 新增 `--arch`。
- 新增主机名、域名自动检测和 `--hostname` / `--domain` 参数。
- 新增 IPv4 / IPv6 自动检测和 IPv6 配置参数。
- 新增 `--dhcp`：IPv4 DHCP + IPv6 SLAAC/DHCPv6 自动获取，并写入 `/etc/network/interfaces`。
- 新增 `--ip6-auto` / `--dhcp6`：IPv4 固定、IPv6 自动获取。
- 新增重启前的安装摘要和交互确认。
- 新增 `--swap` 真实 swap 分区。
- 新增 `--disk`、`--yes`。
- 新增 `--post-install-cmd`。
- 新增 `--insecure`。
- 新增 `--dry-run`。
- 新增 `--image-sha256`。
- 默认启用 HTTPS 和包签名校验。
- RDP 配置加固。
- 移除隐藏式 root 持久化。
