{ config, lib, pkgs, ... }:

# ==============================================================================
# 桌面环境配置
#
#   本文件管理 westwood 主机的桌面体验：
#
#   1. 登录管理器：GDM（GNOME Display Manager，图形登录界面）
#   2. 窗口合成器：niri（Scrollable-tiling Wayland 合成器，Vim 风格快捷键）
#   3. 桌面 Shell：DMS（DankMaterialShell，运行在 niri 之上，提供动态主题）
#   4. 音频服务：PipeWire + WirePlumber（兼容 ALSA/PulseAudio）
#   5. 文件管理：Thunar（轻量 Xfce 文件管理器）
#   6. 门户后端：xdg-desktop-portal-gnome（截图/文件选择等跨桌面功能）
#   7. 字体：JetBrains Mono Nerd Font（等宽+图标） + Noto Sans CJK SC（中文）
# ==============================================================================

{
  # ============================================================================
  # GDM —— GNOME Display Manager（图形登录界面）
  #
  #   取代 greetd+tuigreet（TUI 文本登录），提供图形化的登录界面。
  #   用户可以从登录界面选择 niri 会话进入窗口管理器。
  #   GDM 会自动管理用户会话的环境变量（包括 GTK_IM_MODULE 等），
  #   避免此前 greetd 下环境变量传播不可靠的问题。
  # ============================================================================
  services.displayManager.gdm = {
    enable = true;
  };

  # ============================================================================
  # GSettings 架构路径
  #
  #   NixOS 将 gsettings-desktop-schemas 的 schema 文件安装在非标准路径
  #   share/gsettings-schemas/... 下。如果不设置 GSETTINGS_SCHEMA_DIR，
  #   gsettings 找不到 org.gnome.desktop.interface 等核心 schema，
  #   导致 GTK4/libadwaita 应用的 color-scheme（深浅主题）失效。
  #
  #   此变量通过 PAM 环境传递给 GDM 登录会话，确保从 niri 启动的所有
  #   GUI 应用都能通过 gsettings 读取 dconf 中的 color-scheme 值。
  # ============================================================================
  environment.sessionVariables = {
    GSETTINGS_SCHEMA_DIR =
      "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
  };

  # ============================================================================
  # niri —— Scrollable-tiling Wayland 合成器
  #
  #   特性：平铺窗口可以水平滚动（scrollable-tiling），
  #   不同于传统的 i3/hyprland 固定工作区方案。
  #   niri 自身不管理状态栏/启动器，由 DMS 补充。
  # ============================================================================
  programs.niri.enable = true;
  programs.xwayland.enable = true;              # XWayland —— 运行 X11 应用的兼容层

  # ============================================================================
  # DMS（DankMaterialShell）—— 动态主题桌面 Shell
  #
  #   运行在 niri 之上的现代化桌面 Shell，提供：
  #   - Material Design 风格的状态栏和控件
  #   - 动态配色（根据壁纸自动生成主题色）
  #   - 蓝牙/音量/网络等系统托盘的统一管理
  #
  #   systemd.target = "niri.service" → DMS 仅随 niri 一起启动
  #   enableDynamicTheming → 安装 matugen（Material Color Utilities 配色生成）
  # ============================================================================
  programs.dms-shell = {
    enable = true;
    enableDynamicTheming = true;                 # 动态主题（根据壁纸生成配色）
    systemd = {
      enable = true;
      target = "niri.service";                  # 绑定到 niri 生命周期
    };
  };

  # ============================================================================
  # Qt 配置
  #   Qt 原生样式设为 Adwaita，与 GNOME 生态视觉一致
  #   Qt 平台主题由 niri 环境变量 QT_QPA_PLATFORMTHEME=gtk3 控制（在 niri.nix 中设置）
  #   qt5ct/qt6ct 工具包已在 packages.nix 中安装，用于微调 Qt 应用外观
  # ============================================================================
  qt = {
    enable = true;
    style = "adwaita";
  };

  # ============================================================================
  # XDG Desktop Portal —— 跨桌面环境的功能接口
  #
  #   Portal 是 Flatpak 应用和 Wayland 合成器之间的桥梁，提供：
  #   - 文件选择对话框（File Chooser）
  #   - 屏幕截图/录屏（Screen Capture）
  #   - 壁纸设置（Wallpaper）
  #   - 远程桌面（Remote Desktop）
  #
  #   后端：xdg-desktop-portal-gnome（主力）+ xdg-desktop-portal-gtk（回退）
  # ============================================================================
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome                   # niri 推荐的门户后端
      xdg-desktop-portal-gtk                     # GTK 应用回退后端
    ];
    config = {
      common.default = [ "gnome" "gtk" ];
    };
  };

  }
