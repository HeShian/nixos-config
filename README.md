# ❄️ Westwood NixOS 配置

HeShian 的个人 NixOS 配置，采用 Flake + Home Manager 模块化架构。

| 主机 | 架构 | 状态版本 | 频道 |
|------|------|----------|------|
| westwood | x86_64-linux | 25.11 | nixpkgs-unstable |

## 硬件配置

| 组件 | 型号 |
|------|------|
| CPU | Intel (Kaby Lake, UHD 610 iGPU) |
| GPU | NVIDIA GeForce GTX 1650 Ti Mobile (Turing) |
| 方案 | PRIME Render Offload（默认集显，按需 `nvidia-offload` 调用独显） |
| 内存 | 16 GB |
| 存储 | NVMe SSD |

## 快速部署

### 前提条件

- 已安装 NixOS（可参考 [nixos.org](https://nixos.org/download)）
- 已启用 Flake 支持（NixOS 24.11+ 默认开启）

### 部署步骤

```bash
# 1. 克隆仓库
sudo mv /etc/nixos /etc/nixos.bak  # 备份原有配置
sudo git clone https://github.com/HeShian/nixos-config.git /etc/nixos

# 2. 生成硬件配置（宿主机）
sudo nixos-generate-config --show-hardware-config > /tmp/hardware-configuration.nix
# 将生成的 hardware-configuration.nix 替换到 hosts/westwood/ 下

# 3. 重建系统（NixOS + Home Manager 一起部署）
sudo nixos-rebuild switch --flake /etc/nixos#westwood

# 4. 安装 Flatpak 应用（系统级已配置好 USTC 镜像源）
flatpak install flathub cn.wps.wps_365
flatpak install flathub eu.betterbird.Betterbird
flatpak install flathub io.github.kolunmi.Bazaar

# 5. 复现 DMS 桌面 Shell 配置
cp /etc/nixos/reference/dms/settings.json ~/.config/DankMaterialShell/settings.json
cp /etc/nixos/reference/dms/firefox.css    ~/.config/DankMaterialShell/firefox.css
```

> **注意**：`hardware-configuration.nix` 由 `nixos-generate-config` 根据实际硬件自动生成，
> 每台机器的文件系统 UUID、内核模块列表等都不同，**部署前必须重新生成**。

### 日常维护

```bash
# 系统 + 用户配置一起更新（需要 sudo）
sudo nixos-rebuild switch --flake /etc/nixos#westwood

# 仅更新用户级配置（不需要 sudo）
home-manager switch --flake /etc/nixos#claudia

# 干运行（验证配置不实际变更）
sudo nixos-rebuild dry-activate --flake /etc/nixos#westwood

# 更新 flake.lock（所有依赖）
sudo nix flake update

# 更新单个输入
sudo nix flake update nixpkgs
```

## 目录结构

```
/etc/nixos/
├── flake.nix                      # 🔰 Flake 入口 —— 声明 inputs + outputs
├── flake.lock                     # 依赖锁定文件（自动生成）
├── opencode.jsonc                 # ✨ OpenCode AI 配置（含 nixos MCP + skills 注册）
├── AGENTS.md                      # AI 助手行为指南
├── .gitignore
├── .opencode/skills/              # 📖 项目级 skill（AI 行为规范）
│   └── nixos-config-guide.md      #   目录结构 + 中文注释规范
├── hosts/westwood/                # 🖥️ 主机系统配置
│   ├── configuration.nix          #   系统入口（import 所有子模块）
│   ├── hardware-configuration.nix #   [自动生成] 硬件配置（勿修改代码，可加注释头）
│   ├── networking.nix             #   网络：主机名、NetworkManager、SSH
│   ├── locale.nix                 #   本地化：时区、Locale、Fcitx5+Rime 输入法
│   ├── hardware.nix               #   硬件：systemd-boot、NVIDIA Optimus、蓝牙、zram+swap
│   ├── desktop.nix                #   桌面：GDM、niri WM、DMS Shell、PipeWire
│   ├── packages.nix               #   系统级软件包 + 服务（Firefox/Steam/libvirtd/daed）
│   └── flatpak.nix                #   Flatpak + 中科大 USTC 镜像
├── home/claudia/                  # 👤 用户 claudia 配置
│   ├── default.nix                #   HM 入口（imports + home.packages + MPV 配置）
│   ├── shell.nix                  #   fish + starship + zoxide + kitty
│   ├── git.nix                    #   Git 配置（用户信息、别名、忽略规则）
│   ├── nvim.nix                   #   CookNixvim（基于 Nixvim 的模块化 Neovim）
│   ├── niri.nix                   #   niri WM 键绑定 + 窗口规则 + 动画（KDL）
│   ├── fcitx5.nix                 #   Fcitx5 输入法 + DMS 动态配色同步
│   ├── fuzzel.nix                 #   Fuzzel 启动器 + DMS 配色同步
│   ├── gtk-sync.nix               #   DMS → GTK 深浅主题同步 + Remmina 包装
│   ├── dms-fix.nix                #   DMS 启动主题修复（自动深浅切换）
│   ├── xdg.nix                    #   XDG 基础（mimeapps、user-dirs、Xresources）
│   ├── packages.nix               #   用户级软件包
│   ├── mpv.nix                    #   MPV 视频播放器配置
│   └── thunar.nix                 #   Thunar 桌面集成（exo-open、xfconf）
├── modules/                       # 📦 可复用模块
│   ├── nixos/                     #   NixOS 系统模块（跨主机复用）
│   │   └── common.nix             #     通用配置：镜像源、用户、sudo 免密、Nix GC
│   └── home/                      #   Home Manager 模块（跨用户复用）
├── overlays/                      # 🧩 软件包覆盖
│   └── default.nix                #   openldap 修补 + 引入自定义包
├── pkgs/                          # 📦 自定义包
│   ├── default.nix                #   包集合入口（overlay 形式）
│   └── bilibili-tui/              #   B 站 TUI 客户端（Rust）
│       └── default.nix
├── lib/                           # 🔧 自定义辅助函数库
│   └── default.nix
├── secrets/                       # 🔒 敏感配置（占位，未来用于 agenix/sops-nix）
│   └── .gitkeep
└── reference/                     # 参考文件（非 Nix 管理）
    └── dms/                       # DMS (DankMaterialShell) 配置
        ├── settings.json
        └── firefox.css
```

## 桌面环境

此配置使用 GDM 作为登录管理器：

| 层次 | 组件 | 说明 |
|------|------|------|
| 登录管理器 | GDM | 图形登录界面 |
| 窗口管理器 | niri (Scrollable-tiling) | Wayland 合成器，Vim 风格快捷键 |
| 桌面 Shell | DMS (DankMaterialShell) | 运行在 niri 之上的动态主题 Shell |
| 音频 | PipeWire + WirePlumber | 兼容 ALSA/PulseAudio |
| 文件管理器 | Thunar | 轻量 Xfce 文件管理器 |
| 应用启动器 | fuzzel | Mod+Z 启动 |

### niri 快捷键

| 快捷键 | 功能 |
|--------|------|
| Mod+T | 打开终端（Kitty） |
| Mod+Q | 关闭窗口 |
| Mod+H/J/K/L | 焦点移动（Vim 风格） |
| Mod+Shift+H/J/K/L | 窗口移动 |
| Mod+F | 最大化列 |
| Mod+1~9 | 切换工作区 |
| Mod+R | 切换列宽度预设 |
| Mod+V | 切换窗口浮动 |
| Mod+Z | 应用启动器（fuzzel） |
| Mod+Alt+A | 截图 |
| Print | 截图 |
| Mod+Shift+S | 截图标注（grim + satty） |

## 添加软件包

```bash
# 系统级（所有用户可用）
# 编辑 hosts/westwood/packages.nix → environment.systemPackages

# 用户级（仅 claudia，无需 sudo）
# 编辑 home/claudia/default.nix → home.packages

# Flatpak 应用（系统级已配好 USTC 镜像源）
flatpak install flathub <应用ID>
```

## Flatpak 应用

以下 Flatpak 应用通过 `flatpak install flathub` 手动安装（不在 Nix 管理范围内）：

| 应用 | ID | 说明 |
|------|-----|------|
| WPS 365 | `cn.wps.wps_365` | WPS Office 办公套件 |
| Betterbird | `eu.betterbird.Betterbird` | 邮件客户端（Thunderbird 分支） |
| Bazaar | `io.github.kolunmi.Bazaar` | 应用发现与管理工具 |

安装命令见上方「部署步骤」第 4 步。

## DMS 配置复现

DMS（DankMaterialShell）的完整配置保存在 `reference/dms/` 目录中，文件清单：

| 文件 | 目标位置 | 说明 |
|------|----------|------|
| `reference/dms/settings.json` | `~/.config/DankMaterialShell/settings.json` | DMS 全部设置（主题、布局、插件等） |
| `reference/dms/firefox.css` | `~/.config/DankMaterialShell/firefox.css` | Firefox 动态主题 CSS（matugen 生成） |

**复现方法**：新机器上 clone 仓库后，将参考文件复制到 DMS 配置目录：

```bash
mkdir -p ~/.config/DankMaterialShell
cp /etc/nixos/reference/dms/settings.json ~/.config/DankMaterialShell/settings.json
cp /etc/nixos/reference/dms/firefox.css    ~/.config/DankMaterialShell/firefox.css
```

复制后重新登录或重启 DMS 即可还原当前全部 DMS 桌面 Shell 配置（包括状态栏布局、动态主题、快捷键、字体等 500+ 项设置）。

## 自定义包

自定义包位于 `pkgs/` 目录，通过 `overlays/default.nix` 注入 nixpkgs：

- **bilibili-tui**：GitHub 上的 Rust 终端 B 站客户端，从源码构建

添加步骤：
1. 在 `pkgs/` 下创建包目录和 `default.nix`
2. 在 `pkgs/default.nix` 中注册
3. `overlays/default.nix` 会自动引入

## 重要约束

- **`hosts/westwood/hardware-configuration.nix`**：自动生成，**禁止手动编辑**
- **`stateVersion`** 设为 `25.11`，**禁止修改**
- **Home Manager** 接管以下文件，手动修改会被覆盖：
  - `~/.bashrc`
  - `~/.config/fish/`
  - `~/.config/git/config`
  - `~/.config/niri/config.kdl`
  - `~/.config/kitty/kitty.conf`
  - `~/.Xresources`
  - `~/.config/mpv/mpv.conf`
  - `~/.config/mimeapps.list`
  - `~/.config/user-dirs.dirs`
- **Overlay**：`openldap` 跳过了测试（`test017-syncreplication-refresh` 不稳定会导致 lutris 构建失败）
- **fuzzel** 同时安装在系统级和用户级（系统级确保 PATH 可见）
- **Qt 主题**通过 niri 环境变量 `QT_QPA_PLATFORMTHEME=gtk3` 控制
- **蓝牙**由 DMS 通过 bluez 直接管理（未安装 blueman）
- **Portal 后端**使用 GNOME 的 xdg-desktop-portal-gnome

## 常见问题

### Flatpak 安装失败 "无法从不信任的远程仓库提取"

此配置已内置修复：开机时自动下载 Flathub GPG 公钥并启用签名验证。

如果仍然遇到，可手动修复：
```bash
sudo flatpak remote-delete flathub --system
curl -sL https://flathub.org/repo/flathub.gpg -o /tmp/flathub.gpg
sudo flatpak remote-add --gpg-import=/tmp/flathub.gpg --system flathub https://mirrors.ustc.edu.cn/flathub
sudo flatpak remote-modify --url=https://mirrors.ustc.edu.cn/flathub flathub
```

### 输入法无法使用

确认 Fcitx5 环境变量已设置：
```bash
echo $GTK_IM_MODULE  # 应是 fcitx
echo $QT_IM_MODULE   # 应是 fcitx
```

如果未生效，重新登录或检查 niri 环境变量配置。

Fcitx5 候选框主题会自动跟随 DMS 壁纸配色（通过 `dms-fcitx5-sync` 服务），
切换壁纸或深浅模式后 1-2 秒内自动更新。如果主题未跟随变化，手动运行：
```bash
~/.local/bin/dms-fcitx5-sync
```

### NVIDIA 独显无法调用

使用 `nvidia-offload` 命令：
```bash
nvidia-offload glxinfo | grep "OpenGL renderer"
```

如果命令不存在，确认 `hardware.nix` 中 `offload.enableOffloadCmd = true`。

### 代理服务

系统安装了两种代理：

| 工具 | 类型 | 管理地址 |
|------|------|----------|
| v2raya | 用户态代理 | — |
| daed | eBPF 内核态代理 | http://localhost:2023 |

两者互不干扰，可同时运行。

## 参考

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [niri WM Wiki](https://github.com/YaLTeR/niri/wiki)
- [DMS (DankMaterialShell)](https://github.com/nicemachine/DankMaterialShell)
- [CookNixvim](https://github.com/Youthdreamer/CookNixvim)
