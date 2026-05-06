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

# 查询 NixOS 包/选项
# 使用 opencode.jsonc 中配置的 nixos MCP (mcp-nixos)
```

## 目录结构

| 路径 | 用途 | 备注 |
|---|---|---|
| `flake.nix` | 入口点 — nixosConfigurations + homeConfigurations | |
| `hosts/westwood/configuration.nix` | **系统配置入口**，imports 所有子模块 | 添加新模块时在此注册 |
| `hosts/westwood/hardware-configuration.nix` | **自动生成** — 勿编辑 | `nixos-generate-config` 生成 |
| `hosts/westwood/networking.nix` | 主机名、NetworkManager、SSH | |
| `hosts/westwood/locale.nix` | 时区、locale、Fcitx5+Rime 输入法 | GTK/Qt 输入法环境变量在此 |
| `hosts/westwood/hardware.nix` | systemd-boot、NVIDIA Optimus、蓝牙、zram+swapfile | zswap 已禁用(与 zram 冲突) |
| `hosts/westwood/desktop.nix` | greetd+tuigreet 登录、niri WM、DMS Shell、PipeWire、Thunar、字体 | **无 GDM/GNOME** |
| `hosts/westwood/packages.nix` | 系统级软件包 | Firefox、Steam、libvirtd、v2raya、daed 等 |
| `hosts/westwood/flatpak.nix` | Flatpak + USTC 镜像 | systemd oneshot 配置 flathub 远程 |
| `modules/common.nix` | 共享模块：镜像源、用户 claudia、sudo 免密、Nix GC | 所有主机通用 |
| `home/claudia/default.nix` | 用户配置入口，imports shell/git/nvim/niri/xdg | 用户级软件包在此 |
| `home/claudia/xdg.nix` | XDG 基础配置：mimeapps.list、user-dirs.dirs、Xresources | 从 ~/ 迁移至此 |
| `home/claudia/shell.nix` | Fish + starship(Catppuccin Powerline) + zoxide + kitty | bash 已禁用 |
| `home/claudia/git.nix` | Git config (main 分支, pull rebase) | |
| `home/claudia/nvim.nix` | CookNixvim 外部 flake 输入 | 零污染 Neovim 配置 |
| `home/claudia/niri.nix` | niri WM 配置 (KDL 格式, xdg.configFile 部署) | 键绑定、窗口规则、动画 |
| `overlays/default.nix` | 包覆盖 — openldap 跳过测试 | 引出 pkgs/default.nix |
| `pkgs/default.nix` | 自定义包集合 | 当前: bilibili-tui |
| `pkgs/bilibili-tui/default.nix` | 自定义 Rust 包 (GitHub MareDevi/bilibili-tui) | `doCheck = false` |
| `lib/default.nix` | 自定义辅助函数 | 当前为空 |

## 关键事实

- **单主机**: `westwood` (x86_64-linux), **单用户**: `claudia`
- **频道**: `nixpkgs-unstable`. Home Manager 跟随 nixpkgs (`follows = "nixpkgs"`)
- **stateVersion**: `25.11` — **禁止修改**
- **登录管理器**: greetd + tuigreet (TUI 登录，密码认证)，**不是 GDM**
- **桌面会话**: niri (Scrollable-tiling Wayland 合成器) + DMS Shell (DankMaterialShell)，含动态主题
- **Shell**: fish (bash 已禁用). 提示符: starship (Catppuccin Mocha, Powerline 风格)
- **GPU**: Intel UHD 610 (iGPU) + NVIDIA GTX 1650 Ti Mobile (dGPU). PRIME Render Offload — `nvidia-offload` 命令可用. Bus IDs: `PCI:0:2:0` / `PCI:1:0:0`. Nouveau 已黑名单
- **交换空间**: zram (zstd, 50% RAM, priority 100) + 16G swapfile (priority 10). `zswap.enabled=0` 内核参数 (与 zram 冲突)
- **输入法**: Fcitx5 + Rime + rime-ice (直接使用 rime-ice 包). 环境变量: `GTK_IM_MODULE=fcitx`、`QT_IM_MODULE=fcitx`、`XMODIFIERS=@im=fcitx`
- **镜像源**: USTC 主用 → Tsinghua 备用 → cache.nixos.org 回退. Flatpak 也使用 USTC 镜像
- **代理**: v2raya + daed (eBPF 代理, Web 管理面板端口 2023) 共存
- **Neovim**: CookNixvim 外部 flake 输入 (github:Youthdreamer/CookNixvim). 提供 `nvim` 二进制, 设置 `EDITOR`/`VISUAL`
- **允许非自由软件**: `true` (NVIDIA 驱动、Steam、opencode 等)

## 添加软件包

- **系统级**: `environment.systemPackages` → `hosts/westwood/packages.nix`
- **用户级**: `home.packages` → `home/claudia/default.nix` (无需 sudo)
- **Flatpak 应用**: 手动 `flatpak install flathub <app-id>` (系统级已配好源)

## 约束与注意事项

- `hardware-configuration.nix` 由 `nixos-generate-config` 自动生成 — **禁止编辑**
- `stateVersion` `25.11` — **禁止修改**
- Home Manager 接管 `~/.bashrc`、`~/.config/fish/`、`~/.config/git/config`、`~/.config/niri/config.kdl` — 手动编辑会被覆盖
- `configuration.nix` 新增了 `./flatpak.nix` 模块，添加新子模块时记得在此注册
- 自定义包放在 `pkgs/` 目录，在 `pkgs/default.nix` 中注册，由 `overlays/default.nix` 引出
- 当前 overlay: `openldap` 跳过了测试 (`doCheck = false`)，因为 `test017-syncreplication-refresh` 不稳定会导致 lutris 构建失败
- fuzzel 同时安装在系统级和用户级 — 这是有意为之（系统级确保 PATH 可见）
- niri 配置为 KDL 格式，通过 `xdg.configFile` 部署，含 `include "dms/cursor.kdl"`（DMS 自动生成）
- XDG Desktop Portal 使用 GNOME 后端 (xdg-desktop-portal-gnome + gtk 回退)
- Qt 平台主题通过 niri 环境变量 `QT_QPA_PLATFORMTHEME=gtk3` 控制
- 蓝牙在 `hardware.nix` 中配置，由 DMS 通过 bluez 直接管理（未安装 blueman）
