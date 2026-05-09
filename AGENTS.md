# Westwood NixOS 配置

## ⚠️ 强制性：每次配置前必须加载 skill

在修改本仓库的任何配置之前，AI 助手**必须先执行**：

```bash
skill(name="nixos-config-guide")
```

此 skill 定义了项目的目录结构、注释规范和工作流程，所有配置变更必须严格遵守。
未加载 skill 前，不得编辑任何 `.nix` 文件。

---

# Westwood NixOS 配置

## 快速命令

```bash
# 系统 + home-manager 重建（需 sudo）
sudo nixos-rebuild switch --flake /etc/nixos#westwood

# 仅用户级生效（无需 sudo）
home-manager switch --flake /etc/nixos#claudia

# 干运行（不实际变更，验证配置正确性）
sudo nixos-rebuild dry-activate --flake /etc/nixos#westwood

# 更新 flake lock
sudo nix flake update

# 查询 NixOS 包/选项 — 使用 opencode.jsonc 中配置的 nixos MCP
# 示例: 搜索包 → action=search, query=firefox
#       查选项 → action=search, query=programs.niri, type=options
#       查详情 → action=info,   query=programs.niri.enable, type=option
#       统计   → action=stats
#       频道   → action=channels
```

## 目录结构

| 路径 | 用途 | 备注 |
|---|---|---|
| `flake.nix` | 入口点 — nixosConfigurations + homeConfigurations | specialArgs 传递 inputs 给所有模块 |
| `hosts/westwood/configuration.nix` | **系统配置入口**，imports 所有子模块 | 添加新模块时在此注册 |
| `hosts/westwood/hardware-configuration.nix` | **自动生成** — 勿编辑 | `nixos-generate-config` 生成 |
| `hosts/westwood/boot.nix` | systemd-boot UEFI 引导加载器 | |
| `hosts/westwood/nvidia.nix` | NVIDIA Optimus PRIME Render Offload | iGPU + dGPU 混合显卡 |
| `hosts/westwood/bluetooth.nix` | bluez 蓝牙协议栈 | DMS 管理，未安装 blueman |
| `hosts/westwood/swap.nix` | zram (zstd, 50% RAM) + 16GiB swapfile | zswap 已禁用(与 zram 冲突) |
| `hosts/westwood/networking.nix` | 主机名、NetworkManager、SSH | |
| `hosts/westwood/locale.nix` | 时区、locale、Fcitx5+Rime 输入法 | GTK/Qt 输入法环境变量在此 |
| `hosts/westwood/desktop.nix` | GDM、niri WM、DMS Shell、Qt、Portal | **图形登录（GDM）** |
| `hosts/westwood/pipewire.nix` | PipeWire + WirePlumber 音频服务 | |
| `hosts/westwood/thunar.nix` | Thunar 文件管理器 + gvfs + dconf | |
| `hosts/westwood/fonts.nix` | 字体包 & fontconfig 渲染 | JetBrainsMono + Noto CJK + Emoji |
| `hosts/westwood/packages.nix` | 系统级软件包 | Firefox、Steam、VSCode、开发工具等 |
| `hosts/westwood/services.nix` | 系统服务 | v2raya、libvirtd、daed |
| `hosts/westwood/flatpak.nix` | Flatpak + USTC 镜像 | systemd oneshot 自动修复 Flathub GPG |
| `modules/nixos/common.nix` | 共享模块：镜像源、用户 claudia、sudo 免密、Nix GC | 所有主机通用 |
| `modules/home/` | 共享 Home Manager 模块 | 当前为空，预留扩展 |
| `home/claudia/default.nix` | 用户配置入口，imports 所有子模块 | |
| `home/claudia/shell.nix` | fish + starship + zoxide + kitty | Catppuccin Mocha Powerline 提示符 |
| `home/claudia/ghostty.nix` | Ghostty 终端模拟器 | GPU 加速，匹配 Kitty 配置 |
| `home/claudia/fastfetch.nix` | Fastfetch 系统信息显示 | Catnap 风格，终端启动自动运行 |
| `home/claudia/git.nix` | Git 配置 | 用户信息、别名、忽略规则 |
| `home/claudia/nvim.nix` | CookNixvim 外部 flake 输入 | 零污染 Neovim 配置 + 自定义快捷键 |
| `home/claudia/niri.nix` | niri WM 配置 (KDL 格式, xdg.configFile 部署) | 键绑定、窗口规则、动画、环境变量 |
| `home/claudia/xdg.nix` | XDG 基础 | mimeapps、user-dirs、Xresources |
| `home/claudia/fcitx5.nix` | Fcitx5 输入法 + DMS 动态配色同步 | 递增主题名绕过 classicui 缓存 |
| `home/claudia/fuzzel.nix` | Fuzzel 启动器 + DMS 配色同步 | systemd path 监听配色变化 |
| `home/claudia/gtk-sync.nix` | DMS → GTK 深浅主题同步 + Remmina 包装 | |
| `home/claudia/dms-fix.nix` | DMS 启动主题修复 | SIGUSR1 触发 QML 重载 |
| `home/claudia/packages.nix` | 用户级软件包 | 通讯、多媒体、游戏、工具等 |
| `home/claudia/mpv.nix` | MPV 视频播放器配置 | GPU-Next + NVDEC 硬解 + Bilibili 弹幕 |
| `home/claudia/thunar.nix` | Thunar 桌面集成 | 文件模板、uca.xml、exo-open、xfconf |
| `overlays/default.nix` | 包覆盖 — openldap 跳过测试 + thunar-archive-plugin xarchiver.tap + 引入 pkgs/ | |
| `pkgs/default.nix` | 自定义包集合（overlay 形式） | 当前: bilibili-tui |
| `pkgs/bilibili-tui/default.nix` | B 站 TUI 客户端（Rust） | |
| `lib/default.nix` | 自定义辅助函数库 | **当前为空** — 预留扩展 |
| `reference/` | 参考文件（非 Nix 管理） | DMS 的 settings.json / firefox.css |
| `secrets/` | 敏感配置占位 | 未来用于 agenix/sops-nix |

