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
| `hosts/westwood/networking.nix` | 主机名、NetworkManager、SSH | |
| `hosts/westwood/locale.nix` | 时区、locale、Fcitx5+Rime 输入法 | GTK/Qt 输入法环境变量在此 |
| `hosts/westwood/hardware.nix` | systemd-boot、NVIDIA Optimus、蓝牙、zram+swapfile | zswap 已禁用(与 zram 冲突) |
| `hosts/westwood/desktop.nix` | GDM、niri WM、DMS Shell、PipeWire、Thunar、字体 | **图形登录（GDM）** |
| `hosts/westwood/packages.nix` | 系统级软件包 + 服务 | Firefox、Steam、libvirtd、v2raya、daed 等 |
| `hosts/westwood/flatpak.nix` | Flatpak + USTC 镜像 | systemd oneshot 自动修复 Flathub GPG |
| `modules/common.nix` | 共享模块：镜像源、用户 claudia、sudo 免密、Nix GC | 所有主机通用 |
| `home/claudia/default.nix` | 用户配置入口，imports shell/git/nvim/niri/xdg | 用户级软件包 + MPV 配置在此 |
| `home/claudia/nvim.nix` | CookNixvim 外部 flake 输入 | 零污染 Neovim 配置 |
| `home/claudia/niri.nix` | niri WM 配置 (KDL 格式, xdg.configFile 部署) | 键绑定、窗口规则、动画、环境变量 |
| `overlays/default.nix` | 包覆盖 — openldap 跳过测试 + 引入 pkgs/ | |
| `pkgs/default.nix` | 自定义包集合 | 当前: bilibili-tui |
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
- **用户级**: `home.packages` → `home/claudia/default.nix` (无需 sudo)
- **Flatpak 应用**: 手动 `flatpak install flathub <app-id>` (系统级已配好源)
- **自定义包**: 在 `pkgs/<name>/` 创建 `default.nix` → 在 `pkgs/default.nix` 注册 → `overlays/default.nix` 自动引入

## 约束与注意事项

- `/etc/nixos` 是指向 `/home/claudia/nixos-config/` 的符号链接。`nixos-rebuild switch` 在 `setting up /etc` 阶段会清除 `/etc/nixos/.git`，仓库放 `~/` 下可避免被清除
- `hardware-configuration.nix` 由 `nixos-generate-config` 自动生成 — **禁止编辑**
- Home Manager 接管 `~/.bashrc`、`~/.config/fish/`、`~/.config/git/config`、`~/.config/niri/config.kdl`、`~/.config/kitty/kitty.conf`、`~/.Xresources`、`~/.config/mpv/mpv.conf`、`~/.config/mimeapps.list`、`~/.config/user-dirs.dirs` — **手动编辑会被覆盖**
- niri 配置为 KDL 格式，通过 `xdg.configFile` 部署，含 `include "dms/cursor.kdl"`（DMS 自动生成）
- XDG Desktop Portal 使用 GNOME 后端 (xdg-desktop-portal-gnome + gtk 回退)
- Qt 平台主题通过 niri 环境变量 `QT_QPA_PLATFORMTHEME=gtk3` 控制
- 蓝牙在 `hardware.nix` 中配置，由 DMS 通过 bluez 直接管理（未安装 blueman）
- fuzzel 同时安装在系统级和用户级 — 有意为之（系统级确保 PATH 可见）
- 当前 overlay: `openldap` 跳过了测试 (`doCheck = false`)，因为 `test017-syncreplication-refresh` 不稳定会导致 lutris 构建失败
- `flake.nix` 的 `specialArgs = { inherit inputs; }` 使 CookNixvim 等 inputs 在所有 NixOS 模块中可用
- Flatpak 有内置 GPG 修复：开机自动下载 Flathub 公钥。如遇"无法从不信任的远程仓库提取"错误，见 README.md 手动修复流程

## Git 仓库

- 实际路径: `/home/claudia/nixos-config/`
- 仓库 URL: `https://github.com/HeShian/nixos-config.git`
- 分支: `main`
- `hardware-configuration.nix` 已提交作为参考，但**每台机器需重新生成**：
  `sudo nixos-generate-config --show-hardware-config > hosts/westwood/hardware-configuration.nix`
