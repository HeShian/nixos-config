{ ... }:

# ==============================================================================
# 主机：westwood —— 系统配置总入口
#
#   本文件是 westwood 主机的 NixOS 配置入口点，通过 imports 引入所有子模块。
#   每个子模块负责一个独立的配置领域，按职责拆分如下：
#
#   子模块清单（按引用顺序）：
#     hardware-configuration.nix  → 硬件检测结果（自动生成，禁止编辑）
#     networking.nix              → 主机名、NetworkManager、SSH
#     locale.nix                  → 时区、语言、中文输入法
#     hardware.nix                → 引导加载器、NVIDIA 显卡、蓝牙、交换空间
#     desktop.nix                 → 显示管理器、窗口合成器、音频、字体
#     packages.nix                → 系统级软件包与服务
#     flatpak.nix                 → Flatpak 容器化应用框架 + USTC 镜像源
#
#   共享配置（多主机通用，如镜像源、用户定义、Nix GC）见
#   /etc/nixos/modules/common.nix，在 flake.nix 中统一引入。
#
#   ⚠️ 添加新的子模块时，请在本文件的 imports 列表中注册。
# ==============================================================================

{
  imports = [
    ./hardware-configuration.nix   # [自动生成] 硬件检测（磁盘 UUID、initrd 模块、文件系统）
    ./networking.nix               # 网络：主机名、NetworkManager、SSH 服务
    ./locale.nix                   # 本地化：时区、Locale 编码、Fcitx5+Rime 输入法
    ./hardware.nix                 # 硬件：systemd-boot 引导、NVIDIA Optimus、zram+swap
    ./desktop.nix                  # 桌面：GDM 登录、niri WM、PipeWire 音频
    ./packages.nix                 # 系统软件包：Firefox、Steam、libvirtd 虚拟化、daed 代理
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