## 关键事实

- **单主机**: `westwood` (x86_64-linux), **单用户**: `claudia`
- **频道**: `nixpkgs-unstable`. Home Manager 跟随 nixpkgs (`follows = "nixpkgs"`)
- **stateVersion**: `25.11` (NixOS + HM) — **禁止修改**
- **登录管理器**: GDM（GNOME Display Manager，图形登录界面）
- **桌面会话**: niri (Scrollable-tiling Wayland 合成器) + DMS Shell (DankMaterialShell)，含动态主题
- **Shell**: fish (bash 已禁用). 提示符: starship (Catppuccin Mocha, Powerline 风格)
- **GPU**: Intel UHD 610 (iGPU) + NVIDIA GTX 1650 Ti Mobile (dGPU). PRIME Render Offload — `nvidia-offload` 命令可用. Bus IDs: `PCI:0:2:0` / `PCI:1:0:0`. Nouveau 已黑名单
- **交换空间**: zram (zstd, 50% RAM, priority 100) + 16G swapfile (priority 10). `zswap.enabled=0` 内核参数 (与 zram 冲突)
- **输入法**: Fcitx5 + Rime + rime-ice. 环境变量: `GTK_IM_MODULE=fcitx`、`QT_IM_MODULE=fcitx`、`XMODIFIERS=@im=fcitx`
- **镜像源**: USTC 主用 → Tsinghua 备用 → cache.nixos.org 回退. `auto-optimise-store = true`
- **代理**: v2raya (用户态) + daed (eBPF 内核态, Web 面板端口 2023) 共存，互不干扰
- **Neovim**: CookNixvim 外部 flake 输入 (github:Youthdreamer/CookNixvim). 系统级 neovim 包 + `EDITOR`/`VISUAL` 设置
- **允许非自由软件**: `true` (NVIDIA 驱动、Steam、opencode 等)
- **sudo 免密**: `security.sudo.wheelNeedsPassword = false`
- **Nix GC 双层策略**: ① 自动删除 >7 天的旧世代 ② 之后保留系统/用户 profile 最新 3 个世代

## 构建流程

系统级程序优先使用 NixOS 模块 (`programs.*`) 而非裸加包，以获得完整的配置集成（配置文件、D-Bus、systemd 单元）。例如：
- `programs.firefox.enable = true` 而非只加 firefox 到 systemPackages
- `programs.fish.enable = true` 确保 /etc/shells 注册

## 添加软件包

- **系统级**: `environment.systemPackages` → `hosts/westwood/packages.nix`
- **用户级**: `home.packages` → `home/claudia/packages.nix` (无需 sudo)
- **Flatpak 应用**: 手动 `flatpak install flathub <app-id>` (系统级已配好源)
- **自定义包**: 在 `pkgs/<name>/` 创建 `default.nix` → 在 `pkgs/default.nix` 注册 → `overlays/default.nix` 自动引入

## 约束与注意事项

- `/etc/nixos` 是指向 `/home/claudia/nixos-config/` 的符号链接。`nixos-rebuild switch` 在 `setting up /etc` 阶段会清除 `/etc/nixos/.git`，仓库放 `~/` 下可避免被清除
- `hardware-configuration.nix` 由 `nixos-generate-config` 自动生成 — **禁止编辑**
- Home Manager 接管 `~/.bashrc`、`~/.config/fish/`、`~/.config/git/config`、`~/.config/niri/config.kdl`、`~/.config/kitty/kitty.conf`、`~/.Xresources`、`~/.config/mpv/mpv.conf`、`~/.config/mimeapps.list`、`~/.config/user-dirs.dirs` — **手动编辑会被覆盖**
- niri 配置为 KDL 格式，通过 `xdg.configFile` 部署，含 `include "dms/cursor.kdl"`（DMS 自动生成）
- XDG Desktop Portal 使用 GNOME 后端 (xdg-desktop-portal-gnome + gtk 回退)
- Qt 平台主题通过 niri 环境变量 `QT_QPA_PLATFORMTHEME=gtk3` 控制
- 蓝牙在 `bluetooth.nix` 中配置，由 DMS 通过 bluez 直接管理（未安装 blueman）
- fuzzel 同时安装在系统级和用户级 — 有意为之（系统级确保 PATH 可见）
- 当前 overlay: `openldap` 跳过了测试 (`doCheck = false`)，因为 `test017-syncreplication-refresh` 不稳定会导致 lutris 构建失败
- `flake.nix` 的 `specialArgs = { inherit inputs; }` 使 CookNixvim 等 inputs 在所有 NixOS 模块中可用
- Flatpak 有内置 GPG 修复：开机自动下载 Flathub 公钥。如遇"无法从不信任的远程仓库提取"错误，见 README.md 手动修复流程

## Git 仓库

- 实际路径: `/etc/nixos`（git 仓库直接位于此路径）
- 仓库 URL: `https://github.com/HeShian/nixos-config.git`
- 分支: `main`
- `hardware-configuration.nix` 已提交作为参考，但**每台机器需重新生成**：
  `sudo nixos-generate-config --show-hardware-config > hosts/westwood/hardware-configuration.nix`
