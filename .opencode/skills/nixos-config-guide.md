# NixOS 配置规范指南（NixOS Config Guide）

## 概述

本 skill 定义了本项目（Westwood NixOS 配置）的目录结构、中文注释规范和工作流程。
**AI 助手在执行任何与本配置仓库相关的操作前，必须先加载本 skill，并严格遵循其中所有规范。**

## 强制要求

> ⚠️ **每次修改配置前，AI 助手必须：**
> 1. 加载此 skill（`skill(name="nixos-config-guide")`）
> 2. 确认待修改的配置属于正确的目录层级（系统级 vs 用户级）
> 3. 遵循中文注释规范

---

## 项目实际目录结构

本项目是单主机（westwood）、单用户（claudia）的 NixOS 配置仓库，实际目录结构如下：

```
/etc/nixos/
├── flake.nix                          # Flake 入口点
├── flake.lock                         # 依赖锁定文件（自动生成）
├── opencode.jsonc                     # OpenCode AI 配置（含 nixos MCP + skills 注册）
├── AGENTS.md                          # AI 助手行为指南（含快速命令）
├── .opencode/skills/
│   └── nixos-config-guide.md          # 📖 本文件 —— 配置规范（必须加载）
├── hosts/westwood/                    # 🖥️ 主机系统配置
│   ├── configuration.nix              #   系统入口（imports 所有子模块）
│   ├── hardware-configuration.nix     #   [自动生成] 硬件配置（禁止编辑代码）
│   ├── boot.nix                       #   引导：systemd-boot UEFI 引导加载器
│   ├── nvidia.nix                     #   显卡：NVIDIA Optimus PRIME Render Offload
│   ├── bluetooth.nix                  #   蓝牙：bluez 协议栈
│   ├── swap.nix                       #   交换：zram（优先）+ swapfile（后备）
│   ├── networking.nix                 #   网络：主机名、NetworkManager、SSH
│   ├── locale.nix                     #   本地化：时区、Locale、Fcitx5+Rime 输入法
│   ├── desktop.nix                    #   桌面：GDM、niri WM、DMS Shell、Qt、Portal
│   ├── pipewire.nix                   #   音频：PipeWire + WirePlumber 服务
│   ├── thunar.nix                     #   文件：Thunar 文件管理器 + gvfs + dconf
│   ├── fonts.nix                      #   字体：JetBrainsMono + Noto CJK + Emoji + fontconfig
│   ├── packages.nix                   #   软件包：Firefox、Steam、开发工具等
│   ├── services.nix                   #   服务：libvirtd 虚拟化、daed 代理、v2raya
│   └── flatpak.nix                    #   Flatpak + 中科大 USTC 镜像
├── home/claudia/                      # 👤 用户 claudia 配置
│   ├── default.nix                    #   HM 入口（imports + 基本设置）
│   ├── shell.nix                      #   fish + starship + zoxide + kitty
│   ├── ghostty.nix                    #   Ghostty 终端模拟器（GPU 加速，匹配 Kitty 配置）
│   ├── fastfetch.nix                  #   Fastfetch 系统信息显示（Catnap 风格，终端启动自动运行）
│   ├── git.nix                        #   Git 配置（用户信息、别名、忽略规则）
│   ├── nvim.nix                       #   CookNixvim 外部 flake 输入（零污染 Neovim 配置 + 自定义快捷键）
│   ├── niri.nix                       #   niri WM 键绑定 + 窗口规则 + 动画（KDL）
│   ├── xdg.nix                        #   XDG 基础（mimeapps、user-dirs、Xresources）
│   ├── fcitx5.nix                     #   Fcitx5 输入法 + DMS 动态配色同步
│   ├── fuzzel.nix                     #   Fuzzel 启动器 + DMS 配色同步
│   ├── gtk-sync.nix                   #   DMS → GTK 深浅主题同步 + Remmina 包装
│   ├── dms-fix.nix                    #   DMS 启动主题修复（SIGUSR1 触发 QML 重载）
│   ├── packages.nix                   #   用户级软件包
│   ├── mpv.nix                        #   MPV 视频播放器配置（GPU-Next + NVDEC 硬解 + Bilibili 弹幕）
│   └── thunar.nix                     #   Thunar 桌面集成（文件模板、uca.xml、exo-open、xfconf）
├── modules/                           # 📦 可复用模块
│   ├── nixos/                         #   NixOS 系统模块（跨主机复用）
│   │   └── common.nix                 #     通用配置：镜像源、用户、sudo 免密、Nix GC
│   └── home/                          #   Home Manager 模块（跨用户复用）
├── overlays/                          # 🧩 软件包覆盖
│   └── default.nix                    #   openldap 修补 + thunar-archive-plugin xarchiver.tap + 引入自定义包
├── pkgs/                              # 📦 自定义包
│   ├── default.nix                    #   包集合入口（overlay 形式）
│   └── bilibili-tui/
│       └── default.nix                #   B 站 TUI 客户端
├── lib/                               # 🔧 自定义辅助函数库（预留）
│   └── default.nix
├── secrets/                           # 🔒 敏感配置（占位，未来 agenix/sops-nix）
│   └── .gitkeep
└── reference/                         # 参考文件（非 Nix 管理）
    └── dms/
        ├── settings.json
        └── firefox.css
```

