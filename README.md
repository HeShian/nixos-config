# ❄️ Westwood — 模块化 NixOS 配置

基于 Flake + Home Manager 的个人 NixOS 配置，遵循声明式、可复现的原则。
配置涵盖系统引导、硬件驱动、桌面环境、终端工具链、输入法、动态主题等全栈体验。

| 主机 | 架构 | 状态版本 | nixpkgs 频道 |
|------|------|----------|-------------|
| westwood | x86_64-linux | 25.11 | unstable |

## 目录

- [硬件概览](#硬件概览)
- [快速开始](#快速开始)
- [桌面环境](#桌面环境)
- [项目结构](#项目结构)
- [添加软件包](#添加软件包)
- [Flatpak 应用](#flatpak-应用)
- [DMS 配置复现](#dms-配置复现)
- [自定义包](#自定义包)
- [约束与注意事项](#约束与注意事项)
- [常见问题](#常见问题)
- [参考](#参考)

## 硬件概览

| 组件 | 型号 |
|------|------|
| CPU | Intel (Kaby Lake, UHD 610 iGPU) |
| GPU | NVIDIA GeForce GTX 1650 Ti Mobile (Turing) |
| 方案 | PRIME Render Offload — 默认集显，`nvidia-offload` 按需调用独显 |
| 内存 | 16 GB |
| 存储 | NVMe SSD |

## 快速开始

### 前置条件

- 已安装 NixOS（参考 [nixos.org](https://nixos.org/download)）
- 已启用 Flake 支持（NixOS 24.11+ 默认开启）
- 具备 `sudo` 权限

### 第一次部署

```bash
# 1. 备份原有配置
sudo mv /etc/nixos /etc/nixos.bak

# 2. 克隆本仓库
sudo git clone https://github.com/HeShian/nixos-config.git /etc/nixos

# 3. 生成本机硬件配置（每台机器必须重新生成）
sudo nixos-generate-config --show-hardware-config \
  > /tmp/hardware-configuration.nix
sudo cp /tmp/hardware-configuration.nix \
  /etc/nixos/hosts/westwood/hardware-configuration.nix

# 4. 重建系统（NixOS + Home Manager 一并部署）
sudo nixos-rebuild switch --flake /etc/nixos#westwood

# 5. 安装 Flatpak 应用
flatpak install -y flathub \
  cn.wps.wps_365 \
  eu.betterbird.Betterbird \
  io.github.kolunmi.Bazaar \
  com.github.tchx84.Flatseal \
  net.eudic.dict

# 6. 复现 DMS 桌面 Shell 配置
mkdir -p ~/.config/DankMaterialShell
cp /etc/nixos/reference/dms/settings.json ~/.config/DankMaterialShell/
cp /etc/nixos/reference/dms/firefox.css    ~/.config/DankMaterialShell/
```

> **⚠️ 关键提示**：`hardware-configuration.nix` 包含磁盘 UUID、内核模块列表等机器特有信息，
> 由 `nixos-generate-config` 根据实际硬件自动生成。**每台机器部署前必须重新生成此文件**，
> 否则可能导致系统无法引导。

### 日常维护

```bash
# 拉取最新配置并重建系统
cd /etc/nixos
git pull
sudo nixos-rebuild switch --flake /etc/nixos#westwood

# 仅更新用户级配置（无需 sudo）
home-manager switch --flake /etc/nixos#claudia

# 干运行 —— 验证配置语法，不实际变更
sudo nixos-rebuild dry-activate --flake /etc/nixos#westwood

# 更新 flake.lock（所有依赖）
sudo nix flake update

# 更新单个输入
sudo nix flake update nixpkgs
```

## 桌面环境

Westwood 的桌面从底层到上层由以下组件构成：

| 层次 | 组件 | 职责 |
|------|------|------|
| 登录管理器 | GDM | 图形登录界面 |
| 窗口管理器 | niri | Scrollable-tiling Wayland 合成器，Vim 风格快捷键 |
| 桌面 Shell | DMS (DankMaterialShell) | 动态主题 Shell，材质设计风格 |
| 音频 | PipeWire + WirePlumber | 兼容 ALSA / PulseAudio / JACK |
| 文件管理器 | Thunar | 轻量 Xfce 文件管理器 |
| 应用启动器 | fuzzel | Mod+Z 唤起，Wayland 原生 |

### niri 常用快捷键

| 快捷键 | 功能 |
|--------|------|
| `Mod+Return` | 打开 Ghostty 终端 |
| `Mod+T` | 打开 Kitty 终端 |
| `Mod+Z` | 应用启动器 (fuzzel) |
| `Mod+B` | Firefox 浏览器 |
| `Mod+Q` | 关闭窗口 |
| `Mod+H/J/K/L` | 焦点移动（Vim 风格） |
| `Mod+Ctrl+H/J/K/L` | 窗口移动 |
| `Mod+F` | 最大化列 |
| `Mod+V` | 切换窗口浮动 |
| `Mod+R` | 切换列宽预设 |
| `Mod+1~9` | 切换工作区 |
| `Mod+U / Mod+I` | 工作区上下切换 |
| `Mod+O / Mod+G` | 概览模式 |
| `Mod+Alt+A / Print` | 区域截图 |
| `Mod+Shift+S` | 截图并标注 (grim + satty) |
| `Mod+Alt+V` | 剪贴板历史 (cliphist + fuzzel) |

## 项目结构

```
/etc/nixos/
├── flake.nix                    # 🔰 Flake 入口 — inputs + outputs
├── flake.lock                   # 依赖锁定（自动生成）
├── AGENTS.md                    # AI 助手行为指南
├── hosts/westwood/              # 🖥️ 主机系统配置（westwood）
│   ├── configuration.nix        #   系统入口，imports 所有子模块
│   ├── hardware-configuration.nix # [自动生成] 硬件 — 禁止编辑
│   ├── boot.nix                 #   systemd-boot UEFI 引导
│   ├── nvidia.nix               #   NVIDIA Optimus PRIME 混合显卡
│   ├── bluetooth.nix            #   bluez 蓝牙协议栈
│   ├── swap.nix                 #   zram + swapfile 交换空间
│   ├── networking.nix           #   主机名、NetworkManager、SSH
│   ├── locale.nix               #   时区、locale、Fcitx5+Rime 输入法
│   ├── desktop.nix              #   GDM、niri WM、DMS Shell、Qt、Portal
│   ├── pipewire.nix             #   PipeWire + WirePlumber 音频
│   ├── thunar.nix               #   Thunar 文件管理器
│   ├── fonts.nix                #   字体 + fontconfig 渲染
│   ├── packages.nix             #   系统级软件包
│   ├── services.nix             #   系统服务（libvirtd / daed / v2raya）
│   └── flatpak.nix              #   Flatpak + USTC 镜像
├── home/claudia/                # 👤 用户 claudia 配置
│   ├── default.nix              #   HM 入口，imports + 基本设置
│   ├── shell.nix                #   fish + starship + zoxide + kitty
│   ├── ghostty.nix              #   Ghostty 终端（GPU 加速 + 光标拖尾）
│   ├── fastfetch.nix            #   Fastfetch 系统信息（Catnap 风格）
│   ├── git.nix                  #   Git 全局配置
│   ├── nvim.nix                 #   CookNixvim Neovim 发行版
│   ├── niri.nix                 #   niri WM 键绑定 + 窗口规则 + 动画
│   ├── xdg.nix                  #   XDG 基础（mimeapps / user-dirs / Xresources）
│   ├── fcitx5.nix               #   Fcitx5 输入法 + DMS 配色同步
│   ├── fuzzel.nix               #   Fuzzel 启动器 + DMS 配色同步
│   ├── gtk-sync.nix             #   DMS → GTK 深浅主题同步
│   ├── dms-fix.nix              #   DMS 启动主题修复
│   ├── packages.nix             #   用户级软件包
│   ├── mpv.nix                  #   MPV 视频播放器（硬解 + 弹幕）
│   └── thunar.nix               #   Thunar 桌面集成
├── modules/                     # 📦 可复用模块
│   ├── nixos/common.nix         #   镜像源 / 用户 / sudo / Nix GC
│   └── home/                    #   Home Manager 模块（预留）
├── overlays/                    # 🧩 包覆盖（openldap 修补等）
├── pkgs/                        # 📦 自定义包（bilibili-tui）
├── lib/                         # 🔧 辅助函数库（预留）
├── reference/                   # 📄 参考文件（DMS settings.json 等）
└── secrets/                     # 🔒 敏感配置（预留）
```

### 设计原则

- **职责分离**：每个 `.nix` 文件只管理一个功能领域
- **入口聚合**：`configuration.nix` / `default.nix` 统一 import 子模块
- **系统 vs 用户**：系统级配置在 `hosts/`，用户级在 `home/`
- **共享 vs 专属**：跨主机公用的配置提取到 `modules/`

## 添加软件包

```bash
# 系统级（所有用户可用，需 sudo 重建）
# 编辑 hosts/westwood/packages.nix → environment.systemPackages

# 用户级（仅 claudia，无需 sudo）
# 编辑 home/claudia/packages.nix → home.packages

# Flatpak 应用（系统级已配置 USTC 镜像源）
flatpak install flathub <应用ID>

# 自定义包
# 1. 创建 pkgs/<name>/default.nix
# 2. 在 pkgs/default.nix 中注册
# 3. overlays/default.nix 自动引入
```

## Flatpak 应用

以下应用通过 Flatpak 安装，独立于 Nix 包管理：

| 应用 | ID | 说明 |
|------|-----|------|
| WPS 365 | `cn.wps.wps_365` | 办公套件 |
| Betterbird | `eu.betterbird.Betterbird` | 邮件客户端（Thunderbird 分支） |
| Bazaar | `io.github.kolunmi.Bazaar` | 应用发现与管理 |
| Flatseal | `com.github.tchx84.Flatseal` | Flatpak 权限管理 |
| 欧路词典 | `net.eudic.dict` | 跨平台词典 |

安装命令见上方[第一次部署](#第一次部署)第 5 步。

## DMS 配置复现

DMS（DankMaterialShell）的完整配置保存在 `reference/dms/` 目录：

| 文件 | 目标位置 | 内容 |
|------|----------|------|
| `reference/dms/settings.json` | `~/.config/DankMaterialShell/` | 主题、布局、插件等全部设置（500+ 项） |
| `reference/dms/firefox.css` | `~/.config/DankMaterialShell/` | Firefox 动态主题 CSS（matugen 生成） |

复现命令见[第一次部署](#第一次部署)第 6 步。复制后重新登录或重启 DMS 即可还原当前桌面 Shell 配置。

## 自定义包

- **bilibili-tui**：Rust 编写的终端 B 站客户端，从源码构建。运行时依赖 mpv + yt-dlp + bdanmaku 弹幕插件。

## 约束与注意事项

| 约束 | 说明 |
|------|------|
| `hardware-configuration.nix` | 自动生成，**禁止手动编辑** |
| `stateVersion = "25.11"` | **禁止修改**，影响向后兼容行为 |
| Home Manager 接管文件 | `~/.bashrc` `~/.config/fish/` `~/.config/git/config` `~/.config/niri/config.kdl` `~/.config/kitty/kitty.conf` `~/.Xresources` `~/.config/mpv/mpv.conf` `~/.config/mimeapps.list` `~/.config/user-dirs.dirs` — 手动编辑会被覆盖 |
| NVIDIA 驱动 | 闭源内核模块（`nvidia-open` 不支持 GTX 1650 Ti） |
| sudo 免密 | `wheelNeedsPassword = false` — 方便但降低安全性 |
| 输入法 | Fcitx5 + Rime + 雾凇拼音，`GTK_IM_MODULE=fcitx` `QT_IM_MODULE=fcitx` |
| 代理 | v2raya（用户态）+ daed（eBPF 内核态，Web 面板 :2023），互不干扰 |
| overlay | `openldap` 跳过测试（`test017-syncreplication-refresh` 不稳定，导致 lutris 构建失败） |
| Nix GC | 双层策略：自动删除 >7 天旧世代，之后保留最近 3 个世代 |

## 常见问题

### Flatpak 安装失败："无法从不信任的远程仓库提取"

系统已内置修复（开机自动配置 GPG 签名验证 + USTC 镜像）。如仍失败：

```bash
sudo flatpak remote-delete flathub --system
curl -sL https://flathub.org/repo/flathub.gpg -o /tmp/flathub.gpg
sudo flatpak remote-add --gpg-import=/tmp/flathub.gpg --system flathub \
  https://mirrors.ustc.edu.cn/flathub
sudo flatpak remote-modify --url=https://mirrors.ustc.edu.cn/flathub flathub
```

### 输入法不工作

确认环境变量是否正确加载：

```bash
echo $GTK_IM_MODULE  # 应为 fcitx
echo $QT_IM_MODULE   # 应为 fcitx
```

如果未生效，重新登录或在 niri 中运行 `fcitx5 -r` 重启输入法。

Fcitx5 候选框配色会自动跟随 DMS 壁纸主题变化（通过 `dms-fcitx5-sync` 服务）。
如主题未跟随，手动触发：`~/.local/bin/dms-fcitx5-sync`

### NVIDIA 独显无法调用

```bash
nvidia-offload glxinfo | grep "OpenGL renderer"
# 应显示 NVIDIA GeForce GTX 1650 Ti
```

### 代理服务

系统内置两种代理方案，可同时运行：

| 工具 | 类型 | 管理方式 |
|------|------|----------|
| v2raya | 用户态 | 系统服务 + Web 面板 |
| daed | eBPF 内核态 | 系统服务 + Web 面板 (localhost:2023) |

## 参考

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [niri WM](https://github.com/YaLTeR/niri/wiki)
- [DMS (DankMaterialShell)](https://github.com/nicemachine/DankMaterialShell)
- [CookNixvim](https://github.com/Youthdreamer/CookNixvim)
- [Nix Flakes Wiki](https://nixos.wiki/wiki/Flakes)
