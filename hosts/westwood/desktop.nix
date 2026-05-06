{ config, lib, pkgs, ... }:

# ==============================================================================
# 桌面环境配置
#   niri（默认会话，Scrollable-tiling Wayland 合成器）
#   greetd + tuigreet（登录管理器，替代 GDM）
#   门户后端：xdg-desktop-portal-gnome
#   文件管理器：Thunar
#   录屏：kooha（基于 xdg-desktop-portal）
#   字体：JetBrains Mono Nerd Font + Noto Sans CJK SC
# ==============================================================================

{
  # ============================================================================
  # greetd + tuigreet —— 登录管理器（替代 GDM）
  #   tuigreet 提供 TUI 登录界面，输入密码后启动 niri 会话
  # ============================================================================
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --asterisks --remember --time --cmd ${pkgs.niri}/bin/niri-session";
        user = "greeter";
      };
    };
  };

  # ============================================================================
  # niri —— Scrollable-tiling Wayland 合成器
  # ============================================================================
  programs.niri.enable = true;
  programs.xwayland.enable = true;         # XWayland —— X11 应用兼容层

  # ============================================================================
  # dms（DankMaterialShell）—— 运行在 niri 之上的桌面 Shell
  #   systemd.target = "niri.service" → 仅随 niri 启动
  #   enableDynamicTheming → 安装 matugen，用于配色生成（Qt 配色需要）
  # ============================================================================
  programs.dms-shell = {
    enable = true;
    enableDynamicTheming = true;
    systemd = {
      enable = true;
      target = "niri.service";
    };
  };

  # ============================================================================
  # Qt 配置 —— 为 DMS 应用 Qt 配色提供 qt5ct/qt6ct 支持
  #   平台主题由 niri 环境变量 QT_QPA_PLATFORMTHEME=gtk3 控制（保留）
  # ============================================================================
  qt = {
    enable = true;
    style = "adwaita";
  };

  # ============================================================================
  # XDG 桌面门户 —— 使用 GNOME 后端
  #   niri 需要 portal 实现文件选择、截屏等跨桌面功能
  # ============================================================================
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome   # niri 推荐的门户后端
      xdg-desktop-portal-gtk     # GTK 应用回退
    ];
    config = {
      common.default = [ "gnome" "gtk" ];
    };
  };

  # ============================================================================
  # 蓝牙管理 —— 由 dms 通过 bluez 协议栈直接管理
  #   hardware.bluetooth 已在 hardware.nix 中启用（bluez + bluetoothd）
  #   不再安装 blueman，fuzzel 中不会出现"蓝牙管理器"条目
  # ============================================================================

  # ============================================================================
  # PipeWire —— 音频服务
  #   供 kooha 录屏音频采集、蓝牙音频、一般音频输出
  # ============================================================================
  services.pipewire = {
    enable = true;
    alsa.enable = true;                        # ALSA 兼容
    pulse.enable = true;                       # PulseAudio 兼容
    wireplumber.enable = true;                 # 会话管理
  };

  # ============================================================================
  # Thunar —— 轻量文件管理器（Xfce）
  # ============================================================================
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-volman              # 可移动设备管理
      thunar-archive-plugin      # 压缩文件集成
    ];
  };

  programs.xfconf.enable = true;               # Thunar 设置存储后端
  services.gvfs.enable = true;                 # 挂载、trash、网络文件系统

  # GTK 应用设置存储（dconf）
  programs.dconf.enable = true;

  # ============================================================================
  # 字体 —— shorin 风格配置
  #   参考：https://github.com/SHORiN-KiWATA/shorin-dms-niri
  #   JetBrains Mono Nerd Font → 等宽 + 图标
  #   Noto Sans CJK SC → 中文界面
  #   fontconfig 渲染优化：抗锯齿、slight hinting、LCD 过滤
  # ============================================================================
  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono                # JetBrains Mono + 完整 Nerd Font 图标
      nerd-fonts.symbols-only                  # Nerd Font 图标单独包
      noto-fonts-cjk-sans                      # 中文界面字体（Noto Sans CJK SC）
      noto-fonts-color-emoji                   # Emoji 字体
    ];

    fontconfig = {
      antialias = true;                        # 抗锯齿
      hinting = {
        enable = true;
        style = "slight";                     # slight hinting，保留字形形状
      };
      subpixel = {
        rgba = "rgb";                         # 标准 RGB 子像素排列
        lcdfilter = "default";                # LCD 过滤
      };
      defaultFonts = {
        monospace = ["JetBrainsMono Nerd Font" "Noto Sans CJK SC"];
        sansSerif = ["Noto Sans CJK SC" "Noto Sans"];
        serif = ["Noto Sans CJK SC" "Noto Sans"];
        emoji = ["Noto Color Emoji"];
      };
    };
  };
}
