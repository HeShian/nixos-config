{ ... }:

# ==============================================================================
# 主机：westwood —— 系统配置总入口
#
#   本文件是 westwood 主机的 NixOS 配置入口点，通过 imports 引入所有子模块。
#   每个子模块负责一个独立的配置领域，按职责拆分如下：
#
#   子模块清单（按引用顺序）：
#     硬件层：
#       hardware-configuration.nix  → 硬件检测结果（自动生成，禁止编辑）
#       boot.nix                    → systemd-boot 引导加载器
#       nvidia.nix                  → NVIDIA Optimus 混合显卡
#       bluetooth.nix               → bluez 蓝牙协议栈
#       swap.nix                    → zram + swapfile 交换空间
#     系统层：
#       networking.nix              → 主机名、NetworkManager、SSH
#       locale.nix                  → 时区、语言、中文输入法
#       desktop.nix                 → GDM 登录、niri WM、DMS Shell
#       pipewire.nix                → PipeWire 音频服务
#       thunar.nix                  → Thunar 文件管理器 & 桌面基础服务
#       fonts.nix                   → 字体包 & fontconfig 渲染
#       packages.nix                → 系统级软件包
#       services.nix                → 系统服务（libvirtd / daed / v2raya）
#       flatpak.nix                 → Flatpak 容器化应用 + USTC 镜像源
#
#   共享配置（多主机通用，如镜像源、用户定义、Nix GC）见
#   /etc/nixos/modules/nixos/common.nix，在 flake.nix 中统一引入。
#
#   ⚠️ 添加新的子模块时，请在本文件的 imports 列表中注册。
# ==============================================================================

{
  imports = [
    # ---- 硬件层 ----
    ./hardware-configuration.nix   # [自动生成] 硬件检测（磁盘 UUID、initrd 模块、文件系统）
    ./boot.nix                     # 引导：systemd-boot UEFI 引导加载器
    ./nvidia.nix                   # 显卡：NVIDIA Optimus PRIME Render Offload
    ./bluetooth.nix                # 蓝牙：bluez 协议栈
    ./swap.nix                     # 交换：zram（优先）+ swapfile（后备）

    # ---- 系统层 ----
    ./networking.nix               # 网络：主机名、NetworkManager、SSH 服务
    ./locale.nix                   # 本地化：时区、Locale 编码、Fcitx5+Rime 输入法
    ./desktop.nix                  # 桌面：GDM 登录、niri WM、DMS Shell、Qt、Portal
    ./pipewire.nix                 # 音频：PipeWire + WirePlumber 服务
    ./thunar.nix                   # 文件：Thunar 文件管理器 + gvfs + dconf
    ./fonts.nix                    # 字体：JetBrainsMono + Noto CJK + Emoji + fontconfig
    ./packages.nix                 # 软件包：Firefox、Steam、开发工具等
    ./services.nix                 # 服务：libvirtd 虚拟化、daed 代理、v2raya
    ./flatpak.nix                  # Flatpak 容器化应用 + 中科大 USTC 镜像
  ];

  # ============================================================================
  # 系统状态版本 —— stateVersion
  #
  #   此值用于 NixOS 的向后兼容机制，决定某些选项的默认行为。
  #   ⚠️ 请勿随意修改！每次 NixOS 大版本升级会引入新的默认值，
  #   随意修改可能导致 systemd 服务、网络配置等行为意外变更。
  #
  #   正确的升级流程：
  #     1. 更新 flake.lock 中的 nixpkgs 输入
  #     2. sudo nixos-rebuild switch （测试新版本兼容性）
  #     3. 确认所有功能正常后更新此值
  # ============================================================================
  system.stateVersion = "25.11";
}