### 目录结构原则

1. **职责分离**：每个配置模块只负责一个领域（网络/硬件/桌面/Shell 等）
2. **入口聚合**：`configuration.nix` / `default.nix` 统一 import 子模块
3. **系统 vs 用户分离**：系统级配置在 `hosts/`，用户级在 `home/`
4. **共享 vs 主机专属**：跨主机共享的在 `modules/nixos/`，主机专有的在 `hosts/<hostname>/`
5. **自定义包集中管理**：所有自定义包在 `pkgs/` 中，通过 overlay 注入
6. **不修改自动生成文件**：`hardware-configuration.nix` 保持原样，只可加注释头

### 模块扩展规则

| 操作 | 文件位置 | 说明 |
|------|----------|------|
| 添加系统级包 | `hosts/westwood/packages.nix` → `environment.systemPackages` | 所有用户可用 |
| 添加用户级包 | `home/claudia/packages.nix` → `home.packages` | 无需 sudo |
| 添加自定义包 | `pkgs/<name>/default.nix` → 注册到 `pkgs/default.nix` | 通过 overlay 注入 |
| 添加主机子模块 | `hosts/westwood/<name>.nix` → 在 `configuration.nix` 的 imports 中注册 | |
| 添加共享 NixOS 模块 | `modules/nixos/<name>.nix` → 在 `flake.nix` 的 modules 中添加 | |
| 添加共享 HM 模块 | `modules/home/<name>.nix` → 在 `home/claudia/default.nix` 中 import | |

---

## 中文注释规范

### 通用规则

1. **文件头注释**：每个 `.nix` 文件必须有文件级注释块，说明本文件的职责和内容概要
2. **节注释**：使用 `===` 或 `---` 分隔线标记各配置段落，说明该段的功能
3. **行尾注释**：关键配置项后加 `#` 行尾注释，解释该值的含义或注意事项
4. **注释语言**：注释正文使用中文，术语/命令/文件名/代码片段保留英文
5. **注释风格**：正式且详细，为有 NixOS 基础但需要理解具体配置意图的读者编写

### 注释格式模板

#### 文件头注释模板

```nix
# ==============================================================================
# [模块名称]
#
#   本文件管理 [简要说明本文件的职责范围]，涵盖：
#   - [功能点 1]：[一句话说明]
#   - [功能点 2]：[一句话说明]
#   - [功能点 3]：[一句话说明]
#
#   [补充说明：使用注意事项、关联文件、参考资料等]
# ==============================================================================
```

#### 节注释模板

```nix
  # ============================================================================
  # [节名称]
  #
  #   [详细说明本节的配置目的、设计思路和使用方式]
  #   [可选：特殊说明、依赖关系、注意事项]
  # ============================================================================
```

#### 行尾注释模板

```nix
  配置项 = 值;     # [值的含义，以"——"或"———"分隔，例如：启用某某功能]
```

