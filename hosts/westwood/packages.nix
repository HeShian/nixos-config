{ config, lib, pkgs, ... }:

# ==============================================================================
# 系统软件包
#   全局安装的软件，所有用户可用。
#   用户级软件包请见 home/claudia/default.nix（home.packages）。
# ==============================================================================

{
  # ============================================================================
  # 程序与服务
  # ============================================================================
  programs.firefox.enable = true;              # Firefox 浏览器
  programs.fish.enable = true;                 # fish 默认 Shell（系统级 PATH 配置）
  services.v2raya.enable = true;               # V2RayA —— 代理客户端

  # ============================================================================
  # 游戏
  # ============================================================================
  programs.steam = {
    enable = true;
    extest.enable = true;                 # Wayland 下 Steam Input 支持
    remotePlay.openFirewall = true;       # Steam 远程同乐
    dedicatedServer.openFirewall = true;  # 独立服务器
  };

  # ============================================================================
  # 虚拟化
  # ============================================================================
  virtualisation.libvirtd.enable = true;  # KVM —— 虚拟机（替代 VMware）

  # ============================================================================
  # Daed —— 基于 eBPF 的代理（Web 管理面板，端口 2023）
  #   与 v2raya 共存，两者互不干扰
  # ============================================================================
  systemd.packages = with pkgs; [ daed ];
  systemd.services.daed.wantedBy = [ "multi-user.target" ];
  systemd.services.daed.environment.DAE_LOCATION_ASSET = "${pkgs.symlinkJoin { name = "dae-assets"; paths = with pkgs; [ v2ray-geoip v2ray-domain-list-community ]; } }/share/v2ray";
  networking.firewall.allowedTCPPorts = [ 2023 ];

  # ============================================================================
  # 系统级软件包（所有用户可用）
  # ============================================================================
  environment.systemPackages = with pkgs; [
    neovim                                     # 主力编辑器
    git                                        # 版本控制
    wget                                       # 文件下载
    curl                                       # HTTP 工具
    opencode                                   # AI 编码代理（终端版）
    nodejs                                     # JavaScript 运行时
    bun                                        # 快速 JavaScript 工具链
    uv                                         # Python 包管理器（astral.sh）
    python3                                    # Python 解释器
    fuzzel                                     # 应用启动器（Mod+Z，系统级确保 PATH 可见）
    libsForQt5.qt5ct                           # Qt5 配置工具（DMS 应用 Qt 配色需要）
    kdePackages.qt6ct                          # Qt6 配置工具（DMS 应用 Qt 配色需要）
    adwaita-icon-theme                        # Adwaita 图标+光标主题（DMS 光标配置需要）
    gst_all_1.gstreamer                   # GStreamer 工具（gst-inspect, gst-launch）
    obs-studio                              # OBS Studio（录屏/推流，兼容 niri DMA-BUF）
    daed                                      # dae 代理 + Web 管理面板
  ];
}
