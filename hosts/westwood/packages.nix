{ config, lib, pkgs, ... }:

# ==============================================================================
# 系统软件包与服务配置
#
#   本文件管理 westwood 主机的系统级软件包（对所有用户可用）和系统服务。
#   用户级软件包（仅 claudia 可用，不需要 root 权限）请见：
#     /etc/nixos/home/claudia/default.nix → home.packages
#
#   配置分类：
#   - 系统级程序（programs.*）：Firefox、Fish、Steam、v2raya
#   - 虚拟化：libvirtd（KVM/QEMU）
#   - 代理服务：daed（eBPF 内核态代理）
#   - 系统级软件包（environment.systemPackages）：一般工具和开发环境
# ==============================================================================

{
  # ============================================================================
  # 系统级程序（programs.*）
  #   NixOS 模块级程序配置，比直接在 systemPackages 中添加更完整
  #   （自动处理配置文件、D-Bus 激活、systemd 单元等）
  # ============================================================================
  programs.firefox.enable = true;                  # Firefox 浏览器（带 NixOS 集成）
  programs.fish.enable = true;                     # Fish Shell（系统级启用，确保 /etc/shells 注册）
  services.v2raya.enable = true;                   # V2RayA —— 用户态代理客户端（Web 面板管理）

  # ============================================================================
  # Steam 游戏平台
  #   extest.enable：Wayland 下 Steam Input 手柄支持
  #   remotePlay：Steam 远程同乐/串流防火墙放行
  #   dedicatedServer：Steam 独立服务器防火墙放行
  # ============================================================================
  programs.steam = {
    enable = true;
    extest.enable = true;                          # Wayland 下 Steam Input 手柄支持
    remotePlay.openFirewall = true;                # Steam 远程同乐
    dedicatedServer.openFirewall = true;           # Steam 独立服务器
  };

  # ============================================================================
  # 虚拟化 —— libvirtd（KVM/QEMU）
  #   完整的虚拟化解决方案，支持：
  #   - KVM 硬件加速（需要 CPU 支持 VT-x/AMD-V）
  #   - QEMU 全虚拟化
  #   - virt-manager 图形管理（用户级包，见 home/claudia/default.nix）
  #   用户 virt-manager 非 root 管理需要用户加入 libvirtd 组（已在 modules/nixos/common.nix 中配置）
  # ============================================================================
  virtualisation.libvirtd.enable = true;

  # ============================================================================
  # Daed —— 基于 eBPF 的内核态代理
  #
  #   daed 是 dae 的升级版，在 Linux 内核 eBPF 层面进行流量代理，
  #   CPU/内存开销远低于用户态代理。Web 管理面板端口：2023
  #
  #   v2raya（用户态，用户级）和 daed（内核态，系统级）可以共存，
  #   两者使用不同的端口和路由规则，互不干扰。
  # ============================================================================
  systemd.packages = with pkgs; [ daed ];
  systemd.services.daed.wantedBy = [ "multi-user.target" ];
  systemd.services.daed.environment.DAE_LOCATION_ASSET =
    "${pkgs.symlinkJoin {
      name = "dae-assets";
      paths = with pkgs; [ v2ray-geoip v2ray-domain-list-community ];
    } }/share/v2ray";
  networking.firewall.allowedTCPPorts = [ 2023 ]; # daed Web 管理面板端口

  # ============================================================================
  # 系统级软件包（environment.systemPackages）
  #
  #   以下包对所有系统用户可用（包括 root 和未来新增的用户）。
  #   如果某个包仅当前用户需要，请放入 home.packages（home/claudia/default.nix）。
  #
  #   包分组说明：
  #   - 基础工具：neovim / git / wget / curl / opencode
  #   - 开发运行时：nodejs / bun / uv / python3
  #   - 桌面集成：fuzzel（启动器）/ qt5ct/qt6ct / adwaita-icon-theme
  #   - 多媒体：gstreamer / obs-studio
  #   - 代理：daed
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # ---- 基础工具 ----
    neovim                                       # 终端编辑器（主力）
    git                                          # 版本控制系统
    wget                                         # HTTP/FTP 文件下载
    curl                                         # HTTP 命令行工具
    opencode                                     # AI 编码代理（终端版）

    # ---- 开发运行时 ----
    nodejs                                       # JavaScript/TypeScript 运行时
    bun                                          # 快速 JS/TS 工具链（兼容 Node.js API）
    uv                                           # Python 包管理器（astral.sh 出品，替代 pip/poetry）
    python3                                      # Python 3 解释器

    # ---- 桌面集成 ----
    fuzzel                                        # 应用启动器（Mod+Z 快捷键，系统级确保 PATH 可见）
    libsForQt5.qt5ct                             # Qt5 配置工具（DMS 应用 Qt 配色用）
    kdePackages.qt6ct                            # Qt6 配置工具
    adwaita-icon-theme                           # Adwaita 图标 & 光标主题（DMS 依赖）

    # ---- 多媒体 ----
    gst_all_1.gstreamer                          # GStreamer 多媒体框架工具（gst-inspect / gst-launch）
    obs-studio                                   # OBS Studio 录屏/推流（niri DMA-BUF 兼容）

    # ---- 代理 ----
    daed                                         # eBPF 内核态代理 + Web 管理面板
  ];
}