#### 自动生成文件模板（如 hardware-configuration.nix）

```nix
# ═══════════════════════════════════════════════════════════════════════════════
# [文件名称] —— 自动生成
#
#   ⚠️ 重要：此文件由 [工具名] 自动生成，禁止手动编辑！
#   重新生成命令：[重新生成命令]
#
#   此文件包含：[内容概要]
# ═══════════════════════════════════════════════════════════════════════════════

# [保留原有自动生成警告]
```

### 注释详细程度参考

- **关键配置项**（影响系统行为/安全/性能）：必须有详细中文注释
- **中间配置项**（调整功能细节）：可有简短中文注释
- **自解释配置项**（如 `enable = true`）：可省略注释，或加极简说明
- **值非显而易见**（如特定 UUID、哈希值）：必须注释说明来源和用途
- **限制/约束**（如 `stateVersion` 禁止修改）：必须显式警告

### 禁止行为

- ❌ 注释中使用拼音替代中文
- ❌ 中英文混杂无章（术语和代码片段可保留英文，叙述用中文）
- ❌ 注释与代码功能不符
- ❌ 过度注释（每行都注释 = 没有注释）
- ❌ 在 `hardware-configuration.nix` 中修改代码（只能加注释头）
- ❌ 使用机翻式英文风格中文

## 配置文件命名规范

| 模式 | 示例 | 说明 |
|------|------|------|
| 功能命名 | `networking.nix`, `locale.nix` | 使用完整英文单词 |
| 不使用序号 | ❌ `01-networking.nix` | import 顺序在入口文件控制 |
| 不使用拼音 | ❌ `wangluo.nix` | 使用英文名称 |
| 不使用大写 | ❌ `Networking.nix` | 全部小写+连字符（如需要） |

## 关键项目约束

- **stateVersion**: `25.11` — **禁止修改**
- **单主机**: `westwood` (x86_64-linux), **单用户**: `claudia`
- **频道**: `nixpkgs-unstable`，Home Manager 跟随 nixpkgs
- **硬件配置**: `hosts/westwood/hardware-configuration.nix` 由 `nixos-generate-config` 自动生成，**禁止编辑**
- **硬件**: Intel UHD 610 (iGPU) + NVIDIA GTX 1650 Ti Mobile (dGPU)，PRIME Render Offload
- **交换**: zram (zstd, 50% RAM, priority 100) + 16G swapfile (priority 10)，zswap 已禁用
- **非自由软件**: `allowUnfree = true`（NVIDIA 驱动、Steam 等需要）
- **sudo 免密**: `security.sudo.wheelNeedsPassword = false`

## AI 工作流规范（强制性）

### 配置修改流程

AI 助手在接到与本仓库配置相关的任务时，必须按此流程操作：

1. **加载 skill**：调用 `skill(name="nixos-config-guide")` 加载本规范
2. **定位正确层级**：
   - `hosts/westwood/*.nix` → 系统级配置
   - `home/claudia/*.nix` → 用户级配置
   - `modules/nixos/*.nix` → 可复用 NixOS 模块
   - `modules/home/*.nix` → 可复用 Home Manager 模块
3. **遵循注释规范**：新配置必须添加符合本规范的中文注释
4. **验证**：修改后运行 Nix 语法检查

### 添加配置的决策树

```
需要添加配置？
├── 系统包？ → hosts/westwood/packages.nix → environment.systemPackages
├── 用户包？ → home/claudia/default.nix → home.packages
├── 系统模块（可复用）？ → modules/nixos/<name>.nix
├── 主机专属系统配置？ → hosts/westwood/<name>.nix
├── 用户模块（可复用）？ → modules/home/<name>.nix
├── 自定义包？ → pkgs/<name>/default.nix → pkgs/default.nix 注册
└── 参考文件？ → reference/<category>/
```

---

## 适用项目类型

- 个人/团队的 NixOS 配置仓库
- 使用 Flake 的模块化配置
- 集成 Home Manager 的项目
- 单主机或多主机场景

## 相关参考

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Flake 文档](https://nixos.wiki/wiki/Flakes)
